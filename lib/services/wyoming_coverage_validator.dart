import 'dart:convert';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'wyoming_coverage_contract.dart';

class WyomingCoverageValidator {
  static final Map<String, dynamic> baseline = jsonDecode(
    wyomingCoverageContractJson,
  );
  static bool _ready = false;
  static const ranges = {
    'cowboy-draw': [5, 45, 0, 0],
    'powerball': [5, 69, 1, 26],
    'mega-millions': [5, 70, 1, 24],
    'millionaire-for-life': [5, 58, 1, 5],
    '2by2': [2, 26, 2, 26],
    'keno': [20, 80, 0, 0],
  };
  static bool equal(dynamic a, dynamic b) {
    if (a is Map && b is Map) {
      return a.length == b.length &&
          a.keys.every((k) => b.containsKey(k) && equal(a[k], b[k]));
    }
    if (a is List && b is List) {
      return a.length == b.length &&
          List.generate(a.length, (i) => i).every((i) => equal(a[i], b[i]));
    }
    return a == b;
  }

  static Never fail() =>
      throw const FormatException('Invalid Wyoming coverage contract');
  static DateTime time(dynamic value) {
    if (value is! String || !RegExp(r'(Z|\+00:00)$').hasMatch(value)) fail();
    final t = DateTime.parse(value);
    if (t.isAfter(DateTime.now().toUtc().add(const Duration(minutes: 5)))) {
      fail();
    }
    return t;
  }

  static Map strip(Map row, List<String> keys) =>
      Map.from(row)..removeWhere((k, v) => keys.contains(k));
  static Map<String, dynamic> decode(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    continuity(baseline, data);
    return data;
  }

