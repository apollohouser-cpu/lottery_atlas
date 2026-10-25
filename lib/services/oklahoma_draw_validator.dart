import 'dart:convert';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

class OklahomaDrawValidator {
  static bool _ready = false;
  static const ranges = {
    'powerball': [5, 1, 69, 26],
    'megamillions': [5, 1, 70, 24],
    'lotto-america': [5, 1, 52, 10],
    'millionaire-for-life': [5, 1, 58, 5],
    'pick3': [3, 0, 9, 0],
    'cash-5': [5, 1, 36, 0],
    'powerball-xs-os': [8, 1, 32, 0],
  };
  static String group(Map r) => '${r['game']}/${r['variant']}';
  static Map<String, List<Map>> groups(List rows) {
    final out = <String, List<Map>>{};
    for (final r in rows) {
      (out[group(r as Map)] ??= []).add(r);
    }
    return out;
  }

  static String canonical(dynamic v) {
    dynamic sorted(dynamic x) {
      if (x is Map) {
        return {
          for (final k in (x.keys.cast<String>().toList()..sort()))
            k: sorted(x[k]),
        };
      }
      if (x is List) {
        return x.map(sorted).toList();
      }
      return x;
    }

    return jsonEncode(sorted(v));
  }

  static Map fixed(Map r) => Map.from(r)
    ..removeWhere(
      (k, v) => [
        'date',
        'drawDateTimeUTC',
        'numbers',
        'specialBall',
        'multiplier',
        'retrievedAt',
      ].contains(k),
    );
  static void validate(List rows, List baseline) {
    if (!_ready) {
      tzdata.initializeTimeZones();
      _ready = true;
    }
    final expected = groups(baseline), actual = groups(rows);
    if (canonical(actual.keys.toList()..sort()) !=
        canonical(expected.keys.toList()..sort())) {
      throw const FormatException('Missing or unexpected result group');
    }
    for (final key in actual.keys) {
      final entries = actual[key]!;
      if (entries.isEmpty || entries.length > 2) {
        throw const FormatException('Invalid result window');
      }
      String? previous;
      for (final r in entries) {
        final template = expected[key]!.first;
        if (canonical(fixed(r)) != canonical(fixed(template))) {
          throw const FormatException('Changed result metadata');
        }
        final stamp = r['drawDateTimeUTC'];
        if (stamp is! String ||
            !RegExp(
              r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$',
            ).hasMatch(stamp)) {
          throw const FormatException('Invalid draw UTC time');
        }
        final utc = DateTime.parse(stamp);
        if (utc.toIso8601String().replaceFirst('.000Z', 'Z') != stamp ||
            utc.isAfter(DateTime.parse(r['retrievedAt'] as String))) {
          throw const FormatException('Invalid or future draw');
        }
        final local = tz.TZDateTime.from(
          utc,
          tz.getLocation('America/Chicago'),
        );
        final day =
            '${local.year.toString().padLeft(4, '0')}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')}';
        if (r['date'] != day ||
            (previous != null && day.compareTo(previous) >= 0)) {
          throw const FormatException('Invalid local date/window order');
        }
        previous = day;
        final spec = ranges[r['game']]!;
        final values = r['numbers'];
        if (values is! List ||
            values.length != spec[0] ||
            values.any((n) => n is! int || n < spec[1] || n > spec[2]) ||
            (r['game'] != 'pick3' && values.toSet().length != values.length)) {
          throw const FormatException('Invalid result numbers');
        }
        final bonus = r['specialBall'];
        if (spec[3] == 0
            ? bonus != null
            : bonus is! int || bonus < 1 || bonus > spec[3]) {
          throw const FormatException('Invalid special ball');
        }
        final multiplier = r['multiplier'];
        final needs =
            r['variant'] == 'base' &&
            ['powerball', 'lotto-america'].contains(r['game']);
        final allowed = r['game'] == 'powerball'
            ? [2, 3, 4, 5, 10]
            : [2, 3, 4, 5];
        if (needs
            ? multiplier is! int || !allowed.contains(multiplier)
            : multiplier != null) {
          throw const FormatException('Invalid multiplier');
        }
      }
    }
    final pb = actual['powerball/base']!, dp = actual['powerball/double_play']!;
    if (pb.length != dp.length) {
      throw const FormatException('Double Play window mismatch');
    }
    for (var i = 0; i < pb.length; i++) {
      if (pb[i]['date'] != dp[i]['date'] ||
          !DateTime.parse(
            dp[i]['drawDateTimeUTC'],
          ).isAfter(DateTime.parse(pb[i]['drawDateTimeUTC']))) {
        throw const FormatException('Double Play parent mismatch');
      }
    }
    continuity(baseline, rows);
  }

  static void continuity(List old, List next) {
    final before = groups(old), after = groups(next);
    if (canonical(before.keys.toList()..sort()) !=
        canonical(after.keys.toList()..sort())) {
      throw const FormatException('Result group loss');
    }
    for (final key in before.keys) {
      final current = after[key]!;
      final dates = current.map((r) => r['date'] as String).toList()..sort();
      final priorDates = before[key]!.map((r) => r['date'] as String).toList()
        ..sort();
      if (dates.last.compareTo(priorDates.last) < 0) {
        throw const FormatException('Result window regression');
      }
      for (final r in before[key]!) {
        final matches = current.where((n) => n['date'] == r['date']);
        if (matches.isEmpty) {
          if ((r['date'] as String).compareTo(dates.first) >= 0) {
            throw const FormatException('Result window hole');
          }
        } else {
          Map content(Map x) => Map.from(x)..remove('retrievedAt');
          if (canonical(content(r)) != canonical(content(matches.single))) {
            throw const FormatException('Result correction');
          }
        }
      }
    }
  }
}
