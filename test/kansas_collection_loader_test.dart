import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/kansas_collection_loader.dart';
import 'package:lottery_atlas/services/kansas_collection_validator.dart';

void main() {
  String baseline() =>
      File('data/kansas_draw_collection.generated.json').readAsStringSync();
  test('full collection baseline and malformed advertised values', () {
    KansasCollectionValidator.decode(baseline());
    for (final change in <void Function(Map)>[
      (v) => v['advertisedPrizes'].removeLast(),
      (v) => v['advertisedPrizes'][0]['advertisedCashDollars'] = -1,
      (v) => v['advertisedPrizes'][0]['sourceDrawTimeHasPassed'] =
          !(v['advertisedPrizes'][0]['sourceDrawTimeHasPassed'] as bool),
      (v) => v['advertisedPrizes'][0]['sourceWarnings'] = [],
      (v) => v['advertisedPrizes'][0]['drawDate'] = '2026-10-01',
      (v) => v['coverage']['resultUnit'] = 'All winners',
    ]) {
      final v = jsonDecode(baseline());
      change(v);
      expect(
        () => KansasCollectionValidator.decode(jsonEncode(v)),
        throwsFormatException,
      );
    }
  });
  test('cache retained on request failure and malformed remote', () async {
    final raw = baseline();
    for (final malformed in [false, true]) {
      var writes = 0;
      final loaded = await KansasCollectionLoader(
        readCache: () async => raw,
        fetchRemote: () async {
          if (malformed) return '{}';
          throw const SocketException('offline');
        },
        writeCache: (_) async {
          writes++;
        },
      ).load();
      expect(loaded, jsonDecode(raw));
      expect(writes, 0);
    }
  });
  test(
    'cold bundle available and valid remote survives storage failure',
    () async {
      final raw = baseline();
      final offline = await KansasCollectionLoader(
        readCache: () async => null,
        readBundle: () async => raw,
        fetchRemote: () async => throw const SocketException('offline'),
      ).load();
      expect(offline, jsonDecode(raw));
      final loaded = await KansasCollectionLoader(
        readCache: () async => raw,
        fetchRemote: () async => raw,
        writeCache: (_) async => throw StateError('disk'),
      ).load();
      expect(loaded, jsonDecode(raw));
    },
  );
  test('retrieval and per-group continuity regression rejected', () {
    final old = KansasCollectionValidator.decode(baseline());
    for (final change in <void Function(Map)>[
      (v) => v['retrievedAt'] = '2020-01-01T00:00:00Z',
      (v) => v['reports'][0]['sourceDrawTimestamp'] = '2020-01-01T00:00:00Z',
      (v) => v['reports'][0]['sourceDrawTimestamp'] = '2030-01-01T00:00:00Z',
      (v) => v['advertisedPrizes'][0]['sourceDrawTimestamp'] =
          '2020-01-01T00:00:00Z',
    ]) {
      final v = jsonDecode(baseline()) as Map<String, dynamic>;
      change(v);
      expect(
        () => KansasCollectionValidator.continuity(old, v),
        throwsFormatException,
      );
    }
  });
}