  static void continuity(Map prior, Map next) {
    if (!_ready) {
      tzdata.initializeTimeZones();
      _ready = true;
    }
    final updated = time(next['updatedAt']);
    if (updated.isBefore(time(prior['updatedAt']))) fail();
    for (final name in ['queryWindow', 'kenoWindow']) {
      final keys = (next[name] as Map).keys;
      final expected = (baseline[name] as Map).keys;
      if (keys.length != expected.length ||
          keys.any((k) => !expected.contains(k))) {
        fail();
      }
      for (final key in ['start', 'end']) {
        if (time(next[name][key]).isBefore(time(prior[name][key]))) fail();
      }
      if (time(next[name]['start']).isAfter(time(next[name]['end'])) ||
          time(next[name]['end']).isAfter(updated)) {
        fail();
      }
    }
    final kw = next['kenoWindow'] as Map;
    if (kw['firstId'] is! int ||
        kw['lastId'] is! int ||
        kw['firstId'] <= 0 ||
        kw['lastId'] - kw['firstId'] != 4) {
      fail();
    }
    final sources = next['sources'] as List;
    final templates = baseline['sources'] as List;
    if (sources.length != 21) fail();
    DateTime? previous;
    for (var i = 0; i < sources.length; i++) {
      final s = sources[i] as Map;
      final stamp = time(s['retrievedAt']);
      if (stamp.isBefore(time(prior['sources'][i]['retrievedAt']))) {
        fail();
      }
      if (stamp.isAfter(updated) ||
          stamp.isBefore(time(next['queryWindow']['end'])) ||
          (previous != null && stamp.isBefore(previous))) {
        fail();
      }
      previous = stamp;
      if (s.length != 4 ||
          s['bytes'] is! int ||
          s['bytes'] <= 0 ||
          s['sha256'] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(s['sha256'])) {
        fail();
      }
      final u = Uri.parse(s['url']);
      final b = Uri.parse(templates[i]['url']);
      if (u.scheme != b.scheme ||
          u.authority != b.authority ||
          u.fragment.isNotEmpty) {
        fail();
      }
      if (i >= 3 && i <= 7) {
        if (u.path != b.path ||
            u.queryParameters.length != 2 ||
            time(u.queryParameters['startDate']) !=
                time(next['queryWindow']['start']) ||
            time(u.queryParameters['endDate']) !=
                time(next['queryWindow']['end'])) {
          fail();
        }
      } else if (i == 8 || i == 9) {
        final parts = u.pathSegments, old = b.pathSegments;
        if (u.hasQuery ||
            parts.length != old.length ||
            !equal(
              parts.take(parts.length - 2).toList(),
              old.take(old.length - 2).toList(),
            )) {
          fail();
        }
        if (i == 8) {
          if (time(parts[parts.length - 2]) != time(kw['start']) ||
              time(parts.last) != time(kw['end'])) {
            fail();
          }
        } else if (parts[parts.length - 2] != '${kw['firstId']}' ||
            parts.last != '${kw['lastId']}') {
          fail();
        }
      } else if (s['url'] != templates[i]['url']) {
        fail();
      }
    }
    if (time(sources.last['retrievedAt']) != updated) fail();
    final rules = next['rules'] as List;
    if (rules.length != 6) fail();
    var sourceIndex = 10;
    for (var i = 0; i < rules.length; i++) {
      final rule = rules[i] as Map, original = baseline['rules'][i] as Map;
      if (!equal(
        strip(rule, ['retrievedAt', 'imageRetrievedAt']),
        strip(original, ['retrievedAt', 'imageRetrievedAt']),
      )) {
        fail();
      }
      if (rule['retrievedAt'] != sources[sourceIndex++]['retrievedAt']) fail();
      if (rule.containsKey('image')) {
        if (rule['imageRetrievedAt'] != sources[sourceIndex]['retrievedAt'] ||
            rule['image']['sha256'] != sources[sourceIndex]['sha256']) {
          fail();
        }
        sourceIndex++;
      } else if (rule['imageRetrievedAt'] != null) {
        fail();
      }
    }
    final rows = next['results'] as List;
    if (rows.length != 15) fail();
    for (final game in ranges.keys) {
      final group = rows.where((r) => r['game'] == game).toList();
      final old = (prior['results'] as List)
          .where((r) => r['game'] == game)
          .toList();
      if (group.length != (game == 'keno' ? 5 : 2)) fail();
      final template =
          (baseline['results'] as List).firstWhere((r) => r['game'] == game)
              as Map;
      final spec = ranges[game]!;
      int? lastId;
      DateTime? lastTime;
      for (final dynamic value in group) {
        final r = value as Map;
        final at = time(r['drawTimeUtc']);
        final id = r['drawId'];
        if (id is! int ||
            id <= 0 ||
            (lastId != null && id >= lastId) ||
            (lastTime != null && !at.isBefore(lastTime))) {
          fail();
        }
        lastId = id;
        lastTime = at;
        final window = game == 'keno' ? kw : next['queryWindow'];
        if (at.isBefore(DateTime.utc(2026, 10, 12)) ||
            at.isBefore(time(window['start'])) ||
            at.isAfter(time(window['end']))) {
          fail();
        }
        final local = tz.TZDateTime.from(at, tz.getLocation('America/Denver'));
        final day =
            '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
        if (r['drawDate'] != day) fail();
        if (game != 'keno') {
          final cadence = {
            'cowboy-draw': [14, 0],
            'powerball': [20, 59],
            'mega-millions': [21, 0],
            'millionaire-for-life': [21, 15],
            '2by2': [20, 30],
          }[game]!;
          final days =
              {
                'cowboy-draw': [1, 4],
                'powerball': [1, 3, 6],
                'mega-millions': [2, 5],
              }[game] ??
              [1, 2, 3, 4, 5, 6, 7];
          if (!days.contains(local.weekday) ||
              local.hour != cadence[0] ||
              local.minute != cadence[1] ||
              local.second != 0 ||
              local.millisecond != 0 ||
              local.microsecond != 0) {
            fail();
          }
        } else if (id < kw['firstId'] || id > kw['lastId']) {
          fail();
        }
        void numbers(dynamic v, int count, int max) {
          if (v is! List ||
              v.length != count ||
              v.toSet().length != count ||
              v.any((n) => n is! int || n < 1 || n > max)) {
            fail();
          }
        }

        numbers(r['numbers'], spec[0], spec[1]);
        if (game != 'keno') numbers(r['bonusNumbers'], spec[2], spec[3]);
        if (game == 'powerball' &&
            (r['multiplier'] is! int ||
                ![2, 3, 4, 5, 10].contains(r['multiplier']))) {
          fail();
        }
        final index = game == 'keno'
            ? 9
            : 3 + ranges.keys.toList().indexOf(game);
        if (r['sourceRetrievedAt'] != sources[index]['retrievedAt']) fail();
        final variable = [
          'drawId',
          'drawTimeUtc',
          'drawDate',
          'numbers',
          'sourceRetrievedAt',
          if (game != 'keno') 'bonusNumbers',
          if (game == 'powerball') 'multiplier',
        ];
        if (!equal(strip(r, variable), strip(template, variable))) fail();
        for (final p in old.where((p) => p['drawId'] == id)) {
          if (!equal(
            strip(r, ['sourceRetrievedAt']),
            strip(p, ['sourceRetrievedAt']),
          )) {
            fail();
          }
        }
      }
      if (group.first['drawId'] < old.first['drawId'] ||
          group.last['drawId'] < old.last['drawId'] ||
          time(
            group.first['drawTimeUtc'],
          ).isBefore(time(old.first['drawTimeUtc'])) ||
          time(
            group.last['drawTimeUtc'],
          ).isBefore(time(old.last['drawTimeUtc']))) {
        fail();
      }
      for (final p in old) {
        if (p['drawId'] >= group.last['drawId'] &&
            !group.any((r) => r['drawId'] == p['drawId'])) {
          fail();
        }
      }
    }
    final normalized = Map.from(next);
    for (final key in [
      'updatedAt',
      'queryWindow',
      'kenoWindow',
      'sources',
      'rules',
      'results',
    ]) {
      normalized[key] = baseline[key];
    }
    if (!equal(normalized, baseline)) fail();
  }
}
