import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/main.dart';
import 'package:lottery_atlas/services/map_focus_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets(
    'Kentucky map loads bundled data and opens its controls offline',
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
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();
    },
  );
}
