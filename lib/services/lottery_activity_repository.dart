import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

import '../models/lottery_activity.dart';
import '../widgets/map/map_filter_state.dart';

/// Activity feed shared by the map, games, and stats views.
///
/// The retained sample list is only a development reference. Production starts
/// with no heat-map points until bundled or published official records load;
/// a network or asset failure must never show fabricated lottery activity.
class LotteryActivityRepository {
  LotteryActivityRepository._();

  static bool _isSampleData = true;
  static bool _isCachedActivityData = false;
  static String _activitySourceLabel = 'No verified map activity loaded';
  static DateTime? _activityUpdatedAt;
  static DateTime? _activitySourceLastUpdated;
  static String? _activityCoverageNote;
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static final List<LotteryActivity> _sampleActivity = [
    LotteryActivity(
      id: 'ca-la-aug12',
      location: LatLng(34.0522, -118.2437),
      city: 'Los Angeles',
      county: 'Los Angeles County',
      state: 'CA',
      game: LotteryGame.powerball,
      drawDate: DateTime(2026, 8, 12, 22, 59),
      winningTickets: 118,
      prizeAmount: 1000000,
      isFavorite: true,
    ),
    LotteryActivity(
      id: 'fl-miami-aug12',
      location: LatLng(25.7617, -80.1918),
      city: 'Miami',
      county: 'Miami-Dade County',
      state: 'FL',
      game: LotteryGame.powerball,
      drawDate: DateTime(2026, 8, 12, 22, 59),
      winningTickets: 106,
      prizeAmount: 500000,
      isFavorite: true,
    ),
    LotteryActivity(
      id: 'tx-houston-aug11',
      location: LatLng(29.7604, -95.3698),
      city: 'Houston',
      county: 'Harris County',
      state: 'TX',
      game: LotteryGame.stateDraw,
      drawDate: DateTime(2026, 8, 11, 20, 0),
      winningTickets: 83,
      prizeAmount: 250000,
      isFavorite: true,
    ),
    LotteryActivity(
      id: 'ny-nyc-aug11',
      location: LatLng(40.7128, -74.0060),
      city: 'New York',
      county: 'New York County',
      state: 'NY',
      game: LotteryGame.megaMillions,
      drawDate: DateTime(2026, 8, 11, 23, 0),
      winningTickets: 98,
      prizeAmount: 1000000,
      isFavorite: true,
    ),
    LotteryActivity(
      id: 'il-chicago-aug10',
      location: LatLng(41.8781, -87.6298),
      city: 'Chicago',
      county: 'Cook County',
      state: 'IL',
      game: LotteryGame.powerball,
      drawDate: DateTime(2026, 8, 10, 22, 59),
      winningTickets: 77,
      prizeAmount: 500000,
    ),
    LotteryActivity(
      id: 'ga-atlanta-aug9',
      location: LatLng(33.7490, -84.3880),
      city: 'Atlanta',
      county: 'Fulton County',
      state: 'GA',
      game: LotteryGame.stateDraw,
      drawDate: DateTime(2026, 8, 9, 19, 30),
      winningTickets: 66,
      prizeAmount: 100000,
    ),
    LotteryActivity(
      id: 'pa-pittsburgh-aug7',
      location: LatLng(40.4406, -79.9959),
      city: 'Pittsburgh',
      county: 'Allegheny County',
      state: 'PA',
      game: LotteryGame.scratchOff,
      drawDate: DateTime(2026, 8, 7, 12, 0),
      winningTickets: 24,
      prizeAmount: 75000,
    ),
    LotteryActivity(
      id: 'co-denver-aug6',
      location: LatLng(39.7392, -104.9903),
      city: 'Denver',
      county: 'Denver County',
      state: 'CO',
      game: LotteryGame.megaMillions,
      drawDate: DateTime(2026, 8, 6, 23, 0),
      winningTickets: 31,
      prizeAmount: 250000,
    ),
    LotteryActivity(
      id: 'nc-charlotte-aug4',
      location: LatLng(35.2271, -80.8431),
      city: 'Charlotte',
      county: 'Mecklenburg County',
      state: 'NC',
      game: LotteryGame.powerball,
      drawDate: DateTime(2026, 8, 4, 22, 59),
      winningTickets: 49,
      prizeAmount: 100000,
    ),
    LotteryActivity(
      id: 'ca-sf-aug1',
      location: LatLng(37.7749, -122.4194),
      city: 'San Francisco',
      county: 'San Francisco County',
      state: 'CA',
      game: LotteryGame.megaMillions,
      drawDate: DateTime(2026, 8, 1, 23, 0),
      winningTickets: 72,
      prizeAmount: 500000,
    ),
    LotteryActivity(
      id: 'fl-orlando-jul28',
      location: LatLng(28.5383, -81.3792),
      city: 'Orlando',
      county: 'Orange County',
      state: 'FL',
      game: LotteryGame.scratchOff,
      drawDate: DateTime(2026, 7, 28, 12, 0),
      winningTickets: 54,
      prizeAmount: 100000,
    ),
    LotteryActivity(
      id: 'tx-dallas-jul22',
      location: LatLng(32.7767, -96.7970),
      city: 'Dallas',
      county: 'Dallas County',
      state: 'TX',
      game: LotteryGame.megaMillions,
      drawDate: DateTime(2026, 7, 22, 23, 0),
      winningTickets: 41,
      prizeAmount: 250000,
    ),
    LotteryActivity(
      id: 'wa-seattle-jul18',
      location: LatLng(47.6062, -122.3321),
      city: 'Seattle',
      county: 'King County',
      state: 'WA',
      game: LotteryGame.scratchOff,
      drawDate: DateTime(2026, 7, 18, 12, 0),
      winningTickets: 18,
      prizeAmount: 50000,
    ),
    LotteryActivity(
      id: 'mn-minneapolis-jun15',
      location: LatLng(44.9778, -93.2650),
      city: 'Minneapolis',
      county: 'Hennepin County',
      state: 'MN',
      game: LotteryGame.stateDraw,
      drawDate: DateTime(2026, 6, 15, 19, 0),
      winningTickets: 12,
      prizeAmount: 25000,
    ),
    LotteryActivity(
      id: 'az-phoenix-may20',
      location: LatLng(33.4484, -112.0740),
      city: 'Phoenix',
      county: 'Maricopa County',
      state: 'AZ',
      game: LotteryGame.powerball,
      drawDate: DateTime(2026, 5, 20, 22, 59),
      winningTickets: 35,
      prizeAmount: 100000,
    ),
    LotteryActivity(
      id: 'oh-columbus-apr17',
      location: LatLng(39.9612, -82.9988),
      city: 'Columbus',
      county: 'Franklin County',
      state: 'OH',
      game: LotteryGame.megaMillions,
      drawDate: DateTime(2026, 4, 17, 23, 0),
      winningTickets: 28,
      prizeAmount: 100000,
    ),
    LotteryActivity(
      id: 'nv-vegas-mar21',
      location: LatLng(36.1699, -115.1398),
      city: 'Las Vegas',
      county: 'Clark County',
      state: 'NV',
      game: LotteryGame.scratchOff,
      drawDate: DateTime(2026, 3, 21, 12, 0),
      winningTickets: 63,
      prizeAmount: 250000,
    ),
    LotteryActivity(
      id: 'mi-detroit-feb14',
      location: LatLng(42.3314, -83.0458),
      city: 'Detroit',
      county: 'Wayne County',
      state: 'MI',
      game: LotteryGame.stateDraw,
      drawDate: DateTime(2026, 2, 14, 19, 30),
      winningTickets: 45,
      prizeAmount: 100000,
    ),
    LotteryActivity(
      id: 'la-neworleans-jan7',
      location: LatLng(29.9511, -90.0715),
      city: 'New Orleans',
      county: 'Orleans Parish',
      state: 'LA',
      game: LotteryGame.powerball,
      drawDate: DateTime(2026, 1, 7, 22, 59),
      winningTickets: 21,
      prizeAmount: 50000,
    ),
    LotteryActivity(
      id: 'wi-milwaukee-dec10',
      location: LatLng(43.0389, -87.9065),
      city: 'Milwaukee',
      county: 'Milwaukee County',
      state: 'WI',
      game: LotteryGame.megaMillions,
      drawDate: DateTime(2025, 12, 10, 23, 0),
      winningTickets: 38,
      prizeAmount: 100000,
    ),
  ];

