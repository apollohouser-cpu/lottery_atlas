import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/colorado_draw_reports_loader.dart';

void main() {
  final raw = File(
    'data/colorado_draw_reports.generated.json',
  ).readAsStringSync();
  test(
    'remote preserves source units and literal prizes despite disk failure',
    () async {
      final data = await ColoradoDrawReportsLoader(
        readCache: () async => null,
        fetchRemote: () async => raw,
        writeCache: (_) async => throw StateError('disk full'),
        readBundle: () async => throw StateError('unexpected fallback'),
      ).load();
      expect(data, jsonDecode(raw));
    },
  );
  test('offline preserves cached data exactly', () async {
    final data = await ColoradoDrawReportsLoader(
      readCache: () async => raw,
      fetchRemote: () async => throw StateError('offline'),
    ).load();
    expect(data, jsonDecode(raw));
  });
  test('corrupt cache falls back to bundle without inventing dates', () async {
    final data = await ColoradoDrawReportsLoader(
      readCache: () async => '{}',
      fetchRemote: () async => throw StateError('offline'),
      readBundle: () async => raw,
    ).load();
    expect(data, jsonDecode(raw));
  });
  test(
    'wrong scope, invalid counts and incomplete tables cannot overwrite cache',
    () async {
      for (final mutate in <void Function(dynamic)>[
        (d) => d['state'] = 'New York',
        (d) => d['reports'][0]['tiers'][0]['reportedWinners'] = -1,
        (d) => d['reports'][0]['tiers'].removeLast(),
        (d) => d['reports'].removeWhere((r) => r['game'] == 'Cash 5'),
        (d) => d['reports'].removeWhere(
          (r) => r['game'] == 'Pick 3' && r['drawingSession'] == 'Midday',
        ),
        (d) => d['reports'].add(d['reports'][0]),
        (d) => d['reports'][0]['drawDate'] = '2026-02-31',
        (d) => d['reports'][0]['sourceUrl'] = 'https://example.com',
        (d) => d['reports'].forEach((r) {
          final old = r['drawDate'] as String;
          r['drawDate'] = '2025${old.substring(4)}';
          r['sourceUrl'] = (r['sourceUrl'] as String).replaceFirst(
            old,
            r['drawDate'],
          );
        }),
        (d) => d['reports'].firstWhere(
          (r) => r['game'] == 'Millionaire for Life',
        )['prizeNotes'] = [],
        (d) => d['reports'].firstWhere(
          (r) => r['game'] == 'Pick 3',
        )['tiers'][8]['reportedWinners'] = 0,
      ]) {
        final invalid = jsonDecode(raw);
        mutate(invalid);
        var wrote = false;
        final data = await ColoradoDrawReportsLoader(
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
