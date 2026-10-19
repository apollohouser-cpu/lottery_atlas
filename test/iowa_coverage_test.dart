import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/iowa_coverage_validator.dart';
import '../lib/services/iowa_coverage_loader.dart';

void main() {
  final raw = File('data/iowa_coverage.generated.json').readAsStringSync();
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
