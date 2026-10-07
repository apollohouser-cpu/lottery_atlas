import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/missouri_scratch_catalog_loader.dart';

void main() {
  final raw = File(
    'data/missouri_scratch_catalog.generated.json',
  ).readAsStringSync();
  test(
    'bundle preserves literal inventory and unknown verification date',
    () async {
      final d = await MissouriScratchCatalogLoader(
        readCache: () async => null,
        fetchRemote: () async => throw Exception('offline'),
        readBundle: () async => raw,
      ).load();
      expect((d['games'] as List).length, 73);
      expect(d['sourceDate'], isNull);
      expect(d['games'][0]['advertisedTopPrize'], r'$2,000,000');
      expect(d['games'][0]['endDate'], '2026-08-06');
    },
  );
  test(
    'malformed inventory and identity changes retain cache without writing',
    () async {
      for (final defect in [
        'count',
        'amount',
        'duplicate',
        'url',
        'date',
        'regression',
        'identity',
        'drop',
      ]) {
        final d = jsonDecode(raw);
        switch (defect) {
          case 'count':
            d['games'][0]['prizeTiers'][0]['unclaimedPrizes'] = 999999999;
            break;
          case 'amount':
            d['games'][0]['prizeTiers'][0]['advertisedAmount'] = 21;
            break;
          case 'duplicate':
            d['games'][1] = d['games'][0];
            break;
          case 'url':
            d['games'][0]['sourceUrl'] = 'https://example.com/';
            break;
          case 'date':
            d['games'][0]['startDate'] = '2026-02-30';
            break;
          case 'regression':
            d['updatedAt'] = '2020-01-01T00:00:00Z';
            break;
          case 'identity':
            d['games'][0]['name'] = 'Changed identity';
            break;
          case 'drop':
            d['games'] = (d['games'] as List).take(55).toList();
            break;
        }
        var wrote = false;
        final result = await MissouriScratchCatalogLoader(
          readCache: () async => raw,
          fetchRemote: () async => jsonEncode(d),
          writeCache: (_) async {
            wrote = true;
          },
          readBundle: () async => throw Exception('cache required'),
        ).load();
        expect(result, jsonDecode(raw), reason: defect);
        expect(wrote, false, reason: defect);
      }
    },
  );
  test('valid remote survives cache persistence failure', () async {
    final d = await MissouriScratchCatalogLoader(
      readCache: () async => null,
      fetchRemote: () async => raw,
      writeCache: (_) async => throw Exception('disk'),
    ).load();
    expect(d['updatedAt'], jsonDecode(raw)['updatedAt']);
  });
  test('malformed bundle is not silently admitted', () async {
    final d = jsonDecode(raw);
    d['games'][0]['prizeTiers'] = [];
    await expectLater(
      MissouriScratchCatalogLoader(
        readCache: () async => null,
        fetchRemote: () async => throw Exception('offline'),
        readBundle: () async => jsonEncode(d),
      ).load(),
      throwsFormatException,
    );
  });
}
