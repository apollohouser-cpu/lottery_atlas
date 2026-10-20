import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/iowa_coverage_validator.dart';
import '../lib/services/iowa_coverage_loader.dart';

void main() {
  final raw = File('data/iowa_coverage.generated.json').readAsStringSync();
  test('reviewed source corrections allow only exact forward rows', () {
    final changes = jsonDecode(
      File('tooling/iowa_reviewed_corrections.json').readAsStringSync(),
    );
    for (final change in changes) {
      final oldRaw = jsonDecode(raw);
      final rows = oldRaw['draws']['results'] as List;
      final i = rows.indexWhere(
        (r) =>
            r['group'] == change['group'] &&
            r['drawDate'] == change['drawDate'],
      );
      rows[i] = change['before'];
      final nextRaw = jsonDecode(jsonEncode(oldRaw));
      nextRaw['draws']['results'][i] = change['after'];
      final old = IowaCoverageValidator.decode(jsonEncode(oldRaw));
      final next = IowaCoverageValidator.decode(jsonEncode(nextRaw));
      IowaCoverageValidator.continuity(old, next);
      expect(
        () => IowaCoverageValidator.continuity(next, old),
        throwsFormatException,
      );
      final bad = jsonDecode(jsonEncode(nextRaw));
      final row = bad['draws']['results'][i];
      if (row['report'] != null) {
        row['report']['tiers'][0]['sourceWinners'] += 1;
      } else {
        row['numbers'][0] = 9;
      }
      expect(
        () => IowaCoverageValidator.continuity(
          old,
          IowaCoverageValidator.decode(jsonEncode(bad)),
        ),
        throwsFormatException,
      );
    }
  });
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
    final previousDate = data['instantInventories']['sourceDate'] as String;
    final nextDate = DateTime.parse(
      previousDate,
    ).add(const Duration(days: 1)).toIso8601String().substring(0, 10);
    data['instantInventories']['sourceDate'] = nextDate;
    data['scratchCatalog']['sourceDate'] = nextDate;
    for (final game in data['scratchCatalog']['games']) {
      game['inventoryNote'] = (game['inventoryNote'] as String).replaceFirst(
        previousDate,
        nextDate,
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
        (dynamic d) => d['instantInventories']['sourceDate'] = '2100-01-01',
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
      data['retrievedAt'] = DateTime.parse(
        data['retrievedAt'],
      ).add(const Duration(seconds: 1)).toIso8601String();
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
