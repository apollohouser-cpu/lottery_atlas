import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/kansas_scratch_catalog_loader.dart';

void main() {
  String raw() =>
      File('data/kansas_scratch_catalog.generated.json').readAsStringSync();
  test('combined feed caches only Kansas despite storage failure', () async {
    final combined = jsonDecode(raw());
    combined['catalogs'].add({'state': 'Other', 'games': []});
    String? attempted;
    final loaded = await KansasScratchCatalogLoader(
      readCache: () async => raw(),
      fetchRemote: () async => jsonEncode(combined),
      writeCache: (value) async {
        attempted = value;
        throw StateError('storage unavailable');
      },
    ).load();
    expect(jsonDecode(attempted!)['catalogs'].length, 1);
    expect(loaded['catalogs'].length, 1);
    expect(loaded['catalogs'][0]['state'], 'Kansas');
  });
  test('literal tiers and unknown source date survive decode', () {
    final decoded = KansasScratchCatalogLoader.decode(raw());
    expect(
      decoded['catalogs'][0]['games'],
      jsonDecode(raw())['catalogs'][0]['games'],
    );
    expect(decoded['catalogs'][0]['sourceDate'], isNull);
  });
  test('malformed tiers, dates and source identity reject', () {
    for (final change in <void Function(Map)>[
      (r) => r['catalogs'][0]['sourceDate'] = '2026-10-15',
      (r) => r['catalogs'][0]['games'][0]['startDate'] = '2026-08-24',
      (r) => r['catalogs'][0]['games'][0]['sourceUrl'] = 'https://example.com',
      (r) =>
          r['catalogs'][0]['games'][0]['inventoryNote'] = 'Current inventory',
      (r) => r['catalogs'][0]['games'][0]['prizeTiers'][0]['remaining'] = -1,
      (r) => r['catalogs'][0]['games'][0]['prizeTiers'][0]['prizeAmount'] = 1,
      (r) =>
          r['catalogs'][0]['games'][0]['prizeTiers'].last['prizeAmount'] = 10,
      (r) => r['catalogs'][0]['games'][0]['topPrizesRemaining'] = 999,
      (r) => r['catalogs'][0]['games'].clear(),
    ]) {
      final r = jsonDecode(raw());
      change(r);
      expect(
        () => KansasScratchCatalogLoader.decode(jsonEncode(r)),
        throwsFormatException,
      );
    }
  });
  test('failure retains cache or cold bundle without writes', () async {
    for (final cached in [true, false]) {
      var writes = 0;
      final loaded = await KansasScratchCatalogLoader(
        readCache: () async => cached ? raw() : null,
        readBundle: () async => raw(),
        fetchRemote: () async => throw const SocketException('offline'),
        writeCache: (_) async {
          writes++;
        },
      ).load();
      expect(loaded, KansasScratchCatalogLoader.decode(raw()));
      expect(writes, 0);
    }
  });
  test(
    'continuity rejects identity loss but permits changed remaining counts',
    () {
      final before = KansasScratchCatalogLoader.decode(raw());
      final changed = KansasScratchCatalogLoader.decode(raw());
      changed['catalogs'][0]['games'][0]['prizeTiers'][1]['remaining'] += 1;
      KansasScratchCatalogLoader.continuity(before, changed);
      changed['catalogs'][0]['games'][0]['sourceLaunchDisplayed'] =
          '2026-08-22';
      expect(
        () => KansasScratchCatalogLoader.continuity(before, changed),
        throwsFormatException,
      );
    },
  );
}
