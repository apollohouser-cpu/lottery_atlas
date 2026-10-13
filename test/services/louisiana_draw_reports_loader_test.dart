import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/louisiana_draw_reports_loader.dart';
import 'package:lottery_atlas/services/louisiana_draw_reports_validator.dart';

void main() {
  final raw = File(
    'data/louisiana_draw_reports.generated.json',
  ).readAsStringSync();
  Map<String, dynamic> data() => jsonDecode(raw);
  dynamic report(Map d, String game) =>
      (d['reports'] as List).firstWhere((r) => r['game'] == game);
  test('all seven families retain separate literal units and schedules', () {
    final d = LouisianaDrawReportsValidator.decode(raw);
    expect(d, data());
    expect(d['reports'].length, 14);
    expect(report(d, 'Powerball')['tiers'][0]['powerPlayWinners'], isNull);
    expect(
      report(d, 'Pick 3')['playTypes'][0].containsKey('statewideWinners'),
      false,
    );
    expect(report(d, 'Mega Millions')['tiers'][0]['multipliers'].length, 5);
  });
  test('rejects malformed units, structure, timestamps and lost warnings', () {
    final changes = <void Function(Map<String, dynamic>)>[
      (d) => d['reports'].removeLast(),
      (d) => d['reports'][1] = d['reports'][0],
      (d) => d['reports'][0]['drawDate'] = '2026-02-30',
      (d) => d['reports'][0]['sourceUrl'] = 'https://example.com',
      (d) => d['reports'][0]['tiers'][0]['winners'] = -1,
      (d) => d['reports'][0]['numbers'][1] = d['reports'][0]['numbers'][0],
      (d) => d['reports'][0]['sourceUpdatedAt'] = '2026-10-10T23:15:17Z',
      (d) => d['reports'][0]['qualifications'] = [],
      (d) => report(d, 'Powerball')['tiers'][0]['powerPlayWinners'] = 0,
      (d) =>
          report(d, 'Powerball')['tiers'][1]['powerPlayWinnersLabel'] = '1.5',
      (d) => report(d, 'Powerball')['powerball'] = '27',
      (d) => report(d, 'Mega Millions')['sourceWarnings'] = [],
      (d) => report(d, 'Mega Millions')['tiers'][0]['multipliers'].removeLast(),
      (d) => report(
        d,
        'Mega Millions',
      )['tiers'][1]['multipliers'][0]['prizeLabel'] = r'$3M',
      (d) => report(d, 'Pick 3')['playTypes'][0]['statewideWinners'] = 1,
      (d) => report(d, 'Pick 3')['playTypes'][0]['statewideTotalCents'] = 1,
      (d) => report(d, 'Pick 3')['digits'][0] = 1,
      (d) =>
          report(d, 'Pick 4')['payoutSchedule'][2]['rows'][0]['rowSpans'][0] =
              1,
      (d) => report(d, 'Pick 4')['payoutSchedule'][3]['rows'][0]['cells'][4] =
          r'$500',
      (d) => report(d, 'Pick 5')['playTypes'][0]['statewideWinners'] = null,
      (d) => report(d, 'Pick 5')['payoutSchedule'][3]['rows'].removeLast(),
      (d) => d['reports'].firstWhere(
        (r) =>
            (r['sourceUpdatedAt'] as String)
                .substring(0, 10)
                .compareTo(r['drawDate']) <
            0,
      )['sourceWarnings'] = [],
    ];
    for (var i = 0; i < changes.length; i++) {
      final d = data();
      changes[i](d);
      expect(
        () => LouisianaDrawReportsValidator.decode(jsonEncode(d)),
        throwsA(anything),
        reason: 'mutation $i',
      );
    }
  });
  test(
    'retrieval, family windows and matching report timestamps cannot regress',
    () {
      for (final change in <void Function(Map)>[
        (d) => d['updatedAt'] = '2026-01-01T00:00:00Z',
        (d) => d['reports'][0]['drawDate'] = '2026-01-01',
        (d) => d['reports'][0]['sourceUpdatedAt'] = '2026-01-01T00:00:00Z',
      ]) {
        final next = data();
        change(next);
        expect(
          () => LouisianaDrawReportsValidator.continuity(data(), next),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'network or invalid response preserves existing cache without writing',
    () async {
      for (final fetch in <Future<String> Function()>[
        () async => '{}',
        () async => throw const SocketException('offline'),
      ]) {
        final result = await LouisianaDrawReportsLoader(
          readCache: () async => raw,
          fetchRemote: fetch,
          writeCache: (_) async => fail('must retain cache'),
          readBundle: () async => fail('cache valid'),
        ).load();
        expect(result, data());
      }
    },
  );
  test(
    'cold bundled data protects continuity and bad cache recovers',
    () async {
      final old = data();
      old['updatedAt'] = DateTime.parse(
        old['updatedAt'],
      ).subtract(const Duration(seconds: 1)).toIso8601String();
      final result = await LouisianaDrawReportsLoader(
        readCache: () async => '{}',
        readBundle: () async => raw,
        fetchRemote: () async => jsonEncode(old),
        writeCache: (_) async => fail('must not replace'),
      ).load();
      expect(result, data());
    },
  );
  test('valid newer response survives failed persistence', () async {
    final next = data();
    next['updatedAt'] = DateTime.parse(
      next['updatedAt'],
    ).add(const Duration(seconds: 1)).toIso8601String();
    final result = await LouisianaDrawReportsLoader(
      readCache: () async => raw,
      fetchRemote: () async => jsonEncode(next),
      writeCache: (_) async => throw StateError('storage'),
    ).load();
    expect(result, next);
  });
}
