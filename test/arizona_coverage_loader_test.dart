import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/arizona_coverage_loader.dart';

void main() {
  final raw = File(
    'test/fixtures/arizona_coverage_candidate.json',
  ).readAsStringSync();
  test(
    'release loader rejects candidate refresh and retains released data',
    () async {
      final released = File(
        'data/arizona_coverage.generated.json',
      ).readAsStringSync();
      var writes = 0;
      final loader = ArizonaCoverageLoader(
        releaseOnly: true,
        readBundle: () async => released,
        readCache: () async => raw,
        writeCache: (_) async {
          writes++;
        },
        fetchRemote: () async => raw,
      );
      final result = await loader.load();
      expect(result.origin, 'bundle');
      expect(result.refreshFailed, isTrue);
      expect(result.data, jsonDecode(released));
      expect(writes, 0);
      expect(
        () => ArizonaCoverageLoader.decode('${released} '),
        throwsFormatException,
      );
    },
  );
  test('reviewed artifact accepts all nineteen groups', () {
    expect(ArizonaCoverageLoader.decode(raw)['drawGroups'].length, 19);
  });
  test('unreviewed changes to any component and private fields reject', () {
    for (final field in [
      'drawGroups',
      'drawProvenance',
      'products',
      'rules',
      'ruleDetails',
      'endingNotices',
      'limitations',
    ]) {
      final data = jsonDecode(raw) as Map<String, dynamic>;
      data[field] = {};
      expect(
        () => ArizonaCoverageLoader.decode(jsonEncode(data)),
        throwsFormatException,
      );
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    data['privateId'] = 'not allowed';
    expect(
      () => ArizonaCoverageLoader.decode(jsonEncode(data)),
      throwsFormatException,
    );
  });
  test(
    'failed refresh preserves retained bytes and observation dates',
    () async {
      var cache = raw;
      var writes = 0;
      final loader = ArizonaCoverageLoader(
        readBundle: () async => throw StateError('bundle unused'),
        readCache: () async => cache,
        writeCache: (value) async {
          writes++;
          cache = value;
        },
        fetchRemote: () async => '{}',
      );
      final result = await loader.load();
      expect(result.refreshFailed, isTrue);
      expect(result.origin, 'cache');
      expect(cache, raw);
      expect(writes, 0);
      expect(result.data['drawProvenance'], jsonDecode(raw)['drawProvenance']);
    },
  );
  test(
    'corrupt cache falls back to bundle; remote failure stays visible',
    () async {
      final result = await ArizonaCoverageLoader(
        readBundle: () async => raw,
        readCache: () async => 'corrupt',
        writeCache: (_) async => fail('must not write'),
        fetchRemote: () async => throw StateError('offline'),
      ).load();
      expect(result.origin, 'bundle');
      expect(result.refreshFailed, isTrue);
    },
  );
  test('valid remote survives cache write failure and reports it', () async {
    final result = await ArizonaCoverageLoader(
      readBundle: () async => raw,
      readCache: () async => null,
      writeCache: (_) async => throw StateError('full storage'),
      fetchRemote: () async => raw,
    ).load();
    expect(result.origin, 'remote');
    expect(result.refreshFailed, isFalse);
    expect(result.persistenceFailed, isTrue);
  });
  test('no validated fallback fails without manufacturing data', () async {
    expect(
      ArizonaCoverageLoader(
        readBundle: () async => '{}',
        readCache: () async => null,
        writeCache: (_) async => fail('must not write'),
        fetchRemote: () async => '{}',
      ).load(),
      throwsStateError,
    );
  });
}
