import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../../lib/services/north_carolina_draw_reports_loader.dart';
import '../../lib/services/north_carolina_draw_reports_validator.dart';

void main() {
  final raw = File(
    'data/north_carolina_draw_reports.generated.json',
  ).readAsStringSync();
  Map<String, dynamic> data() => jsonDecode(raw) as Map<String, dynamic>;
  test('all reports retain source labels, literal prizes and warnings', () {
    final d = NorthCarolinaDrawReportsValidator.decode(raw);
    expect(d['reports'].length, 28);
    expect(
      (d['reports'] as List)
          .where((r) => r.containsKey('sourceWarnings'))
          .length,
      4,
    );
  });
  test('rejects malformed groups, dates, routes, counts and lost warning', () {
    final changes = <void Function(Map<String, dynamic>)>[
      (d) => d['reports'].removeLast(),
      (d) => d['reports'][1] = d['reports'][0],
      (d) => d['reports'][0]['drawDate'] = '2026-02-30',
      (d) => d['reports'][0]['sourceUrl'] = 'https://example.com/',
      (d) => d['reports'][0]['tiers'][0]['reportedWins'] = -1,
      (d) => d['reports'][0]['tiers'].removeLast(),
      (d) => d['reports']
          .firstWhere((r) => r['game'] == 'Mega Millions')
          .remove('sourceWarnings'),
      (d) => d['reports'].firstWhere(
        (r) => r['game'] == 'Mega Millions',
      )['tiers'][2]['multiplierLabel'] = 'X10',
      (d) => d['reports'].firstWhere(
        (r) => r['game'] == 'Cash Pop',
      )['reportedPayoutCents'] = 1,
      (d) => d['reports'].firstWhere(
        (r) => r['game'] == 'Pick 3',
      )['winningDigits'][0] = 1,
      (d) => d['reports']
          .firstWhere((r) => r['game'] == 'Powerball')['variants'][1]['tiers']
          .add(d['reports'][0]['tiers'][0]),
    ];
    for (final change in changes) {
      final d = data();
      change(d);
      expect(
        () => NorthCarolinaDrawReportsValidator.decode(jsonEncode(d)),
        throwsA(anything),
      );
    }
  });
  test('date windows cannot regress', () {
    final old = data(), next = data();
    next['reports'][0]['drawDate'] = '2026-01-01';
    expect(
      () => NorthCarolinaDrawReportsValidator.continuity(old, next),
      throwsFormatException,
    );
  });
  test('invalid remote retains exact cached data without writing', () async {
    var writes = 0;
    final d = await NorthCarolinaDrawReportsLoader(
      readCache: () async => raw,
      fetchRemote: () async => '{}',
      writeCache: (_) async {
        writes++;
      },
      readBundle: () async => throw StateError('not needed'),
    ).load();
    expect(d, data());
    expect(writes, 0);
  });
  test(
    'cold bundle protects continuity and valid response survives storage failure',
    () async {
      final older = data();
      older['updatedAt'] = DateTime.parse(
        older['updatedAt'],
      ).subtract(const Duration(seconds: 1)).toIso8601String();
      final a = await NorthCarolinaDrawReportsLoader(
        readCache: () async => null,
        readBundle: () async => raw,
        fetchRemote: () async => jsonEncode(older),
        writeCache: (_) async => fail('must not write'),
      ).load();
      expect(a, data());
      final b = await NorthCarolinaDrawReportsLoader(
        readCache: () async => raw,
        fetchRemote: () async => raw,
        writeCache: (_) async => throw StateError('storage'),
      ).load();
      expect(b, data());
    },
  );
}
