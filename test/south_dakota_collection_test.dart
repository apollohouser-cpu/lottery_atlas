import 'package:flutter/material.dart';
import '../lib/widgets/map/south_dakota_draw_collection_sheet.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/south_dakota_collection_validator.dart';
import '../lib/services/south_dakota_collection_loader.dart';

void main() {
  testWidgets(
    'every selection renders with enlarged text and explicit variants',
    (tester) async {
      final data =
          jsonDecode(
                File(
                  'data/south_dakota_draw_collection.generated.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      for (var i = 0; i < 14; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                textScaler: TextScaler.linear(2),
              ),
              child: Scaffold(
                body: SouthDakotaDrawCollectionSheet(
                  key: ValueKey(i),
                  reportsOverride: data,
                  initialIndex: i,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'selection $i');
        expect(find.text('South Dakota results and schedules'), findsOneWidget);
        if (data['results'][i]['game'] == 'Xs and Os') {
          expect(find.textContaining('Teams:'), findsOneWidget);
        }
      }
    },
  );

  final raw = File(
    'data/south_dakota_draw_collection.generated.json',
  ).readAsStringSync();
  test(
    'all fourteen reports/results validate without external zone initialization',
    () {
      expect(SouthDakotaCollectionValidator.decode(raw)['results'].length, 14);
    },
  );
  test('corrupt domains dates counts schedules and variants rejected', () {
    final mutations = <void Function(dynamic)>[
      (d) => d['results'][0]['primary'][0] = '99',
      (d) => d['results'][0]['drawDate'] = '2026-02-30',
      (d) => d['results'][0]['variant'] = 'Power Play',
      (d) => d['reports'][0]['tiers'][0]['sdWinners'] = -1,
      (d) => d['schedules'].removeLast(),
      (d) => d['results'][1]['multiplier'] = 2,
      (d) => d['reports'][4]['drawId'] = '999999',
    ];
    for (final mutate in mutations) {
      final d = jsonDecode(raw);
      mutate(d);
      expect(
        () => SouthDakotaCollectionValidator.decode(jsonEncode(d)),
        throwsA(anything),
      );
    }
  });
  test('changed overlapping counts rejected', () {
    final old = SouthDakotaCollectionValidator.decode(raw);
    final next = jsonDecode(raw) as Map<String, dynamic>;
    next['reports'][0]['tiers'][0]['sdWinners'] += 1;
    expect(
      () => SouthDakotaCollectionValidator.continuity(old, next),
      throwsFormatException,
    );
  });
  test('remote failure preserves cached bytes', () async {
    var writes = 0;
    final loader = SouthDakotaCollectionLoader(
      readCache: () async => raw,
      writeCache: (_) async {
        writes++;
      },
      fetchRemote: () async => throw const SocketException('test outage'),
      readBundle: () async => throw StateError('should use cache'),
    );
    expect((await loader.load())['results'].length, 14);
    expect(writes, 0);
  });
  test('newer valid remote survives persistence failure', () async {
    final next = jsonDecode(raw);
    next['retrievedAt'] = DateTime.parse(
      next['retrievedAt'],
    ).add(const Duration(minutes: 1)).toIso8601String();
    final loader = SouthDakotaCollectionLoader(
      readCache: () async => raw,
      writeCache: (_) async => throw StateError('disk'),
      fetchRemote: () async => jsonEncode(next),
    );
    expect((await loader.load())['retrievedAt'], next['retrievedAt']);
  });
}
