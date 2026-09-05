import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/models/lottery_activity.dart';
import 'package:lottery_atlas/widgets/map/map_filter_state.dart';

void main() {
  Map<String, dynamic> record({
    double latitude = 34.0,
    double longitude = -81.0,
    int winningTickets = 1,
    int prizeAmount = 500,
  }) => {
    'id': 'sc-test-1',
    'latitude': latitude,
    'longitude': longitude,
    'city': 'Columbia',
    'county': 'Richland County',
    'state': 'sc',
    'game': 'state-draw',
    'gameName': 'Palmetto Cash 5',
    'drawDate': '2026-08-28T12:00:00-04:00',
    'winningTickets': winningTickets,
    'prizeAmount': prizeAmount,
  };

  test('normalizes a valid published record', () {
    final activity = LotteryActivity.fromJson(record());

    expect(activity.state, 'SC');
    expect(activity.game, LotteryGame.stateDraw);
    expect(activity.location.latitude, 34.0);
    expect(activity.location.longitude, -81.0);
  });

  test('rejects a record outside valid map coordinates', () {
    expect(
      () => LotteryActivity.fromJson(record(latitude: 91)),
      throwsFormatException,
    );
    expect(
      () => LotteryActivity.fromJson(record(longitude: -181)),
      throwsFormatException,
    );
  });

  test('rejects negative heat-map amounts', () {
    expect(
      () => LotteryActivity.fromJson(record(winningTickets: -1)),
      throwsFormatException,
    );
    expect(
      () => LotteryActivity.fromJson(record(prizeAmount: -1)),
      throwsFormatException,
    );
  });
}
