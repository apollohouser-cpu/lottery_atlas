import 'dart:convert';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Validates projected results against reviewed group and report contracts.
class IdahoDrawValidator {
  static bool _ready = false;
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
      throw const FormatException('Invalid Idaho draw/report');
  static dynamic copy(dynamic v) => jsonDecode(jsonEncode(v));
  static int ball(dynamic v, int low, int high, {int? width}) {
    if (v is! String ||
        !RegExp(r'^[0-9]{1,2}$').hasMatch(v) ||
        (width != null && v.length != width)) {
      fail();
    }
    final n = int.parse(v);
    if (n < low || n > high) {
      fail();
    }
    return n;
  }

  static void validate(dynamic rows, List baseline, DateTime collected) {
    if (!_ready) {
      tzdata.initializeTimeZones();
      _ready = true;
    }
    final local = tz.TZDateTime.from(
      collected,
      tz.getLocation('America/Boise'),
    );
    final asOf = DateTime.utc(local.year, local.month, local.day);
    if (rows is! List || rows.length != baseline.length) {
      fail();
    }
    final templates = <String, dynamic>{};
    for (final r in baseline) {
      templates.putIfAbsent(r['group'], () => r);
    }
    final dates = <String, List<String>>{};
    for (final row in rows) {
      if (row is! Map || !templates.containsKey(row['group'])) {
        fail();
      }
      final g = row['group'] as String;
      final template = templates[g];
      final date = row['drawDate'];
      if (date is! String || !RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date)) {
        fail();
      }
      final day = DateTime.tryParse('${date}T00:00:00Z');
      if (day == null ||
          day.toIso8601String().substring(0, 10) != date ||
          day.isAfter(asOf)) {
        fail();
      }
      final groupDates = dates.putIfAbsent(g, () => []);
      if (groupDates.contains(date)) {
        fail();
      }
      groupDates.add(date);
      final pick = g.startsWith('pick-');
      final xs = g == 'powerball-xs-os';
      final max =
          {
            'powerball': 69,
            'powerball-double-play': 69,
            'mega-millions': 70,
            'lotto-america': 52,
            'idaho-cash': 45,
            'millionaire-for-life': 58,
            'powerball-xs-os': 32,
          }[g] ??
          9;
      final numbers = row['numbers'];
      final size = pick ? (g.startsWith('pick-3') ? 3 : 4) : (xs ? 8 : 5);
      if (numbers is! List || numbers.length != size) {
        fail();
      }
      final values = numbers
          .map(
            (v) =>
                ball(v, pick ? 0 : 1, max, width: pick ? 1 : (xs ? 2 : null)),
          )
          .toSet();
      if (!pick && values.length != size) {
        fail();
      }
      final normalized = copy(row) as Map;
      if (row.containsKey('reportProvenance')) {
        final p = row['reportProvenance'];
        final latest = rows
            .where((r) => r['group'] == g)
            .map((r) => r['drawDate'] as String)
            .reduce((a, b) => a.compareTo(b) > 0 ? a : b);
        if (g != 'millionaire-for-life' ||
            row['report'] == null ||
            date.compareTo(latest) >= 0 ||
            p is! Map ||
            p.length != 3 ||
            p['sourceUrl'] != row['sourceUrl'] ||
            p['sha256'] is! String ||
            !RegExp(r'^[0-9a-f]{64}$').hasMatch(p['sha256']) ||
            p['collectionStartedAt'] is! String ||
            !RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(p['collectionStartedAt'])) {
          fail();
        }
        final original = DateTime.tryParse(p['collectionStartedAt']);
        if (original == null ||
            original.isAfter(collected) ||
            original.isBefore(day)) {
          fail();
        }
        normalized.remove('reportProvenance');
      }
      normalized['numbers'] = template['numbers'];
      if (template.containsKey('specialNumber')) {
        ball(
          row['specialNumber'],
          1,
          {
            'powerball': 26,
            'powerball-double-play': 26,
            'mega-millions': 24,
            'lotto-america': 10,
            'millionaire-for-life': 5,
          }[g]!,
        );
        normalized['specialNumber'] = template['specialNumber'];
      }
      if (template.containsKey('multiplier')) {
        if (row['multiplier'] is! int ||
            !(g == 'powerball' ? [2, 3, 4, 5, 10] : [2, 3, 4, 5]).contains(
              row['multiplier'],
            )) {
          fail();
        }
        normalized['multiplier'] = template['multiplier'];
      }
      if (xs) {
        if (!equal(
          row['imageUrls'],
          numbers
              .map(
                (n) =>
                    'https://d2kx0heugfrx3y.cloudfront.net/nfl/logos-with-names/$n.png',
              )
              .toList(),
        )) {
          fail();
        }
        normalized['imageUrls'] = template['imageUrls'];
      }
      final url = (template['sourceUrl'] as String).replaceAll(
        template['drawDate'],
        date,
      );
      if (row['sourceUrl'] != url) {
        fail();
      }
      normalized['sourceUrl'] = template['sourceUrl'];
      normalized['drawDate'] = template['drawDate'];
      final report = row['report'];
      if (pick) {
        if (report != null || row['reportGap'] != template['reportGap']) {
          fail();
        }
      } else if (report == null) {
        final gap = g == 'millionaire-for-life'
            ? 'No exact-date Idaho HTML report available.'
            : 'No dated Idaho report rows supplied.';
        if (row['reportGap'] != gap) {
          fail();
        }
      } else {
        if (report is! Map ||
            row['reportGap'] != null ||
            report['sourceUrl'] != url) {
          fail();
        }
        final expected = template['report'];
        final normalizedReport = copy(report) as Map;
        final tiers = normalizedReport['tiers'];
        if (tiers is! List || tiers.length != expected['tiers'].length) {
          fail();
        }
        for (var i = 0; i < tiers.length; i++) {
          final tier = tiers[i];
          if (tier is! Map ||
              tier['publishedWinnerCount'] is! int ||
              tier['publishedWinnerCount'] < 0 ||
              tier['publishedWinnerCount'] > 9007199254740991) {
            fail();
          }
          tier['publishedWinnerCount'] =
              expected['tiers'][i]['publishedWinnerCount'];
        }
        normalizedReport['sourceUrl'] = expected['sourceUrl'];
        if (g == 'millionaire-for-life') {
          if (report['drawDate'] != date) {
            fail();
          }
          normalizedReport['drawDate'] = expected['drawDate'];
        }
        if (!equal(normalizedReport, expected)) {
          fail();
        }
      }
      normalized['report'] = template['report'];
      normalized['reportGap'] = template['reportGap'];
      if (!equal(normalized, template)) {
        fail();
      }
    }
    if (dates.length != templates.length ||
        dates.values.any((d) => d.length != 2)) {
      fail();
    }
    for (final pair in [
      ['powerball', 'powerball-double-play'],
      ['pick-3-day', 'pick-3-night'],
      ['pick-4-day', 'pick-4-night'],
    ]) {
      dates[pair[0]]!.sort();
      dates[pair[1]]!.sort();
      if (!equal(dates[pair[0]], dates[pair[1]])) {
        fail();
      }
    }
    continuity(baseline, rows);
  }

  static void continuity(List old, List next) {
    final groups = old.map((r) => r['group']).toSet();
    if (!equal(
      groups.toList()..sort(),
      next.map((r) => r['group']).toSet().toList()..sort(),
    )) {
      fail();
    }
    for (final g in groups) {
      final a = old.where((r) => r['group'] == g).toList()
        ..sort((a, b) => (a['drawDate'] as String).compareTo(b['drawDate']));
      final b = next.where((r) => r['group'] == g).toList()
        ..sort((a, b) => (a['drawDate'] as String).compareTo(b['drawDate']));
      if (a.length != 2 || b.length != 2) {
        fail();
      }
      for (var i = 0; i < 2; i++) {
        if ((b[i]['drawDate'] as String).compareTo(a[i]['drawDate']) < 0) {
          fail();
        }
      }
      for (final prior in a) {
        for (final current in b.where(
          (r) => r['drawDate'] == prior['drawDate'],
        )) {
          final normalized = copy(prior);
          if (prior['report'] == null && current['report'] != null) {
            normalized['report'] = current['report'];
            normalized['reportGap'] = current['reportGap'];
          }
          if (!prior.containsKey('reportProvenance') &&
              current.containsKey('reportProvenance')) {
            if (g != 'millionaire-for-life' ||
                prior['report'] == null ||
                !equal(prior['report'], current['report'])) {
              fail();
            }
            normalized['reportProvenance'] = current['reportProvenance'];
          }
          if (!equal(normalized, current)) {
            fail();
          }
        }
      }
    }
  }
}
