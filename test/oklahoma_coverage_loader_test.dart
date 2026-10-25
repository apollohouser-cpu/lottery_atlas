import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/oklahoma_coverage_loader.dart';
import 'package:lottery_atlas/services/oklahoma_coverage_validator.dart';

void main() {
  final raw = File('data/oklahoma_coverage.generated.json').readAsStringSync();
  Map<String, dynamic> fixture() => jsonDecode(raw) as Map<String, dynamic>;
  test('baseline all products and unavailable reports', () {
    final d = OklahomaCoverageValidator.decode(raw);
    expect(d['results'].length, 14);
    expect(
      (d['results'] as List).every((r) => r['reportStatus'] == 'unavailable'),
      true,
    );
  });
  test('inventory decrease accepted; cache prevents rebound', () {
    final d = fixture();
    final tier = d['products']['fastPlay']['games'][0]['prizeTiers'][0];
    tier['remainingPrizes'] -= 1;
    final next = OklahomaCoverageValidator.decode(jsonEncode(d));
    OklahomaCoverageValidator.continuity(fixture(), next);
    expect(
      () => OklahomaCoverageValidator.continuity(next, fixture()),
      throwsFormatException,
    );
  });
  test('original quantities, rules, identities and missing status fail', () {
    for (final key in ['totalPrizes', 'prizeAmount']) {
      final d = fixture();
      d['products']['scratch']['games'][0]['prizeTiers'][0][key] = 9999999;
      expect(
        () => OklahomaCoverageValidator.decode(jsonEncode(d)),
        throwsFormatException,
      );
    }
    final d = fixture();
    d['results'][0]['reportStatus'] = 'available';
    expect(
      () => OklahomaCoverageValidator.decode(jsonEncode(d)),
      throwsFormatException,
    );
  });
  test('dated advancement remains explicitly fail closed', () {
    final d = fixture();
    d['results'][0]['date'] = '2026-10-25';
    expect(
      () => OklahomaCoverageValidator.decode(jsonEncode(d)),
      throwsFormatException,
    );
  });
  test('failure returns validated bundle without writing', () async {
    var writes = 0;
    final d = await OklahomaCoverageLoader(
      readCache: () async => null,
      readBundle: () async => raw,
      fetchRemote: () async =>
          throw const SocketException('controlled failure'),
      writeCache: (_) async {
        writes++;
      },
    ).load();
    expect(d['updatedAt'], fixture()['updatedAt']);
    expect(writes, 0);
  });
  test('corrupt remote retains cache bytes and date', () async {
    var cached = raw;
    final d = await OklahomaCoverageLoader(
      readCache: () async => cached,
      readBundle: () async => raw,
      fetchRemote: () async => '{}',
      writeCache: (value) async {
        cached = value;
      },
    ).load();
    expect(cached, raw);
    expect(d['updatedAt'], fixture()['updatedAt']);
  });
  test('valid remote remains usable if cache write fails', () async {
    final d = await OklahomaCoverageLoader(
      readCache: () async => null,
      readBundle: () async => raw,
      fetchRemote: () async => raw,
      writeCache: (_) async {
        throw const FileSystemException('disk');
      },
    ).load();
    expect(d['results'].length, 14);
  });
}
