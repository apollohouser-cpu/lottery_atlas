import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottery_atlas/models/lottery_activity.dart';
import 'package:lottery_atlas/services/map_ranking_service.dart';
import 'package:lottery_atlas/widgets/map/map_filter_state.dart';

LotteryActivity _activity({
  required String id,
  required String state,
  required String county,
  required String city,
  required String retailer,
  required String game,
  required int tickets,
  required int prize,
}) => LotteryActivity(
  id: id,
  location: const LatLng(40, -75),
  city: city,
  county: county,
  state: state,
  game: game == 'Powerball' ? LotteryGame.powerball : LotteryGame.scratchOff,
  gameName: game,
  retailerName: retailer,
  retailerAddress: '$id Main Street',
  drawDate: DateTime(2026, 6, 1),
  winningTickets: tickets,
  prizeAmount: prize,
);

MapRankingSnapshot _snapshot(
  List<LotteryActivity> records, {
  String? stateName,
  String? stateAbbreviation,
  String? countyName,
  String? cityName,
  String? retailerName,
  String? retailerAddress,
}) => MapRankingSnapshot(
  records: records,
  dateRangeStart: DateTime(2026, 1, 1),
  dateRangeEnd: DateTime(2026, 12, 31),
  stateName: stateName,
  stateAbbreviation: stateAbbreviation,
  countyName: countyName,
  countyId: countyName == null ? null : 'county-1',
  cityName: cityName,
  retailerName: retailerName,
  retailerAddress: retailerAddress,
  countyIds: const <String, String>{'alpha': 'county-1', 'beta': 'county-2'},
);

void main() {
  final records = <LotteryActivity>[
    _activity(
      id: 'one',
      state: 'NY',
      county: 'Alpha County',
      city: 'Albany',
      retailer: 'Market One',
      game: 'Powerball',
      tickets: 8,
      prize: 100000,
    ),
    _activity(
      id: 'two',
      state: 'NY',
      county: 'Alpha County',
      city: 'Albany',
      retailer: 'Market Two',
      game: 'Scratch Gold',
      tickets: 3,
      prize: 500000,
    ),
    _activity(
      id: 'three',
      state: 'VA',
      county: 'Beta County',
      city: 'Richmond',
      retailer: 'Market Three',
      game: 'Powerball',
      tickets: 4,
      prize: 200000,
    ),
  ];

  test('national rankings order states by winning-ticket total', () {
    final rankings = MapRankingService.rankings(_snapshot(records));
    expect(rankings.map((entry) => entry.label), <String>[
      'New York',
      'Virginia',
    ]);
    expect(rankings.first.winningTickets, 11);
    expect(rankings.first.publishedPrizeTotal, 600000);
    expect(rankings.first.gameBreakdown['Powerball'], 8);
  });

  test('state and county selections drill into counties then cities', () {
    final counties = MapRankingService.rankings(
      _snapshot(records, stateName: 'New York', stateAbbreviation: 'NY'),
    );
    expect(counties.single.label, 'Alpha County');
    expect(counties.single.countyId, 'county-1');

    final cities = MapRankingService.rankings(
      _snapshot(
        records,
        stateName: 'New York',
        stateAbbreviation: 'NY',
        countyName: 'Alpha County',
      ),
    );
    expect(cities.single.label, 'Albany');
    expect(cities.single.winningTickets, 11);
  });

  test('city and retailer selections drill into retailers then games', () {
    final retailers = MapRankingService.rankings(
      _snapshot(
        records,
        stateName: 'New York',
        stateAbbreviation: 'NY',
        countyName: 'Alpha County',
        cityName: 'Albany',
      ),
    );
    expect(retailers, hasLength(2));
    expect(retailers.first.label, 'Market One');

    final games = MapRankingService.rankings(
      _snapshot(
        records,
        stateName: 'New York',
        stateAbbreviation: 'NY',
        countyName: 'Alpha County',
        cityName: 'Albany',
        retailerName: 'Market One',
        retailerAddress: 'one Main Street',
      ),
    );
    expect(games.single.label, 'Powerball');
    expect(games.single.winningTickets, 8);
  });
}
