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
}
