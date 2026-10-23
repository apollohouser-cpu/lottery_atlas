import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/idaho_coverage_loader.dart';
import 'package:lottery_atlas/services/idaho_coverage_validator.dart';

void main() {
  final raw = File('data/idaho_coverage.generated.json').readAsStringSync();
  test('audited typed baseline preserves unknown inventory', () {
    final data = IdahoCoverageValidator.decode(raw);
    expect(data['results'].length, 22);
    expect(
      data['scratch']['unavailableInventoryGames'].single['remainingPrizes'],
      isNull,
    );
  });
  test('changed counts, unknowns and missing components fail closed', () {
    for (final change in <void Function(dynamic)>[
      (d) => d['results'][0]['numbers'][0] = '99',
      (d) =>
          d['scratch']['unavailableInventoryGames'][0]['remainingPrizes'] = 0,
      (d) => d['instantCatalogs'].remove('tabs'),
      (d) => d['sourceEvidence'][0]['url'] = 'https://example.com/source',
    ]) {
      final data = jsonDecode(raw);
      change(data);
      expect(
        () => IdahoCoverageValidator.decode(jsonEncode(data)),
        throwsFormatException,
      );
    }
  });
  test('failed remote retains real cache without write', () async {
    var writes = 0;
    final data = await IdahoCoverageLoader(
      readCache: () async => raw,
      writeCache: (_) async {
        writes++;
      },
      fetchRemote: () async => throw const SocketException('controlled'),
      readBundle: () async => throw StateError('cache expected'),
    ).load();
    expect(data['collectionStartedAt'], jsonDecode(raw)['collectionStartedAt']);
    expect(writes, 0);
  });
  test(
    'invalid cache uses bundle and invalid remote never overwrites',
    () async {
      var writes = 0;
      final data = await IdahoCoverageLoader(
        readCache: () async => '{}',
        writeCache: (_) async {
          writes++;
        },
        fetchRemote: () async => '{}',
        readBundle: () async => raw,
      ).load();
      expect(data['state'], 'Idaho');
      expect(writes, 0);
    },
  );
  test('valid remote survives persistence error', () async {
    final data = await IdahoCoverageLoader(
      readCache: () async => null,
      writeCache: (_) async => throw const FileSystemException('controlled'),
      fetchRemote: () async => raw,
      readBundle: () async => raw,
    ).load();
    expect(data['results'].length, 22);
  });
  test(
    'numeric Scratch decreases adopt without inventing verification date',
    () async {
      final candidate = jsonDecode(raw);
      candidate['scratch']['games'][0]['topPrizesRemaining'] = 1;
      candidate['scratch']['games'][0]['prizeTiers'][0]['remaining'] = 1;
      String? saved;
      final result = await IdahoCoverageLoader(
        readCache: () async => raw,
        writeCache: (value) async {
          saved = value;
        },
        fetchRemote: () async => jsonEncode(candidate),
        readBundle: () async => raw,
      ).load();
      expect(result['scratch']['games'][0]['topPrizesRemaining'], 1);
      expect(result['scratch']['games'][0]['sourceDate'], isNull);
      expect(saved, jsonEncode(candidate));
    },
  );
  test('Scratch structural and count mutations fail closed', () {
    for (final change in <void Function(dynamic)>[
      (d) => d['scratch']['games'][0]['prizeTiers'][1]['remaining'] = -1,
      (d) => d['scratch']['games'][0]['prizeTiers'][1]['remaining'] = 6,
      (d) => d['scratch']['games'][0]['prizeTiers'][1]['remaining'] = 1.5,
      (d) => d['scratch']['games'][0]['prizeTiers'][1]['original'] = 6,
      (d) => d['scratch']['games'][0]['topPrizesRemaining'] = 1,
      (d) => d['scratch']['games'].removeLast(),
      (d) => d['scratch']['games'][0]['sourceDate'] = '2026-10-23',
    ]) {
      final candidate = jsonDecode(raw);
      change(candidate);
      expect(
        () => IdahoCoverageValidator.decode(jsonEncode(candidate)),
        throwsFormatException,
      );
    }
  });
  test(
    'remote cannot increase counts relative to newer retained cache',
    () async {
      final cached = jsonDecode(raw);
      cached['scratch']['games'][0]['prizeTiers'][1]['remaining'] = 3;
      var writes = 0;
      final result = await IdahoCoverageLoader(
        readCache: () async => jsonEncode(cached),
        writeCache: (_) async {
          writes++;
        },
        fetchRemote: () async => raw,
        readBundle: () async => raw,
      ).load();
      expect(result['scratch']['games'][0]['prizeTiers'][1]['remaining'], 3);
      expect(writes, 0);
    },
  );
}
