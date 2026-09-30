import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/main.dart';
import 'package:lottery_atlas/services/map_focus_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('Leaving drawings panel cannot capture scroll behind a report', (
    tester,
  ) async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    final activeCalls = <bool>[];
    tester.binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('lottery_atlas/magic_mouse'),
      (call) async {
        if (call.method == 'setMapActive') {
          activeCalls.add(call.arguments as bool);
        }
        return null;
      },
    );
    await tester.binding.setSurfaceSize(const Size(800, 632));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const LotteryAtlasApp());
    for (var i = 0; i < 30; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    MapFocusService.focusState('Kentucky');
    await tester.pump();
    await tester.pump(const Duration(seconds: 2));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(tester.getCenter(find.text('DRAWINGS IN KENTUCKY')));
    await tester.tap(find.text('DRAWINGS IN KENTUCKY'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await mouse.moveTo(tester.getCenter(find.text('Statewide prize tables')));
    await tester.tap(find.text('Statewide prize tables'));
    for (var i = 0; i < 10; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 100)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
    await mouse.moveTo(const Offset(780, 600));
    await tester.pump();
    expect(find.text('Kentucky statewide prize tables'), findsOneWidget);
    expect(activeCalls.last, isFalse);
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
