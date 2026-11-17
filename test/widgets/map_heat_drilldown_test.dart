import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottery_atlas/main.dart';
import 'package:lottery_atlas/models/lottery_activity.dart';
import 'package:lottery_atlas/services/lottery_activity_repository.dart';
import 'package:lottery_atlas/services/map_focus_service.dart';
import 'package:lottery_atlas/services/map_ranking_service.dart';
import 'package:lottery_atlas/widgets/map/county_heat_layer.dart';
import 'package:lottery_atlas/widgets/map/map_filter_state.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets(
    'areas at national/state depth, city then retailer bubbles on drilldown',
    (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('lottery_atlas/magic_mouse'),
        (_) async => null,
      );
      await tester.binding.setSurfaceSize(const Size(1280, 900));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(const LotteryAtlasApp());
      for (var i = 0; i < 30; i++) {
        await tester.runAsync(
          () => Future<void>.delayed(const Duration(milliseconds: 100)),
        );
        await tester.pump(const Duration(milliseconds: 100));
      }
      final now = DateTime.now();
      // Explicit test fixtures, never written to production feeds.
      LotteryActivityRepository.usePublishedActivity([
        LotteryActivity(
          id: 'test-only',
          location: const LatLng(34.9496, -81.932),
          city: 'Spartanburg',
          county: 'Spartanburg',
          state: 'SC',
          game: LotteryGame.powerball,
          gameName: 'Powerball',
          drawDate: DateTime(now.year, now.month, now.day),
          winningTickets: 5,
          prizeAmount: 100,
          retailerName: 'Fixture store',
          retailerAddress: 'Fixture address',
        ),
      ], sourceLabel: 'Test fixture');
      await tester.pump();
      expect(find.byType(CircleLayer), findsNothing);
      MapFocusService.focusState('South Carolina');
      await tester.pumpAndSettle();
      expect(find.byType(CircleLayer), findsNothing);
      final regions = tester
          .widget<CountyHeatLayer>(find.byType(CountyHeatLayer))
          .regions;
      expect(regions.any((r) => r.sites.isNotEmpty), isTrue);
      final countyId =
          MapRankingService.snapshot.value.countyIds['spartanburg']!;
      MapFocusService.focusCounty(
        stateName: 'South Carolina',
        countyId: countyId,
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<CircleLayer>(find.byType(CircleLayer)).circles,
        hasLength(1),
      );
      MapFocusService.focusCity(
        stateName: 'South Carolina',
        city: 'Spartanburg',
        location: const LatLng(34.9496, -81.932),
        countyId: countyId,
      );
      await tester.pumpAndSettle();
      expect(
        tester.widget<CircleLayer>(find.byType(CircleLayer)).circles,
        hasLength(1),
      );
      expect(find.text('Fixture store'), findsWidgets);
      MapFocusService.focusState('Delaware');
      await tester.pumpAndSettle();
      expect(find.byType(CircleLayer), findsNothing);
      expect(
        tester
            .widget<CountyHeatLayer>(find.byType(CountyHeatLayer))
            .regions
            .every((r) => r.sites.isEmpty),
        isTrue,
      );
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
