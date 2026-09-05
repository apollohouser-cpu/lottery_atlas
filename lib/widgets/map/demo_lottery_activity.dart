import 'package:latlong2/latlong.dart';

import 'map_filter_state.dart';

class LotteryActivityPoint {
  const LotteryActivityPoint({
    required this.location,
    required this.city,
    required this.state,
    required this.game,
    required this.drawDate,
    required this.winningTickets,
    required this.isFavorite,
  });

  final LatLng location;
  final String city;
  final String state;
  final LotteryGame game;
  final DateTime drawDate;
  final int winningTickets;
  final bool isFavorite;

  bool get hasWinningActivity => winningTickets > 0;

  double get radius {
    if (winningTickets >= 100) return 18;
    if (winningTickets >= 50) return 15;
    if (winningTickets >= 20) return 12;
    if (winningTickets >= 5) return 9;
    return 6;
  }
}

final List<LotteryActivityPoint> demoLotteryActivity = [
  LotteryActivityPoint(
    location: LatLng(34.0522, -118.2437),
    city: 'Los Angeles',
    state: 'CA',
    game: LotteryGame.powerball,
    drawDate: DateTime(2026, 7, 30),
    winningTickets: 118,
    isFavorite: true,
  ),
  LotteryActivityPoint(
    location: LatLng(37.7749, -122.4194),
    city: 'San Francisco',
    state: 'CA',
    game: LotteryGame.megaMillions,
    drawDate: DateTime(2026, 7, 22),
    winningTickets: 72,
    isFavorite: false,
  ),
  LotteryActivityPoint(
    location: LatLng(25.7617, -80.1918),
    city: 'Miami',
    state: 'FL',
    game: LotteryGame.powerball,
    drawDate: DateTime(2026, 7, 28),
    winningTickets: 106,
    isFavorite: true,
  ),
  LotteryActivityPoint(
    location: LatLng(28.5383, -81.3792),
    city: 'Orlando',
    state: 'FL',
    game: LotteryGame.scratchOff,
    drawDate: DateTime(2026, 6, 16),
    winningTickets: 54,
    isFavorite: false,
  ),
  LotteryActivityPoint(
    location: LatLng(29.7604, -95.3698),
    city: 'Houston',
    state: 'TX',
    game: LotteryGame.stateDraw,
    drawDate: DateTime(2026, 7, 19),
    winningTickets: 83,
    isFavorite: true,
  ),
  LotteryActivityPoint(
    location: LatLng(32.7767, -96.7970),
    city: 'Dallas',
    state: 'TX',
    game: LotteryGame.megaMillions,
    drawDate: DateTime(2026, 5, 28),
    winningTickets: 41,
    isFavorite: false,
  ),
  LotteryActivityPoint(
    location: LatLng(40.7128, -74.0060),
    city: 'New York',
    state: 'NY',
    game: LotteryGame.megaMillions,
    drawDate: DateTime(2026, 7, 26),
    winningTickets: 98,
    isFavorite: true,
  ),
  LotteryActivityPoint(
    location: LatLng(40.4406, -79.9959),
    city: 'Pittsburgh',
    state: 'PA',
    game: LotteryGame.scratchOff,
    drawDate: DateTime(2026, 4, 12),
    winningTickets: 24,
    isFavorite: false,
  ),
  LotteryActivityPoint(
    location: LatLng(33.7490, -84.3880),
    city: 'Atlanta',
    state: 'GA',
    game: LotteryGame.stateDraw,
    drawDate: DateTime(2026, 7, 9),
    winningTickets: 66,
    isFavorite: false,
  ),
  LotteryActivityPoint(
    location: LatLng(35.2271, -80.8431),
    city: 'Charlotte',
    state: 'NC',
    game: LotteryGame.powerball,
    drawDate: DateTime(2026, 6, 3),
    winningTickets: 49,
    isFavorite: false,
  ),
  LotteryActivityPoint(
    location: LatLng(41.8781, -87.6298),
    city: 'Chicago',
    state: 'IL',
    game: LotteryGame.powerball,
    drawDate: DateTime(2026, 7, 14),
    winningTickets: 77,
    isFavorite: false,
  ),
  LotteryActivityPoint(
    location: LatLng(47.6062, -122.3321),
    city: 'Seattle',
    state: 'WA',
    game: LotteryGame.scratchOff,
    drawDate: DateTime(2026, 3, 18),
    winningTickets: 0,
    isFavorite: false,
  ),
  LotteryActivityPoint(
    location: LatLng(39.7392, -104.9903),
    city: 'Denver',
    state: 'CO',
    game: LotteryGame.megaMillions,
    drawDate: DateTime(2026, 2, 20),
    winningTickets: 31,
    isFavorite: false,
  ),
  LotteryActivityPoint(
    location: LatLng(44.9778, -93.2650),
    city: 'Minneapolis',
    state: 'MN',
    game: LotteryGame.stateDraw,
    drawDate: DateTime(2025, 11, 8),
    winningTickets: 12,
    isFavorite: false,
  ),
];
