import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/new_york_prize_tables_loader.dart';

void main() {
  final raw = File(
    'data/new_york_draw_reports.generated.json',
  ).readAsStringSync();
  test(
    'remote preserves all units, dates and literal prizes despite disk failure',
    () async {
      final data = await NewYorkPrizeTablesLoader(
        readCache: () async => null,
        fetchRemote: () async => raw,
        writeCache: (_) async => throw StateError('disk full'),
        readBundle: () async => throw StateError('unexpected fallback'),
      ).load();
      expect(data, jsonDecode(raw));
    },
  );
  test('offline preserves cached data exactly', () async {
    final data = await NewYorkPrizeTablesLoader(
      readCache: () async => raw,
      fetchRemote: () async => throw StateError('offline'),
    ).load();
    expect(data, jsonDecode(raw));
  });
  test('corrupt cache falls back to bundle without inventing dates', () async {
    final data = await NewYorkPrizeTablesLoader(
      readCache: () async => '{}',
      fetchRemote: () async => throw StateError('offline'),
      readBundle: () async => raw,
    ).load();
    expect(data, jsonDecode(raw));
  });
  test(
    'wrong scope, inferred counts and incomplete tables cannot overwrite cache',
    () async {
      for (final mutate in <void Function(dynamic)>[
        (d) => d['reports'][0]['jurisdiction'] = 'National',
        (d) => d['reports'].firstWhere(
          (r) => r['gameName'] == 'NUMBERS',
        )['tables'][0]['tiers'][0]['reportedWinners'] = 1,
        (d) => d['reports'].firstWhere(
          (r) => r['gameName'] == 'Quick Draw / Money Dots',
        )['tables'][0]['reportedWinners'] = 0,
        (d) => d['reports'][0]['tables'].removeLast(),
        (d) => d['reports'].add(d['reports'][0]),
        (d) => d['reports'][0]['drawDate'] = '2026-02-31',
      ]) {
        final invalid = jsonDecode(raw);
        mutate(invalid);
        var wrote = false;
        final data = await NewYorkPrizeTablesLoader(
          readCache: () async => raw,
          fetchRemote: () async => jsonEncode(invalid),
          writeCache: (_) async {
            wrote = true;
          },
        ).load();
        expect(wrote, isFalse);
        expect(data, jsonDecode(raw));
      }
    },
  );
}
