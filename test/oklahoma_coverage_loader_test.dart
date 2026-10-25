import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/oklahoma_coverage_loader.dart';
import 'package:lottery_atlas/services/oklahoma_coverage_validator.dart';

void main() {
  final raw = File('data/oklahoma_coverage.generated.json').readAsStringSync();
  Map<String, dynamic> fixture() => jsonDecode(raw) as Map<String, dynamic>;
  void unknown(Map<String, dynamic> d, String kind) {
    final game = d['products'][kind]['games'][0];
    game['prizeTiers'] = [];
    if (kind == 'scratch') {
      game['topPrizesRemaining'] = null;
      game['inventoryNote'] =
          'Prize inventory not published for this game; remaining counts are unknown. ${game['inventoryNote']}';
    } else {
      game['inventoryStatus'] = 'unavailable';
    }
  }

  test('explicit unknown inventory remains empty and nullable', () {
    for (final kind in ['scratch', 'fastPlay']) {
      final d = fixture();
      unknown(d, kind);
      final next = OklahomaCoverageValidator.decode(jsonEncode(d));
      expect(next['products'][kind]['games'][0]['prizeTiers'], isEmpty);
      OklahomaCoverageValidator.continuity(fixture(), next);
      OklahomaCoverageValidator.continuity(next, fixture());
      if (kind == 'scratch') {
        expect(
          next['products'][kind]['games'][0]['topPrizesRemaining'],
          isNull,
        );
      }
    }
  });
  test('empty inventory requires explicit unknown status', () {
    for (final kind in ['scratch', 'fastPlay']) {
      final d = fixture();
      d['products'][kind]['games'][0]['prizeTiers'] = [];
      expect(
        () => OklahomaCoverageValidator.decode(jsonEncode(d)),
        throwsFormatException,
      );
    }
  });
  test('product and source timestamps must join', () {
    final d = fixture();
    d['products']['scratch']['games'][0]['retrievedAt'] = d['updatedAt'];
    expect(
      () => OklahomaCoverageValidator.decode(jsonEncode(d)),
      throwsFormatException,
    );
  });
  test('individual source cache regression rejected', () {
    final old = fixture();
    final next = fixture();
    old['sources'][0]['retrievedAt'] = old['updatedAt'];
    expect(
      () => OklahomaCoverageValidator.continuity(old, next),
      throwsFormatException,
    );
  });
  Map<String, dynamic> advanced() {
    final d = fixture();
    final rows = d['results'] as List;
    final indices = [
      for (var i = 0; i < rows.length; i++)
        if (rows[i]['game'] == 'powerball-xs-os') i,
    ];
    final newest = Map<String, dynamic>.from(rows[indices.first] as Map);
    rows[indices.last] = Map<String, dynamic>.from(newest);
    final stamp = DateTime.parse(
      newest['drawDateTimeUTC'] as String,
    ).add(const Duration(days: 1));
    newest['drawDateTimeUTC'] = stamp.toIso8601String().replaceFirst(
      '.000Z',
      'Z',
    );
    newest['date'] = DateTime.parse(
      newest['date'] as String,
    ).add(const Duration(days: 1)).toIso8601String().substring(0, 10);
    rows[indices.first] = newest;
    return d;
  }

  test('strict rolling window advances and retains source codes', () {
    final next = OklahomaCoverageValidator.decode(jsonEncode(advanced()));
    OklahomaCoverageValidator.continuity(fixture(), next);
    expect(
      () => OklahomaCoverageValidator.continuity(next, fixture()),
      throwsFormatException,
    );
  });
  test('same-date corrections rejected', () {
    final d = fixture();
    d['results'][0]['numbers'][0] = 69;
    expect(
      () => OklahomaCoverageValidator.decode(jsonEncode(d)),
      throwsFormatException,
    );
  });
  test('advancing results reject out-of-range code and report injection', () {
    for (final field in ['numbers', 'reportStatus', 'session']) {
      final d = advanced();
      final r = (d['results'] as List).firstWhere(
        (r) => r['game'] == 'powerball-xs-os',
      );
      if (field == 'numbers') {
        r['numbers'] = [0, 2, 3, 4, 5, 6, 7, 8];
      }
      if (field == 'reportStatus') {
        r[field] = 'available';
      }
      if (field == 'session') {
        r[field] = 'Evening';
      }
      expect(
        () => OklahomaCoverageValidator.decode(jsonEncode(d)),
        throwsFormatException,
      );
    }
  });
  test('Double Play parent loss rejected', () {
    final d = fixture();
    (d['results'] as List).removeWhere((r) => r['variant'] == 'double_play');
    expect(
      () => OklahomaCoverageValidator.decode(jsonEncode(d)),
      throwsFormatException,
    );
  });
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
  test('date without matching UTC timestamp is rejected', () {
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
