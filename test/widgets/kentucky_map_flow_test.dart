import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/main.dart';
import 'package:lottery_atlas/services/map_focus_service.dart';
import 'package:lottery_atlas/services/map_ranking_service.dart';
import 'package:lottery_atlas/services/lottery_activity_repository.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  for (final size in [const Size(800, 632), const Size(1280, 900)]) {
    testWidgets(
      'Kentucky offline map exposes covered dates, county scope, details and reset at $size',
      (tester) async {
        rootBundle.clear();
        SharedPreferencesAsyncPlatform.instance =
            InMemorySharedPreferencesAsync.empty();
        tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
          const MethodChannel('lottery_atlas/magic_mouse'),
          (_) async => null,
        );
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        // The widget-test HTTP client rejects all requests. Only bundled data
        // can populate this real app flow; street tiles are not promised offline.
        await tester.pumpWidget(const LotteryAtlasApp());
        for (var i = 0; i < 30; i++) {
          await tester.runAsync(
            () async => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(
          LotteryActivityRepository.activity.map((row) => row.id),
          contains('ky-current-2026-08-31-amexpress9-bowlinggreen-35'),
        );
        MapFocusService.focusState('Kentucky');
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(find.textContaining('Kentucky'), findsWidgets);
        await tester.tap(find.text('DRAWINGS IN KENTUCKY'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.text('Statewide prize tables'));
        for (var i = 0; i < 10; i++) {
          await tester.runAsync(
            () async => Future<void>.delayed(const Duration(milliseconds: 100)),
          );
          await tester.pump(const Duration(milliseconds: 100));
        }
        expect(find.text('Kentucky statewide prize tables'), findsOneWidget);
        expect(
          find.text('Reported winners by tier • Not retailer map counts'),
          findsOneWidget,
        );
        expect(find.byType(DropdownButton<int>), findsOneWidget);
        final sourceLink = find.text('Open official draw report');
        await tester.ensureVisible(sourceLink);
        await tester.pump();
        expect(sourceLink.hitTestable(), findsOneWidget);
        await tester.tap(find.byTooltip('Close prize tables'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('Kentucky statewide prize tables'), findsNothing);
        expect(find.text('DRAWINGS IN KENTUCKY'), findsOneWidget);
        await tester.tap(find.text('DRAWINGS IN KENTUCKY'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 1));
        await tester.tap(find.byIcon(Icons.calendar_month_rounded));
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Switch to input'));
        await tester.pumpAndSettle();
        await tester.enterText(find.byType(TextField), '08/31/2026');
        await tester.tap(find.text('OK'));
        await tester.pump();
        await tester.pump(const Duration(seconds: 2));
        expect(find.byType(DatePickerDialog), findsNothing);
        expect(
          MapRankingService.snapshot.value.records.map((row) => row.id),
          contains('ky-current-2026-08-31-amexpress9-bowlinggreen-35'),
        );
        final stateSnapshot = MapRankingService.snapshot.value;
        final stateCounties = MapRankingService.rankings(stateSnapshot);
        expect(stateCounties.length, greaterThan(1));
        MapFocusService.focusCounty(
          stateName: 'Kentucky',
          countyId: stateSnapshot.countyIds['warren']!,
        );
        await tester.pumpAndSettle();
        expect(MapRankingService.snapshot.value.countyName, 'Warren');
        final warrenCities = MapRankingService.rankings(
          MapRankingService.snapshot.value,
        );
        expect(warrenCities, hasLength(1));
        expect(warrenCities.single.label, 'Bowling Green');
        expect(warrenCities.single.records, 1);
        await tester.tap(find.byTooltip('Back to state map'));
        await tester.pumpAndSettle();
        expect(MapRankingService.snapshot.value.countyName, isNull);
        expect(
          MapRankingService.rankings(MapRankingService.snapshot.value).length,
          stateCounties.length,
        );
        MapFocusService.focusCounty(
          stateName: 'Kentucky',
          countyId: stateSnapshot.countyIds['adair']!,
        );
        await tester.pumpAndSettle();
        expect(MapRankingService.snapshot.value.countyName, 'Adair');
        expect(
          MapRankingService.rankings(MapRankingService.snapshot.value),
          isEmpty,
        );
        final emptyScope = find.text(
          'No verified activity matches the current map and timeline filters.',
        );
        final homeScroll = tester
            .state<ScrollableState>(find.byType(Scrollable).first)
            .position;
        homeScroll.jumpTo(homeScroll.maxScrollExtent);
        await tester.pumpAndSettle();
        expect(emptyScope.hitTestable(), findsOneWidget);
        // Return the home scroll view to the map before operating its controls.
        homeScroll.jumpTo(0);
        await tester.pumpAndSettle();
        await tester.tap(find.byTooltip('Back to state map'));
        await tester.pumpAndSettle();
        expect(MapRankingService.snapshot.value.countyName, isNull);
        MapFocusService.focusRetailer(
          stateName: 'Kentucky',
          retailerId: 'ky-current-2026-08-31-amexpress9-bowlinggreen-35',
        );
        await tester.pumpAndSettle();
        final noticeDate = find.text('NOTICE DATE');
        await tester.ensureVisible(noticeDate);
        expect(noticeDate.hitTestable(), findsOneWidget);
        final source = find
            .text('Official Kentucky Lottery Have You Heard? · Aug 31, 2026')
            .last;
        await tester.ensureVisible(source);
        expect(source.hitTestable(), findsOneWidget);
        await tester.tapAt(const Offset(10, 10));
        await tester.pumpAndSettle();
        expect(
          tester.getRect(find.byTooltip('Zoom out')).bottom,
          lessThan(
            tester.getRect(find.byIcon(Icons.calendar_month_rounded)).top,
          ),
        );
        await tester.tap(find.byTooltip('Return timeline to now'));
        await tester.pumpAndSettle();
        expect(
          MapRankingService.snapshot.value.records.map((row) => row.id),
          isNot(contains('ky-current-2026-08-31-amexpress9-bowlinggreen-35')),
        );
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
        await tester.pump();
      },
    );
  }
}
