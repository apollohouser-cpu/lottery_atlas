import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottery_atlas/models/lottery_activity.dart';
import 'package:lottery_atlas/services/lottery_activity_repository.dart';
import 'package:lottery_atlas/services/map_ranking_service.dart';
import 'package:lottery_atlas/widgets/map/map_filter_state.dart';
import 'package:lottery_atlas/widgets/navigation/bottom_nav.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('Games follows selected state on each visit and national reset', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    LotteryActivity record(String state, String city) => LotteryActivity(
      id: state,
      location: const LatLng(0, 0),
      city: city,
      county: 'Test county',
      state: state,
      game: LotteryGame.powerball,
      drawDate: DateTime(2026, 11, 12),
      winningTickets: 1,
      prizeAmount: 100,
    );
    LotteryActivityRepository.usePublishedActivity([
      record('TX', 'Houston'),
      record('SC', 'Columbia'),
    ], sourceLabel: 'Test fixture');
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(bottomNavigationBar: BottomNav())),
    );
    Future<void> open(String? state, String? abbreviation) async {
      MapRankingService.publish(
        MapRankingSnapshot(
          records: const [],
          dateRangeStart: DateTime(2026),
          dateRangeEnd: DateTime(2026, 12),
          countyIds: const {},
          stateName: state,
          stateAbbreviation: abbreviation,
        ),
      );
      await tester.tap(find.text('Games'));
      await tester.pumpAndSettle();
    }

    Future<void> back() async {
      await tester.pageBack();
      await tester.pumpAndSettle();
    }

    await open('Texas', 'TX');
    expect(find.text('Houston, TX'), findsOneWidget);
    expect(find.text('Columbia, SC'), findsNothing);
    await back();
    await open('South Carolina', 'SC');
    expect(find.text('South Carolina Lottery Activity'), findsOneWidget);
    expect(find.text('Columbia, SC'), findsOneWidget);
    expect(find.text('Houston, TX'), findsNothing);
    expect(find.text('Terminal Instant Games'), findsNothing);
    await tester.tap(find.byType(TextField));
    await tester.enterText(find.byType(TextField), 'Texas');
    await tester.pumpAndSettle();
    expect(find.text('No activity matches those filters.'), findsOneWidget);
    expect(find.text('Houston, TX'), findsNothing);
    await back();
    await open('Delaware', 'DE');
    expect(find.text('Delaware Lottery Activity'), findsOneWidget);
    expect(find.text('No activity matches those filters.'), findsOneWidget);
    expect(find.text('Houston, TX'), findsNothing);
    await back();
    await open(null, null);
    expect(find.text('Lottery Activity'), findsOneWidget);
    expect(find.text('Houston, TX'), findsOneWidget);
    expect(find.text('Columbia, SC'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
