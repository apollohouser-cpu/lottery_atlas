import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/louisiana_scratch_catalog_loader.dart';

void main() {
  final raw = File(
    'data/louisiana_scratch_catalog.generated.json',
  ).readAsStringSync();
  Map<String, dynamic> data() => jsonDecode(raw);
  dynamic game(Map d) => d['catalogs'][0]['games'][0];
  test('retains every game, literal tier and source field', () {
    final d = LouisianaScratchCatalogLoader.decode(raw);
    expect(d, data());
    expect(d['catalogs'][0]['games'].length, 43);
    expect(game(d)['prizeTiers'].last['prizeLabel'], 'TICKET');
    expect(game(d)['prizeTiers'].last.containsKey('prizeAmount'), false);
  });
  test('rejects malformed inventory, identity, source and literal units', () {
    final mutations = <void Function(Map)>[
      (d) => d['catalogs'].add(d['catalogs'][0]),
      (d) => d['catalogs'][0]['games'] = [],
      (d) => d['catalogs'][0]['games'][1] = game(d),
      (d) => game(d)['sourceUrl'] = 'https://example.com/',
      (d) => game(d)['sourceUrl'] =
          'https://louisianalottery.com/game/9999-wrong/',
      (d) => game(d)['startDate'] = '2026-02-30',
      (d) => game(d)['sourceTimestamp'] = 'no date',
      (d) => game(d)['prizeTiers'][0]['remaining'] = -1,
      (d) => game(d)['prizeTiers'][0]['claimed'] = 0,
      (d) => game(d)['prizeTiers'][0]['prizeAmount'] = 1,
      (d) => game(d)['prizeTiers'].last['prizeAmount'] = 1,
      (d) => game(d)['prizeTiers'][0]['publishedOdds'] = '1 in NaN',
      (d) => game(d)['topPrizesRemaining'] = 99,
      (d) => d['catalogs'][0]['sourceDate'] = '2026-01-01',
    ];
    for (final mutate in mutations) {
      final d = data();
      mutate(d);
      expect(
        () => LouisianaScratchCatalogLoader.decode(jsonEncode(d)),
        throwsA(anything),
      );
    }
  });
  test(
    'rejects retrieval, discovery, per-game regressions and identity changes',
    () {
      for (final mutate in <void Function(Map)>[
        (d) => d['updatedAt'] = '2026-01-01T00:00:00Z',
        (d) => d['catalogs'][0]['reportTimestamp'] = '2026-01-01T00:00:00Z',
        (d) => game(d)['sourceTimestamp'] = '2026-01-01T00:00:00Z',
        (d) => game(d)['cost'] = 50,
        (d) => d['catalogs'][0]['games'].removeRange(0, 10),
      ]) {
        final d = data();
        mutate(d);
        expect(
          () => LouisianaScratchCatalogLoader.continuity(data(), d),
          throwsFormatException,
        );
      }
    },
  );
  test(
    'request and validation failure preserve cache or cold bundle',
    () async {
      for (final fetch in <Future<String> Function()>[
        () async => throw const SocketException('offline'),
        () async => '{}',
      ]) {
        for (final cache in [raw, null]) {
          final d = await LouisianaScratchCatalogLoader(
            readCache: () async => cache,
            readBundle: () async => raw,
            fetchRemote: fetch,
            writeCache: (_) async => fail('must not overwrite'),
          ).load();
          expect(d, data());
        }
      }
    },
  );
  test(
    'combined feed caches only Louisiana; persistence failure retains valid response',
    () async {
      final combined = data();
      combined['catalogs'].add({'state': 'Other'});
      String? stored;
      final loader = LouisianaScratchCatalogLoader(
        readCache: () async => raw,
        fetchRemote: () async => jsonEncode(combined),
        writeCache: (s) async => stored = s,
      );
      expect(await loader.load(), data());
      expect(jsonDecode(stored!), data());
      final failing = LouisianaScratchCatalogLoader(
        readCache: () async => raw,
        fetchRemote: () async => jsonEncode(combined),
        writeCache: (_) async => throw StateError('storage'),
      );
      expect(await failing.load(), data());
    },
  );
}
