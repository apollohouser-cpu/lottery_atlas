import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/models/lottery_activity.dart';
import '../../tooling/import_south_carolina_winners_report.dart';

Map<String, dynamic> row(String date, String id, {int count = 1}) => {
  'id': id,
  'drawDate': '${date}T12:00:00.000Z',
  'prizeAmount': 500,
  'gameName': 'Pick 3',
  'game': 'state-draw',
  'county': 'Spartanburg',
  'city': 'Spartanburg',
  'retailerName': 'Example Store',
  'retailerAddress': '1 Main St',
  'state': 'SC',
  'latitude': 34.95,
  'longitude': -81.93,
  'winningTickets': count,
  'sourceSnapshotDate': '2026-09-06T00:00:00.000Z',
};
void main() {
  test('restored snapshot IDs agree with app migration and remain unique', () {
    final root = jsonDecode(
      File(
        'data/south_carolina_current_winner_activity.generated.json',
      ).readAsStringSync(),
    );
    final ids = <String>{};
    for (final row in root['activities']) {
      final activity = LotteryActivity.fromJson(Map<String, dynamic>.from(row));
      expect(activity.id, row['id']);
      expect(ids.add(activity.id), isTrue);
    }
  });
  test(
    'retains older claims, replaces overlap, removes missing window rows',
    () {
      final old = row('2026-06-08', 'sc-winners-old');
      final overlap = row('2026-08-20', 'sc-winners-overlap');
      final removed = row('2026-08-21', 'sc-winners-removed');
      final current = row('2026-08-20', 'sc-winners-renumbered', count: 3);
      final result = retainSouthCarolinaHistory(
        [old, overlap, removed],
        [current],
        DateTime.utc(2026, 8, 20),
      );
      expect(result.length, 2);
      expect(result.first['sourceSnapshotDate'], old['sourceSnapshotDate']);
      expect(result.last['winningTickets'], 3);
      expect(
        result.every((r) => DateTime.parse(r['drawDate']).month >= 6),
        isTrue,
      );
      expect(
        retainSouthCarolinaHistory(result, [
          current,
        ], DateTime.utc(2026, 8, 20)),
        result,
      );
    },
  );
  test('empty refresh fails rather than clearing records', () {
    expect(
      () => retainSouthCarolinaHistory(
        [row('2026-06-08', 'old')],
        [],
        DateTime.utc(2026, 8),
      ),
      throwsFormatException,
    );
  });
  test('old bundle and corrected report share semantic identity', () {
    final old = LotteryActivity.fromJson(
      row('2026-08-20', 'sc-winners-2026-08-20-9'),
    );
    final updated = LotteryActivity.fromJson(
      row('2026-08-20', 'sc-winners-2026-08-20-14', count: 3),
    );
    expect(old.id, updated.id);
    expect(updated.winningTickets, 3);
  });
}