  // Kept false in production. Referencing the fixture preserves it for manual
  // developer testing without ever allowing it to reach a user-facing map.
  static const bool _useDevelopmentSampleActivity = false;
  static List<LotteryActivity> _activity = _useDevelopmentSampleActivity
      ? _sampleActivity
      : const <LotteryActivity>[];

  static List<LotteryActivity> get activity => List.unmodifiable(_activity);
  static bool get isSampleData => _isSampleData;
  static bool get isCachedActivityData => _isCachedActivityData;
  static String get activitySourceLabel => _activitySourceLabel;
  static DateTime? get activityUpdatedAt => _activityUpdatedAt;
  static DateTime? get activitySourceLastUpdated => _activitySourceLastUpdated;
  static String? get activityCoverageNote => _activityCoverageNote;

  static void usePublishedActivity(
    List<LotteryActivity> records, {
    required String sourceLabel,
    DateTime? updatedAt,
    bool isCached = false,
    DateTime? sourceLastUpdated,
    String? coverageNote,
  }) {
    if (records.isEmpty) {
      throw ArgumentError.value(records, 'records', 'must not be empty');
    }
    _activity = List<LotteryActivity>.unmodifiable(records);
    _isSampleData = false;
    _isCachedActivityData = isCached;
    _activitySourceLabel = sourceLabel;
    _activityUpdatedAt = updatedAt;
    _activitySourceLastUpdated = sourceLastUpdated;
    _activityCoverageNote = coverageNote;
    changes.value++;
  }
}
