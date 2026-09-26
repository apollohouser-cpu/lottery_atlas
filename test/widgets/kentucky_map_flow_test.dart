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
  testWidgets(
    'Kentucky offline map exposes covered notice dates, details and reset',
    (tester) async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
        const MethodChannel('lottery_atlas/magic_mouse'),
        (_) async => null,
      );
      await tester.binding.setSurfaceSize(const Size(800, 632));
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
        lessThan(tester.getRect(find.byIcon(Icons.calendar_month_rounded)).top),
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
