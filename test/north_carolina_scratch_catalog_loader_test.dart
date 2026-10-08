import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/north_carolina_scratch_catalog_loader.dart';

void main() {
  final raw = File(
    'data/north_carolina_scratch_catalog.generated.json',
  ).readAsStringSync();
  test('offline bundle retains every literal tier and source date', () async {
    final d = await NorthCarolinaScratchCatalogLoader(
      readCache: () async => null,
      fetchRemote: () async => throw Exception('offline'),
      readBundle: () async => raw,
    ).load();
    expect(d['sourceDate'], '2026-10-07');
    expect((d['games'] as List).length, 83);
    expect(
      (d['games'] as List).fold<int>(
        0,
        (n, g) => n + (g['tiers'] as List).length,
      ),
      896,
    );
    expect(d['sourceDefinition'], contains('Reordered'));
  });
  test(
    'malformed remote and regressions preserve full cached snapshot',
    () async {
      for (final defect in [
        'count',
        'duplicate',
        'url',
        'date',
        'retrieval',
        'identity',
        'drop',
        'tier',
        'odds',
        'future',
        'price',
      ]) {
        final d = jsonDecode(raw);
        final game = d['games'][0];
        switch (defect) {
          case 'count':
            game['tiers'][0]['remainingPrizes'] = -1;
            break;
          case 'duplicate':
            d['games'][1] = game;
            break;
          case 'url':
            game['sourceUrl'] = 'https://example.com/';
            break;
          case 'date':
            d['sourceDate'] = '2026-02-30';
            break;
          case 'retrieval':
            d['updatedAt'] = '2020-01-01T00:00:00Z';
            break;
          case 'identity':
            game['name'] = 'Changed';
            break;
          case 'drop':
            d['games'] = (d['games'] as List).take(55).toList();
            break;
          case 'tier':
            game['tiers'].removeLast();
            break;
          case 'odds':
            game['tiers'][0]['oddsLabel'] = '1,,000';
            break;
          case 'future':
            d['sourceDate'] = '2099-01-01';
            break;
          case 'price':
            game['ticketPrice'] = 0;
            break;
        }
        var wrote = false;
        final result = await NorthCarolinaScratchCatalogLoader(
          readCache: () async => raw,
          fetchRemote: () async => jsonEncode(d),
          writeCache: (_) async {
            wrote = true;
          },
        ).load();
        expect(result, jsonDecode(raw), reason: defect);
        expect(wrote, false, reason: defect);
      }
    },
  );
  test(
    'cold cache uses bundle identity baseline and accepts literal reorders',
    () async {
      final d = jsonDecode(raw);
      d['games'][0]['name'] = 'Changed';
      var writes = 0;
      Future<Map<String, dynamic>> load() => NorthCarolinaScratchCatalogLoader(
        readCache: () async => null,
        readBundle: () async => raw,
        fetchRemote: () async => jsonEncode(d),
        writeCache: (_) async {
          writes++;
        },
      ).load();
      expect(await load(), jsonDecode(raw));
      expect(writes, 0);
      d['games'][0]['name'] = jsonDecode(raw)['games'][0]['name'];
      final tier = d['games'][0]['tiers'][0];
      tier['totalPrizes'] += 10;
      tier['remainingPrizes'] += 10;
      expect(await load(), d);
      expect(writes, 1);
    },
  );
  test(
    'valid remote survives persistence failure; corrupt fallback fails',
    () async {
      final d = await NorthCarolinaScratchCatalogLoader(
        readCache: () async => null,
        readBundle: () async => raw,
        fetchRemote: () async => raw,
        writeCache: (_) async => throw Exception('disk'),
      ).load();
      expect(d, jsonDecode(raw));
      final bad = jsonDecode(raw);
      bad['games'][0]['tiers'] = [];
      await expectLater(
        NorthCarolinaScratchCatalogLoader(
          readCache: () async => null,
          fetchRemote: () async => throw Exception('offline'),
          readBundle: () async => jsonEncode(bad),
        ).load(),
        throwsFormatException,
      );
    },
  );
}
