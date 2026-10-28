import 'dart:convert';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'montana_coverage_contract.dart';

class MontanaCoverageValidator {
  static final Map<String, dynamic> baseline = jsonDecode(
    montanaCoverageContractJson,
  );
  static bool _ready = false;
  static const ranges = {
    'powerball': [5, 69, 1, 26],
    'powerball-double-play': [5, 69, 1, 26],
    'mega-millions': [5, 70, 1, 24],
    'millionaire-for-life': [5, 58, 1, 5],
    'lotto-america': [5, 52, 1, 10],
    'montana-cash': [5, 45, 0, 0],
    'big-sky-bonus': [4, 31, 1, 16],
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
      throw const FormatException('Invalid Montana coverage');
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
    if (sources.length != 24) {
      fail();
    }
    DateTime? previous;
    for (var i = 0; i < 24; i++) {
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
    for (final key in ['status', 'raffle', 'endings']) {
      final field = key == 'endings' ? 'sourceRetrievedAt' : 'retrievedAt';
      final index = key == 'status'
          ? 0
          : key == 'raffle'
          ? 22
          : 23;
      if (!equal(strip(next[key], [field]), strip(baseline[key], [field])) ||
          next[key][field] != sources[index]['retrievedAt']) {
        fail();
      }
    }
    if (next['endings']['sha256'] != sources[23]['sha256']) fail();
    final catalogs = next['catalogs'] as Map;
    if (catalogs.length != 2 ||
        !catalogs.containsKey('scratch') ||
        !catalogs.containsKey('treasure-play')) {
      fail();
    }
    for (final kind in ['scratch', 'treasure-play']) {
      final value = jsonDecode(jsonEncode(catalogs[kind])) as Map;
      final expected =
          jsonDecode(jsonEncode(baseline['catalogs'][kind])) as Map;
      final entries = value['entries'] as List;
      for (final e in entries) {
        final jackpot = e['advertisedJackpot'] as Map;
        final amount = jackpot['amountText'];
        if (jackpot['status'] == 'published') {
          if (amount is! String ||
              !RegExp(r'^\$(?:0|[1-9]\d{0,2}(?:,\d{3})*)$').hasMatch(amount)) {
            fail();
          }
        } else if (amount != null) {
          fail();
        }
        jackpot['amountText'] = null;
      }
      for (final e in expected['entries']) {
        e['advertisedJackpot']['amountText'] = null;
      }
      entries.sort(
        (a, b) =>
            (a['cmsEntryId'] as String).compareTo(b['cmsEntryId'] as String),
      );
      (expected['entries'] as List).sort(
        (a, b) =>
            (a['cmsEntryId'] as String).compareTo(b['cmsEntryId'] as String),
      );
      if (!equal(
            strip(value, ['retrievedAt']),
            strip(expected, ['retrievedAt']),
          ) ||
          value['retrievedAt'] !=
              sources[kind == 'scratch' ? 18 : 21]['retrievedAt']) {
        fail();
      }
    }
    final rules = next['rules'] as List, rows = next['results'] as List;
    if (rules.length != 6 || rows.length != 14) fail();
    for (var i = 0; i < 6; i++) {
      if (!equal(
            strip(rules[i], ['retrievedAt']),
            strip(baseline['rules'][i], ['retrievedAt']),
          ) ||
          rules[i]['retrievedAt'] != sources[i + 1]['retrievedAt']) {
        fail();
      }
    }
    for (var i = 0; i < 7; i++) {
      final sourceIndex = i == 0 ? 1 : i;
      final game = ranges.keys.elementAt(i), spec = ranges.values.elementAt(i);
      final group = rows.sublist(2 * i, 2 * i + 2);
      final old = (prior['results'] as List).sublist(2 * i, 2 * i + 2);
      final template = baseline['results'][2 * i] as Map;
      for (final value in group) {
        final r = value as Map;
        final date = day(r['drawDate']);
        final captured = tz.TZDateTime.from(
          time(sources[sourceIndex]['retrievedAt']),
          tz.getLocation('America/Denver'),
        );
        final localDate = DateTime.utc(
          captured.year,
          captured.month,
          captured.day,
        );
        final weekdays =
            game == 'powerball' ||
                game == 'powerball-double-play' ||
                game == 'lotto-america'
            ? [1, 3, 6]
            : game == 'mega-millions'
            ? [2, 5]
            : game == 'montana-cash'
            ? [3, 6]
            : [1, 2, 3, 4, 5, 6, 7];
        if (date.isBefore(DateTime.utc(2026, 4, 26)) ||
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
            r['sourceRetrievedAt'] != sources[sourceIndex]['retrievedAt']) {
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
    for (final key in [
      'updatedAt',
      'sources',
      'catalogs',
      'status',
      'raffle',
      'endings',
      'rules',
      'results',
    ]) {
      normalized[key] = baseline[key];
    }
    if (!equal(normalized, baseline)) {
      fail();
    }
  }
}
