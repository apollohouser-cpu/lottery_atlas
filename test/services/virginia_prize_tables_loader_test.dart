import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/virginia_prize_tables_loader.dart';

void main() {
  final raw = File(
    'data/virginia_draw_reports.generated.json',
  ).readAsStringSync();
  test('valid remote data survives persistence failure', () async {
    final data = await VirginiaPrizeTablesLoader(
      readCache: () async => null,
      fetchRemote: () async => raw,
      writeCache: (_) async => throw StateError('disk full'),
      readBundle: () async => throw StateError('must not fall back'),
    ).load();
    expect(
      data,
      equals(jsonDecode(raw)),
    ); // Preserve every supplied report and date.
  });
  test(
    'network failure retains cached source dates and unit distinctions',
    () async {
      final data = await VirginiaPrizeTablesLoader(
        readCache: () async => raw,
        fetchRemote: () async => throw StateError('offline'),
      ).load();
      expect(data['retrievedAt'], jsonDecode(raw)['retrievedAt']);
      expect(
        (data['reports'] as List).firstWhere(
          (r) => r['game'] == 'keno',
        )['totalWinners'],
        isNull,
      );
    },
  );
  test('invalid national allocation cannot replace valid cache', () async {
    final invalid = jsonDecode(raw);
    (invalid['reports'] as List).firstWhere(
      (r) => r['game'] == 'powerball',
    )['jurisdiction'] = 'Virginia';
    var wrote = false;
    final data = await VirginiaPrizeTablesLoader(
      readCache: () async => raw,
      fetchRemote: () async => jsonEncode(invalid),
      writeCache: (_) async {
        wrote = true;
      },
    ).load();
    expect(wrote, isFalse);
    expect(
      (data['reports'] as List).firstWhere(
        (r) => r['game'] == 'powerball',
      )['jurisdiction'],
      isNot('Virginia'),
    );
  });
  test('corrupt cache and unavailable network use bundled coverage', () async {
    final data = await VirginiaPrizeTablesLoader(
      readCache: () async => '{}',
      fetchRemote: () async => throw StateError('offline'),
      readBundle: () async => raw,
    ).load();
    expect((data['reports'] as List).map((r) => r['game']).toSet().length, 10);
  });
}
