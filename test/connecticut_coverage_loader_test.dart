import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/connecticut_coverage_loader.dart';

void main() {
  test(
    'published loader accepts exact bundled release and rejects altered bytes',
    () {
      final raw = File(
        'data/connecticut_coverage.generated.json',
      ).readAsStringSync();
      final loader = ConnecticutCoverageLoader.published();
      final data = loader.decode(raw);
      expect(data['draws'], hasLength(12));
      expect(data['reports'], hasLength(9));
      expect(
        (data['scratchCatalog']['games'] as List).any((g) => g['id'] == '1725'),
        isFalse,
      );
      expect(() => loader.decode('$raw '), throwsFormatException);
    },
  );

  // Synthetic transport fixture only; no Connecticut source claims or release.
  final raw = jsonEncode({
    'schemaVersion': 1,
    'stateCode': 'CT',
    'productionReady': true,
    'recordType': 'supported-coverage',
    'observedDate': '2026-11-22',
  });
  ConnecticutCoverageLoader loader({
    String? bundle,
    String? cache,
    String? remote,
    String? digest,
    Future<void> Function(String)? write,
  }) => ConnecticutCoverageLoader(
    reviewedSha256: digest ?? sha256.convert(utf8.encode(raw)).toString(),
    readBundle: () async => bundle ?? raw,
    readCache: () async => cache,
    fetchRemote: () async => remote ?? (throw StateError('offline')),
    writeCache: write ?? (_) async => fail('Unexpected cache mutation'),
  );

  test('offline restart retains exact cache and original date', () async {
    final result = await loader(cache: raw, bundle: '{}').load();
    expect(result.origin, 'cache');
    expect(result.refreshFailed, isTrue);
    expect(result.data['observedDate'], '2026-11-22');
  });
  test('corrupt cache and unreviewed refresh retain reviewed bundle', () async {
    final result = await loader(cache: '{}', remote: '$raw ').load();
    expect(result.origin, 'bundle');
    expect(result.refreshFailed, isTrue);
    expect(result.data, jsonDecode(raw));
  });
  test('even hash-pinned private candidates cannot enter release loader', () {
    final candidate = jsonEncode({
      ...jsonDecode(raw) as Map<String, dynamic>,
      'productionReady': false,
      'recordType': 'private development candidate',
    });
    final service = loader(
      digest: sha256.convert(utf8.encode(candidate)).toString(),
    );
    expect(() => service.decode(candidate), throwsFormatException);
  });
  test('remote persists original bytes without reserialization', () async {
    String? written;
    final result = await loader(
      remote: raw,
      write: (value) async {
        written = value;
      },
    ).load();
    expect(written, raw);
    expect(result.origin, 'remote');
    expect(result.refreshFailed, isFalse);
    expect(result.persistenceFailed, isFalse);
  });
  test('storage failure is distinct from remote failure', () async {
    final result = await loader(
      remote: raw,
      write: (_) async => throw StateError('full storage'),
    ).load();
    expect(result.origin, 'remote');
    expect(result.refreshFailed, isFalse);
    expect(result.persistenceFailed, isTrue);
  });
  test('no reviewed fallback fails without manufacturing coverage', () async {
    await expectLater(loader(bundle: '{}').load(), throwsStateError);
  });
}
