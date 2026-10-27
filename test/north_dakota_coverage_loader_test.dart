import 'dart:convert';
import 'package:lottery_atlas/services/north_dakota_coverage_contract.dart';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/north_dakota_coverage_loader.dart';
import 'package:lottery_atlas/services/north_dakota_coverage_validator.dart';

void main() {
  const raw = northDakotaCoverageContractJson;
  test('latest published snapshot advances from bundled baseline', () {
    final live = NorthDakotaCoverageValidator.decode(
      File('data/north_dakota_coverage.generated.json').readAsStringSync(),
    );
    expect(live['results'].length, 10);
  });
  Map<String, dynamic> data() => jsonDecode(raw);
  test('baseline has all groups and unavailable reports', () {
    final d = NorthDakotaCoverageValidator.decode(raw);
    expect(d['results'].length, 10);
  });
  test('rejects number, identity, date, rule and provenance mutations', () {
    final mutations = <void Function(Map<String, dynamic>)>[
      (d) => d['results'][0]['numbers'][0] = 99,
      (d) => d['results'][0]['drawId'] = true,
      (d) => d['results'][0]['drawDate'] = '2026-10-25',
      (d) => d['results'][0]['drawDate'] = '2026-02-30',
      (d) => d['results'][0]['drawDate'] = '2026-10-28',
      (d) => d['results'][0]['multiplier'] = true,
      (d) => d['results'][2]['multiplier'] = 3,
      (d) => d['results'][6]['multiplier'] = 10,
      (d) => d['results'][8]['numberLabels'] = ['White', 'Red'],
      (d) => d['results'][0]['bonusNumbers'] = [27],
      (d) => d['results'][0]['reportStatus'] = 'available',
      (d) => d['results'][0]['sourceRetrievedAt'] = d['updatedAt'],
      (d) => d['results'].removeLast(),
      (d) => d['rules'][0]['document']['children'].clear(),
      (d) => d['sources'][3]['url'] = 'https://example.com/',
      (d) => d['sources'][0]['sha256'] = 'bad',
      (d) => d['catalog']['retired'].clear(),
      (d) => d['customerId'] = 'private',
    ];
    for (final mutate in mutations) {
      final d = data();
      mutate(d);
      expect(
        () => NorthDakotaCoverageValidator.decode(jsonEncode(d)),
        throwsA(anything),
      );
    }
  });
  test('failure retains validated cache without writing', () async {
    var writes = 0;
    final loader = NorthDakotaCoverageLoader(
      readCache: () async => raw,
      readBundle: () async => throw StateError('unused'),
      fetchRemote: () async => throw const SocketException('controlled'),
      writeCache: (_) async {
        writes++;
      },
    );
    expect((await loader.load())['updatedAt'], data()['updatedAt']);
    expect(writes, 0);
  });
  test(
    'corrupt cache falls back to bundle and rejects corrupt remote',
    () async {
      final loader = NorthDakotaCoverageLoader(
        readCache: () async => '{}',
        readBundle: () async => raw,
        fetchRemote: () async => '{}',
        writeCache: (_) async => fail('invalid write'),
      );
      expect((await loader.load())['results'].length, 10);
    },
  );
  test('valid remote survives persistence failure', () async {
    final loader = NorthDakotaCoverageLoader(
      readCache: () async => null,
      readBundle: () async => raw,
      fetchRemote: () async => raw,
      writeCache: (_) async => throw FileSystemException('controlled'),
    );
    expect((await loader.load())['results'].length, 10);
  });
  test('all five date-only windows advance from older retained dates', () {
    final prior = data();
    for (final r in prior['results']) {
      r['drawDate'] = DateTime.parse(
        r['drawDate'],
      ).subtract(const Duration(days: 7)).toIso8601String().substring(0, 10);
    }
    NorthDakotaCoverageValidator.continuity(prior, data());
    final changed = data();
    changed['results'][0]['numbers'] =
        (changed['results'][0]['numbers'] as List).reversed.toList();
    expect(
      () => NorthDakotaCoverageValidator.continuity(data(), changed),
      throwsFormatException,
    );
  });
  test('retained dates cannot disappear inside advanced window', () {
    final prior = data();
    prior['results'][1]['drawDate'] = '2026-10-21';
    NorthDakotaCoverageValidator.continuity(prior, data());
    final next = data();
    next['results'][0]['drawDate'] = '2026-10-24';
    next['results'][1]['drawDate'] = '2026-10-21';
    expect(
      () => NorthDakotaCoverageValidator.continuity(data(), next),
      throwsFormatException,
    );
  });
  test(
    'newer remote persists exact bytes, older remote retains newer cache',
    () async {
      final newer = data();
      String advance(String s) =>
          DateTime.parse(s).add(const Duration(seconds: 1)).toIso8601String();
      newer['updatedAt'] = advance(newer['updatedAt']);
      for (final s in newer['sources']) {
        s['retrievedAt'] = advance(s['retrievedAt']);
      }
      newer['catalog']['retrievedAt'] = newer['sources'][0]['retrievedAt'];
      for (var i = 0; i < 5; i++) {
        newer['rules'][i]['retrievedAt'] =
            newer['sources'][2 * i + 2]['retrievedAt'];
        for (var j = 0; j < 2; j++) {
          newer['results'][2 * i + j]['sourceRetrievedAt'] =
              newer['sources'][2 * i + 1]['retrievedAt'];
        }
      }
      final bytes = jsonEncode(newer);
      String? written;
      final loader = NorthDakotaCoverageLoader(
        readCache: () async => raw,
        fetchRemote: () async => bytes,
        writeCache: (v) async {
          written = v;
        },
      );
      expect((await loader.load())['updatedAt'], newer['updatedAt']);
      expect(written, bytes);
      final older = NorthDakotaCoverageLoader(
        readCache: () async => bytes,
        fetchRemote: () async => raw,
        writeCache: (_) async => fail('regressed write'),
      );
      expect((await older.load())['updatedAt'], newer['updatedAt']);
    },
  );
}
