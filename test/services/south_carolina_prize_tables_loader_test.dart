import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/south_carolina_prize_tables_loader.dart';

void main() {
  final raw = File(
    'data/south_carolina_draw_reports.generated.json',
  ).readAsStringSync();
  test('offline cache preserves draw dates and all seven games', () async {
    final data = await SouthCarolinaPrizeTablesLoader(
      readCache: () async => raw,
      fetchRemote: () async => throw StateError('offline'),
      readBundle: () async => throw StateError('cache should win'),
    ).load();
    expect(
      (data['reports'] as List).map((r) => r['gameName']).toSet(),
      hasLength(7),
    );
    expect(data['reports'][0]['drawDate'], isNotEmpty);
  });
  test('wrong-state response cannot replace valid bundle or cache', () async {
    var wrote = false;
    final data = await SouthCarolinaPrizeTablesLoader(
      readCache: () async => null,
      fetchRemote: () async =>
          raw.replaceFirst('"state": "SC"', '"state": "TX"'),
      writeCache: (_) async {
        wrote = true;
      },
      readBundle: () async => raw,
    ).load();
    expect(data['state'], 'SC');
    expect(wrote, isFalse);
  });
}
