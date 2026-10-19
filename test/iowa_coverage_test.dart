import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/iowa_coverage_validator.dart';
import '../lib/services/iowa_coverage_loader.dart';

void main() {
  final raw = File('data/iowa_coverage.generated.json').readAsStringSync();
  test(
    'reviewed legacy UTF-8 names migrate without accepting count corrections',
    () {
      final old = jsonDecode(raw);
      final inventories = old['instantInventories']['inventories'] as List;
      for (final subset in inventories) {
        for (final game in subset['games']) {
          game['name'] = (game['name'] as String).replaceAll('™', 'â\u0084¢');
        }
      }
      for (final game in old['scratchCatalog']['games']) {
        game['name'] = (game['name'] as String).replaceAll('™', 'â\u0084¢');
      }
      final migrated = IowaCoverageValidator.decode(jsonEncode(old));
      final corrected = IowaCoverageValidator.decode(raw);
      expect(jsonEncode(migrated), jsonEncode(corrected));
      IowaCoverageValidator.continuity(migrated, corrected);
      final changed = jsonDecode(raw);
      changed['instantInventories']['inventories'][1]['games'][0]['prizeTiers'][0]['claimed'] +=
          1;
      expect(
        () => IowaCoverageValidator.continuity(
          migrated,
          IowaCoverageValidator.decode(jsonEncode(changed)),
        ),
        throwsFormatException,
      );
    },
  );
  dynamic nextInventory() {
    final data = jsonDecode(raw);
    data['instantInventories']['sourceDate'] = '2026-10-18';
    data['scratchCatalog']['sourceDate'] = '2026-10-18';
    for (final game in data['scratchCatalog']['games']) {
      game['inventoryNote'] = (game['inventoryNote'] as String).replaceFirst(
        '2026-10-17',
        '2026-10-18',
      );
    }
    return data;
  }

  test('dated typed inventory advances and retains product boundaries', () {
    final old = IowaCoverageValidator.decode(raw), data = nextInventory();
    final tier =
        data['instantInventories']['inventories'][1]['games'][0]['prizeTiers'][0];
    tier['claimed'] += 1;
    tier['unclaimed'] -= 1;
    final parsed = IowaCoverageValidator.decode(jsonEncode(data));
    IowaCoverageValidator.continuity(old, parsed);
    expect(
      parsed['instantInventories']['inventories'][1]['productType'],
      'InstaPlay',
    );
  });
  test(
    'inventory schema counts duplicate identities and unsafe sources reject',
    () {
      for (final change in [
        (dynamic d) =>
            d['instantInventories']['inventories'][1]['games'][0]['prizeTiers'][0]['claimed'] =
                -1,
        (dynamic d) =>
            d['instantInventories']['inventories'][1]['productType'] =
                'Scratch',
        (dynamic d) => d['instantInventories']['inventories'][1]['games'].add(
          d['instantInventories']['inventories'][1]['games'][0],
        ),
        (dynamic d) => d['scratchCatalog']['games'][0]['sourceUrl'] =
            'https://example.com',
        (dynamic d) => d['scratchCatalog']['games'][0]['topPrize'] = 1,
      ]) {
        final data = nextInventory();
        change(data);
        expect(
          () => IowaCoverageValidator.decode(jsonEncode(data)),
          throwsA(anything),
        );
      }
    },
  );
  test('same-date changes and reversed cumulative counts fail continuity', () {
    final old = IowaCoverageValidator.decode(raw);
    for (final sameDate in [true, false]) {
      final data = sameDate ? jsonDecode(raw) : nextInventory();
      data['instantInventories']['inventories'][1]['games'][0]['prizeTiers'][0]['claimed'] -=
          1;
      final parsed = IowaCoverageValidator.decode(jsonEncode(data));
      expect(
        () => IowaCoverageValidator.continuity(old, parsed),
        throwsA(anything),
      );
    }
  });
  test('complete coupled baseline validates', () {
    final data = IowaCoverageValidator.decode(raw);
    expect(data['draws']['results'].length, 20);
    expect(data['instantInventories']['inventories'].length, 3);
  });
  test(
    'wrong dates, variant multipliers, counts and source changes reject',
    () {
      for (final change in [
        (dynamic d) => d['draws']['results'][0]['numbers'][0] = 99,
        (dynamic d) =>
            d['draws']['results'][0]['report']['group'] = 'double_play',
        (dynamic d) =>
            d['draws']['results'][0]['report']['tiers'][0]['sourceWinners'] =
                -1,
        (dynamic d) =>
            d['draws']['results'][0]['report']['advertisedJackpotDollars'] = 0,
        (dynamic d) => d['draws']['results'][0]['drawDate'] = '2026-02-30',
        (dynamic d) => d['draws']['results'][2]['multiplier'] = 2,
        (dynamic d) => d['instantInventories']['sourceDate'] = '2026-10-18',
      ]) {
        final data = jsonDecode(raw);
        change(data);
        expect(
          () => IowaCoverageValidator.decode(jsonEncode(data)),
          throwsA(anything),
        );
      }
    },
  );
  test(
    'request failure and malformed remote retain valid cache without writes',
    () async {
      for (final malformed in [false, true]) {
        var writes = 0;
        final loader = IowaCoverageLoader(
          readCache: () async => raw,
          writeCache: (_) async {
            writes++;
          },
          fetchRemote: () async {
            if (malformed) return '{}';
            throw const SocketException('controlled');
          },
        );
        expect(await loader.load(), jsonDecode(raw));
        expect(writes, 0);
      }
    },
  );
  test(
    'newer retrieval adopts and persists unchanged verified contents',
    () async {
      final data = jsonDecode(raw);
      data['retrievedAt'] = '2026-10-19T13:00:00+00:00';
      data['draws']['retrievedAt'] = data['retrievedAt'];
      final newer = jsonEncode(data);
      String? saved;
      final loader = IowaCoverageLoader(
        readCache: () async => raw,
        writeCache: (s) async {
          saved = s;
        },
        fetchRemote: () async => newer,
      );
      expect((await loader.load())['retrievedAt'], data['retrievedAt']);
      expect(saved, newer);
    },
  );
}
