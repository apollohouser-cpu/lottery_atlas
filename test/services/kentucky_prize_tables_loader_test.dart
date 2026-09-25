import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/kentucky_prize_tables_loader.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final raw = File(
    'data/kentucky_draw_tiers.generated.json',
  ).readAsStringSync();
  final fixture = jsonDecode(raw) as Map<String, dynamic>;
  Future<String> offline() async => throw const SocketException('offline');

  test('offline first launch uses bundle without changing any dates', () async {
    final result = await KentuckyPrizeTablesLoader(
      readCache: () async => null,
      fetchRemote: offline,
      readBundle: () async => raw,
    ).load();
    expect(result, fixture);
  });
  test('offline and malformed remote preserve validated cache', () async {
    for (final remote in [offline, () async => '{bad json']) {
      final result = await KentuckyPrizeTablesLoader(
        readCache: () async => raw,
        fetchRemote: remote,
        readBundle: () async => throw StateError('cache must win'),
      ).load();
      expect(result, fixture);
    }
  });
  test(
    'untrusted source and malformed columns cannot become cached data',
    () async {
      for (final invalidSource in [true, false]) {
        var writes = 0;
        final invalid = jsonDecode(raw);
        if (invalidSource) {
          invalid['reports'][0]['sourceUrl'] = 'https://example.com/report';
        } else {
          invalid['reports'][0]['tiers'][0].removeLast();
        }
        final result = await KentuckyPrizeTablesLoader(
          readCache: () async => jsonEncode(invalid),
          fetchRemote: () async => jsonEncode(invalid),
          writeCache: (_) async {
            writes++;
          },
          readBundle: () async => raw,
        ).load();
        expect(result, fixture);
        expect(writes, 0);
      }
    },
  );
  test(
    'reconnection caches exact response and preserves original dates',
    () async {
      String? saved;
      final loader = KentuckyPrizeTablesLoader(
        readCache: () async => null,
        fetchRemote: () async => raw,
        writeCache: (value) async {
          saved = value;
        },
        readBundle: () async => throw StateError('remote must win'),
      );
      expect(await loader.load(), fixture);
      expect(saved, raw);
      expect(
        await KentuckyPrizeTablesLoader(
          readCache: () async => saved,
          fetchRemote: offline,
          readBundle: () async => throw StateError('cache must win'),
        ).load(),
        fixture,
      );
    },
  );
  test('cache write failure still returns valid remote report', () async {
    final result = await KentuckyPrizeTablesLoader(
      readCache: () async => null,
      fetchRemote: () async => raw,
      writeCache: (_) async => throw StateError('disk full'),
      readBundle: () async => throw StateError('remote must win'),
    ).load();
    expect(result, fixture);
  });
}
