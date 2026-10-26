import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/new_mexico_report_validator.dart';
import 'package:lottery_atlas/services/new_mexico_coverage_validator.dart';
import 'package:lottery_atlas/services/new_mexico_coverage_loader.dart';

void main() {
  final raw = File(
    'data/new_mexico_coverage.generated.json',
  ).readAsStringSync();
  Map<String, dynamic> fixture() => jsonDecode(raw);
  test('all four report schemas validate changing counts on new dates', () {
    final d = fixture();
    for (final r in (d['results'] as List).where((r) => r['report'] != null)) {
      final p = r['report'];
      r['date'] = '2026-10-26';
      p['date'] = r['date'];
      final tier = (p['tiers'] as List).firstWhere(
        (t) => t['prizeValue'] != null,
      );
      tier['sourceWinners'] += 1;
      p['totalPrizesWon'] += 1;
      p['totalPrizeValue'] += tier['prizeValue'];
      NewMexicoReportValidator.validate(r);
    }
  });
  test(
    'report mismatches units counts totals and jackpot unknowns rejected',
    () {
      for (final mutate in <void Function(Map)>[
        (p) => p['date'] = '2026-10-01',
        (p) => p['countUnit'] = 'tickets',
        (p) => p['geography'] = 'National',
        (p) => p['totalPrizesWon'] += 1,
        (p) => p['tiers'][1]['sourceWinners'] = -1,
        (p) => p['tiers'][0]['sourceWinners'] = 1,
        (p) => p['tiers'][1]['column'] = 'invented',
        (p) => p['tiers'].removeLast(),
      ]) {
        final r = (fixture()['results'] as List).firstWhere(
          (r) =>
              r['game'] == 'powerball' &&
              r['variant'] == 'base' &&
              r['report'] != null,
        );
        mutate(r['report']);
        expect(
          () => NewMexicoReportValidator.validate(r),
          throwsFormatException,
        );
      }
    },
  );
  test('paired report prices follow new multiplier except fixed PB Match5', () {
    final r = (fixture()['results'] as List).firstWhere(
      (r) =>
          r['game'] == 'powerball' &&
          r['variant'] == 'base' &&
          r['report'] != null,
    );
    r['multiplier'] = 5;
    final p = r['report'];
    p['multiplier'] = 5;
    for (var i = 2; i < (p['tiers'] as List).length; i += 2) {
      final t = p['tiers'][i];
      t['prizeValue'] = i == 2 ? 2000000 : p['tiers'][i - 1]['prizeValue'] * 5;
      t['prizeLabel'] = '\$${t['prizeValue']}';
    }
    p['totalPrizeValue'] = (p['tiers'] as List).fold<int>(
      0,
      (n, t) =>
          n + (t['sourceWinners'] as int) * ((t['prizeValue'] as int?) ?? 0),
    );
    NewMexicoReportValidator.validate(r);
  });
  test('dynamic completed result adopted through production loader', () async {
    final d = fixture();
    final rows =
        (d['results'] as List)
            .where((r) => r['game'] == 'pick3plus' && r['session'] == 'DAY')
            .toList()
          ..sort((a, b) => (a['date'] as String).compareTo(b['date']));
    rows.first['date'] = '2026-10-26';
    rows.first['numbers'] = ['0', '0', '1'];
    final next = jsonEncode(d);
    String? saved;
    final result = await NewMexicoCoverageLoader(
      readCache: () async => raw,
      fetchRemote: () async => next,
      writeCache: (s) async {
        saved = s;
      },
    ).load();
    expect(saved, next);
    expect(result, d);
  });
  test('report loss and same-date correction reject', () {
    final old = fixture(), next = fixture();
    final r = (next['results'] as List).firstWhere((r) => r['report'] != null);
    final p = r['report'];
    p['tiers'][1]['sourceWinners'] += 1;
    p['totalPrizesWon'] += 1;
    p['totalPrizeValue'] += p['tiers'][1]['prizeValue'];
    expect(
      () =>
          NewMexicoReportValidator.continuity(old['results'], next['results']),
      throwsFormatException,
    );
    r['report'] = null;
    r['reportStatus'] = 'unavailable';
    expect(
      () => NewMexicoCoverageValidator.decode(jsonEncode(next)),
      throwsFormatException,
    );
  });
  test(
    'older report joins original capture while current endpoint advances',
    () {
      final d = fixture();
      final r = (d['results'] as List).firstWhere((r) => r['report'] != null);
      final p = r['report'];
      final s = (d['sources'] as List).firstWhere(
        (s) => s['url'] == p['sourceUrl'],
      );
      d['retainedReportSources'] = [jsonDecode(jsonEncode(s))];
      s['retrievedAt'] = d['updatedAt'];
      NewMexicoCoverageValidator.decode(jsonEncode(d));
      d['retainedReportSources'][0]['sha256'] = 'bad';
      expect(
        () => NewMexicoCoverageValidator.decode(jsonEncode(d)),
        throwsFormatException,
      );
    },
  );
  test('exact-date gap upgrades with valid report and provenance', () {
    final d = fixture();
    final rows = (d['results'] as List)
        .where((r) => r['game'] == 'powerball' && r['variant'] == 'double_play')
        .toList();
    final latest = rows.firstWhere((r) => r['report'] != null),
        older = rows.firstWhere((r) => r['report'] == null);
    final p = jsonDecode(jsonEncode(latest['report']));
    p['date'] = older['date'];
    older['report'] = p;
    older['reportStatus'] = 'available';
    NewMexicoCoverageValidator.decode(jsonEncode(d));
  });
  test('query advancement preserves official sources and overlap', () {
    final prior = fixture(), next = fixture();
    prior['queryWindow']['start'] = '2026-10-11';
    prior['queryWindow']['end'] = '2026-10-25';
    for (final row in prior['results']) {
      row['sourceUrl'] = (row['sourceUrl'] as String)
          .replaceAll('10%2F12%2F2026', '10%2F11%2F2026')
          .replaceAll('10%2F26%2F2026', '10%2F25%2F2026');
    }
    for (final source in prior['sources']) {
      source['url'] = (source['url'] as String)
          .replaceAll('10%2F12%2F2026', '10%2F11%2F2026')
          .replaceAll('10%2F26%2F2026', '10%2F25%2F2026');
    }
    NewMexicoCoverageValidator.continuity(prior, next);
    next['sources'][0]['url'] = 'https://example.com';
    expect(
      () => NewMexicoCoverageValidator.continuity(prior, next),
      throwsFormatException,
    );
  });
}
