import 'dart:convert';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'north_dakota_coverage_contract.dart';

class NorthDakotaCoverageValidator {
  static final Map<String, dynamic> baseline = jsonDecode(
    northDakotaCoverageContractJson,
  );
  static bool _ready = false;
  static const ranges = {
    'powerball': [5, 69, 1, 26],
    'mega-millions': [5, 70, 1, 24],
    'millionaire-for-life': [5, 58, 1, 5],
    'lotto-america': [5, 52, 1, 10],
    '2by2': [2, 26, 2, 26],
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
      throw const FormatException('Invalid North Dakota coverage');
  static Map strip(Map row, List<String> keys) =>
      Map.from(row)..removeWhere((k, v) => keys.contains(k));
  static DateTime time(dynamic value) {
    if (value is! String || !RegExp(r'(Z|\+00:00)$').hasMatch(value)) {
      fail();
    }
    final t = DateTime.parse(value);
    if (t.isAfter(DateTime.now().toUtc().add(const Duration(minutes: 5)))) {
      fail();
    }
    return t;
  }

  static DateTime day(dynamic value) {
    if (value is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value)) {
      fail();
    }
    final t = DateTime.parse('${value}T00:00:00Z');
    if (t.toIso8601String().substring(0, 10) != value) {
      fail();
    }
    return t;
  }

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
    if (updated.isBefore(time(prior['updatedAt']))) {
      fail();
    }
    final sources = next['sources'] as List;
    if (sources.length != 11) {
      fail();
    }
    DateTime? previous;
    for (var i = 0; i < 11; i++) {
      final s = sources[i] as Map;
      final at = time(s['retrievedAt']);
      if (at.isBefore(time(prior['sources'][i]['retrievedAt'])) ||
          at.isAfter(updated) ||
          (previous != null && at.isBefore(previous))) {
        fail();
      }
      previous = at;
      if (s['bytes'] is! int ||
          s['bytes'] <= 0 ||
          s['sha256'] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(s['sha256'])) {
        fail();
      }
      if (!equal(
        strip(s, ['bytes', 'sha256', 'retrievedAt']),
        strip(baseline['sources'][i], ['bytes', 'sha256', 'retrievedAt']),
      )) {
        fail();
      }
    }
    if (sources.last['retrievedAt'] != next['updatedAt']) {
      fail();
    }
    final catalog = next['catalog'] as Map;
    if (!equal(
          strip(catalog, ['retrievedAt']),
          strip(baseline['catalog'], ['retrievedAt']),
        ) ||
        catalog['retrievedAt'] != sources[0]['retrievedAt']) {
      fail();
    }
    final rules = next['rules'] as List, rows = next['results'] as List;
    if (rules.length != 5 || rows.length != 10) {
      fail();
    }
    for (var i = 0; i < 5; i++) {
      if (!equal(
            strip(rules[i], ['retrievedAt']),
            strip(baseline['rules'][i], ['retrievedAt']),
          ) ||
          rules[i]['retrievedAt'] != sources[2 * i + 2]['retrievedAt']) {
        fail();
      }
      final game = ranges.keys.elementAt(i), spec = ranges.values.elementAt(i);
      final group = rows.sublist(2 * i, 2 * i + 2);
      final old = (prior['results'] as List).sublist(2 * i, 2 * i + 2);
      final template = baseline['results'][2 * i] as Map;
      for (final value in group) {
        final r = value as Map;
        final date = day(r['drawDate']);
        final captured = tz.TZDateTime.from(
          time(sources[2 * i + 1]['retrievedAt']),
          tz.getLocation('America/Chicago'),
        );
        final localDate = DateTime.utc(
          captured.year,
          captured.month,
          captured.day,
        );
        final weekdays = game == 'powerball' || game == 'lotto-america'
            ? [1, 3, 6]
            : game == 'mega-millions'
            ? [2, 5]
            : [1, 2, 3, 4, 5, 6, 7];
        if (date.isBefore(DateTime.utc(2026, 9, 1)) ||
            date.isAfter(localDate) ||
            !weekdays.contains(date.weekday)) {
          fail();
        }
        void numbers(dynamic values, int count, int max) {
          if (values is! List ||
              values.length != count ||
              values.toSet().length != count ||
              values.any((n) => n is! int || n < 1 || n > max)) {
            fail();
          }
        }

        numbers(r['numbers'], spec[0], spec[1]);
        numbers(r['bonusNumbers'], spec[2], spec[3]);
        final multiplierGame = game == 'powerball' || game == 'lotto-america';
        if (multiplierGame &&
            (r['multiplier'] is! int ||
                !(game == 'powerball' ? [2, 3, 4, 5, 10] : [2, 3, 4, 5])
                    .contains(r['multiplier']))) {
          fail();
        }
        final variable = [
          'drawDate',
          'numbers',
          'bonusNumbers',
          'sourceRetrievedAt',
          if (multiplierGame) 'multiplier',
        ];
        if (!equal(strip(r, variable), strip(template, variable)) ||
            r['sourceRetrievedAt'] != sources[2 * i + 1]['retrievedAt']) {
          fail();
        }
        for (final p in old.where((p) => p['drawDate'] == r['drawDate'])) {
          if (!equal(
            strip(r, ['sourceRetrievedAt']),
            strip(p, ['sourceRetrievedAt']),
          )) {
            fail();
          }
        }
      }
      if (!day(group.first['drawDate']).isAfter(day(group.last['drawDate']))) {
        fail();
      }
      for (var j = 0; j < 2; j++) {
        if (day(group[j]['drawDate']).isBefore(day(old[j]['drawDate']))) {
          fail();
        }
      }
      for (final p in old) {
        if (!day(p['drawDate']).isBefore(day(group.last['drawDate'])) &&
            !group.any((r) => r['drawDate'] == p['drawDate'])) {
          fail();
        }
      }
    }
    final normalized = Map.from(next);
    for (final key in ['updatedAt', 'sources', 'catalog', 'rules', 'results']) {
      normalized[key] = baseline[key];
    }
    if (!equal(normalized, baseline)) {
      fail();
    }
  }
}
