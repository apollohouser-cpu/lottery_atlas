import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottery_atlas/models/lottery_activity.dart';
import 'package:lottery_atlas/services/map_ranking_service.dart';
import 'package:lottery_atlas/services/trending_service.dart';
import 'package:lottery_atlas/widgets/map/map_filter_state.dart';

LotteryActivity record(
  String state,
  int day,
  int tickets, {
  String county = 'Union',
  String? retailer = 'Shop',
}) => LotteryActivity(
  id: '$state-$day-$tickets',
  location: const LatLng(35, -80),
  city: 'Town',
  county: county,
  state: state,
  game: LotteryGame.powerball,
  drawDate: DateTime(2026, 11, day),
  winningTickets: tickets,
  prizeAmount: 100,
  retailerName: retailer,
  retailerAddress: '1 Main St',
);
MapRankingSnapshot snapshot(
  List<LotteryActivity> records, {
  int end = 10,
  String? state,
}) => MapRankingSnapshot(
  records: records,
  dateRangeStart: DateTime(2026, 11, 1),
  dateRangeEnd: DateTime(2026, 11, end, 23, 59),
  countyIds: const {},
  stateAbbreviation: state,
);
void main() {
  test('persistent fourth place outranks a one-window leader', () {
    final data = <LotteryActivity>[];
    for (var day = 1; day <= 10; day++) {
      for (final state in ['TX', 'NY', 'VA']) {
        data.add(record(state, day, 20));
      }
      data.add(record('SC', day, 5));
    }
    data.add(record('CA', 1, 10000));
    final result = TrendingService.calculate(
      snapshot(data),
      MapRankingLevel.state,
    );
    expect(result.windows, 10);
    expect(
      result.entries.firstWhere((e) => e.entry.key == 'SC').appearances,
      10,
    );
    expect(result.entries.any((e) => e.entry.key == 'CA'), false);
  });
  test(
    'empty windows remain in denominator; one day cannot establish trend',
    () {
      final data = [record('SC', 1, 1), record('SC', 10, 1)];
      final result = TrendingService.calculate(
        snapshot(data),
        MapRankingLevel.state,
      );
      expect(result.observedWindows, 2);
      expect(result.windows, 10);
      expect(result.entries.single.appearances, 2);
      expect(
        TrendingService.calculate(
          snapshot(data, end: 1),
          MapRankingLevel.state,
        ).entries,
        isEmpty,
      );
    },
  );
  test(
    'same-named counties stay separate nationally and state scope applies',
    () {
      final data = [
        for (var day = 1; day <= 2; day++) ...[
          record('SC', day, 2),
          record('NC', day, 3),
        ],
      ];
      final result = TrendingService.calculate(
        snapshot(data, end: 2),
        MapRankingLevel.county,
      );
      expect(result.entries.length, 2);
      expect(
        result.entries.map((e) => e.entry.label),
        containsAll(['Union, SC', 'Union, NC']),
      );
      expect(
        TrendingService.calculate(
          snapshot(data, end: 2, state: 'SC'),
          MapRankingLevel.county,
        ).entries.length,
        1,
      );
    },
  );
  test('all five dimensions and missing retailer handling', () {
    final data = [record('SC', 1, 2), record('SC', 2, 2)];
    for (final level in MapRankingLevel.values) {
      expect(
        TrendingService.calculate(
          snapshot(data, end: 2),
          level,
        ).entries.single.appearances,
        2,
      );
    }
    expect(
      TrendingService.calculate(
        snapshot([
          record('SC', 1, 2, retailer: null),
          record('SC', 2, 2, retailer: null),
        ], end: 2),
        MapRankingLevel.retailer,
      ).entries,
      isEmpty,
    );
  });
  test('average rank resolves frequency ties', () {
    final result = TrendingService.calculate(
      snapshot([
        record('SC', 1, 2),
        record('NC', 1, 5),
        record('SC', 2, 2),
        record('NC', 2, 5),
      ], end: 2),
      MapRankingLevel.state,
    );
    expect(result.entries.first.entry.key, 'NC');
  });
}
