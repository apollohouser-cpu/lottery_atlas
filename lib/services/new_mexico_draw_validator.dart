import 'dart:convert';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Completed result identities and source-local query windows, independent of reports.
class NewMexicoDrawValidator {
  static bool _ready = false;
  static const ranges = {
    'powerball': [5, 69, 26],
    'megamillions': [5, 70, 24],
    'lottoamerica': [5, 52, 10],
    'roadrunnercash': [5, 37, 0],
    'pick3plus': [3, 9, 0],
    'pick4plus': [4, 9, 0],
  };
  static const groups = {
    'powerball/base/null',
    'powerball/double_play/null',
    'megamillions/base/null',
    'lottoamerica/base/null',
    'roadrunnercash/base/null',
    'pick3plus/base/DAY',
    'pick3plus/base/EVE',
    'pick4plus/base/DAY',
    'pick4plus/base/EVE',
  };
  static String group(Map r) => '${r['game']}/${r['variant']}/${r['session']}';
  static DateTime day(dynamic value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      throw const FormatException('Invalid result date');
    }
    final d = DateTime.parse(value);
    if (d.toIso8601String().substring(0, 10) != value) {
      throw const FormatException('Invalid calendar date');
    }
    return d;
  }

  static String queryUrl(String game, Map window) {
    String us(String v) =>
        '${v.substring(5, 7)}/${v.substring(8, 10)}/${v.substring(0, 4)}';
    return Uri.https(
      'nmlotterydynamic.sks.com',
      '/rts/games/pastdrawings/search/',
      {
        'game': game,
        'start': us(window['start']),
        'end': us(window['end']),
        'sort': 'drawn',
        'appmode': 'true',
        'seamless-embed': 'true',
      },
    ).toString();
  }

  static Map<String, List<Map>> validate(
    List rows,
    Map window,
    DateTime retrieved,
  ) {
    if (!_ready) {
      tzdata.initializeTimeZones();
      _ready = true;
    }
    if (window.length != 3 || window['timezone'] != 'America/Denver') {
      throw const FormatException('Unreviewed query timezone');
    }
    final start = day(window['start']), end = day(window['end']);
    final local = tz.TZDateTime.from(
      retrieved,
      tz.getLocation('America/Denver'),
    );
    final today = DateTime(local.year, local.month, local.day);
    if (start.isBefore(DateTime(2025, 4, 8)) ||
        end.difference(start).inDays != 14 ||
        end.isAfter(today)) {
      throw const FormatException('Invalid current-format query window');
    }
    final out = <String, List<Map>>{};
    for (final item in rows) {
      final r = item as Map;
      final g = group(r);
      final spec = ranges[r['game']];
      const keys = {
        'game',
        'variant',
        'date',
        'session',
        'numbers',
        'specialBall',
        'multiplier',
        'reportStatus',
        'sourceUrl',
        'retrievedAt',
        'report',
      };
      if (r.length != keys.length ||
          !r.keys.every(keys.contains) ||
          !groups.contains(g) ||
          spec == null) {
        throw const FormatException('Unreviewed result identity');
      }
      final date = day(r['date']);
      if (date.isBefore(start) || date.isAfter(end)) {
        throw const FormatException('Out-of-window result');
      }
      if (r['sourceUrl'] != queryUrl(r['game'], window)) {
        throw const FormatException('Result query source mismatch');
      }
      final pick = (r['game'] as String).startsWith('pick');
      final nums = r['numbers'];
      if (nums is! List || nums.length != spec[0]) {
        throw const FormatException('Wrong main-ball count');
      }
      final values = <int>[];
      for (final n in nums) {
        if (n is! String ||
            !RegExp(pick ? r'^\d$' : r'^\d{1,2}$').hasMatch(n)) {
          throw const FormatException('Invalid ball text');
        }
        final v = int.parse(n);
        if (v < (pick ? 0 : 1) || v > spec[1]) {
          throw const FormatException('Ball out of range');
        }
        values.add(v);
      }
      if (!pick && values.toSet().length != values.length) {
        throw const FormatException('Duplicate main balls');
      }
      final special = r['specialBall'];
      if (spec[2] == 0
          ? special != null
          : special is! int || special < 1 || special > spec[2]) {
        throw const FormatException('Invalid special ball');
      }
      final multiplier = r['multiplier'];
      final allowed = r['variant'] == 'double_play'
          ? <int>[]
          : r['game'] == 'powerball'
          ? [2, 3, 4, 5, 10]
          : r['game'] == 'lottoamerica'
          ? [2, 3, 4, 5]
          : <int>[];
      if (allowed.isEmpty
          ? multiplier != null
          : multiplier is! int || !allowed.contains(multiplier)) {
        throw const FormatException('Invalid multiplier');
      }
      if (r['report'] == null
          ? r['reportStatus'] != 'unavailable'
          : r['reportStatus'] != 'available') {
        throw const FormatException('Report availability mismatch');
      }
      final list = out.putIfAbsent(g, () => []);
      if (list.any((v) => v['date'] == r['date'])) {
        throw const FormatException('Duplicate result date');
      }
      list.add(r);
    }
    if (out.length != groups.length ||
        !out.keys.every(groups.contains) ||
        out.values.any((v) => v.length != 2)) {
      throw const FormatException('Missing bounded result group/date');
    }
    for (final list in out.values) {
      list.sort((a, b) => (a['date'] as String).compareTo(b['date']));
    }
    if (jsonEncode(
          out['powerball/base/null']!.map((r) => r['date']).toList(),
        ) !=
        jsonEncode(
          out['powerball/double_play/null']!.map((r) => r['date']).toList(),
        )) {
      throw const FormatException('Double Play dates not paired');
    }
    return out;
  }

  static void continuity(
    List oldRows,
    Map oldWindow,
    List nextRows,
    Map nextWindow,
    DateTime retrieved,
  ) {
    final next = validate(nextRows, nextWindow, retrieved);
    if ((nextWindow['start'] as String).compareTo(oldWindow['start']) < 0 ||
        (nextWindow['end'] as String).compareTo(oldWindow['end']) < 0) {
      throw const FormatException('Query regression');
    }
    for (final g in groups) {
      final before = oldRows.where((r) => group(r) == g).cast<Map>().toList()
        ..sort((a, b) => (a['date'] as String).compareTo(b['date']));
      final after = next[g]!;
      if (before.length != 2 ||
          (after.first['date'] as String).compareTo(before.first['date']) < 0 ||
          (after.last['date'] as String).compareTo(before.last['date']) < 0) {
        throw const FormatException('Result window regression');
      }
      for (final old in before) {
        final matches = after.where((r) => r['date'] == old['date']);
        if (matches.isEmpty) {
          if ((old['date'] as String).compareTo(after.first['date']) >= 0) {
            throw const FormatException('Result lost inside window');
          }
          continue;
        }
        final current = matches.single;
        for (final key in ['numbers', 'specialBall', 'multiplier']) {
          if (jsonEncode(old[key]) != jsonEncode(current[key])) {
            throw const FormatException('Published result correction');
          }
        }
      }
    }
  }
}
