import 'dart:ui' show PointerDeviceKind;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/main.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  testWidgets('Leaving map releases wheel input for the home ranking', (
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
    await tester.binding.setSurfaceSize(const Size(1280, 900));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const LotteryAtlasApp());
    await tester.pump(const Duration(seconds: 2));
    final mouse = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await mouse.addPointer(location: Offset.zero);
    await mouse.moveTo(const Offset(400, 350));
    await tester.pump();
    expect(activeCalls.last, isTrue);
    await mouse.moveTo(tester.getCenter(find.text('TIMELINE')));
    await tester.pump();
    expect(activeCalls.last, isFalse);
    await mouse.moveTo(const Offset(400, 350));
    await tester.pump();
    expect(activeCalls.last, isTrue);
    await mouse.moveTo(const Offset(600, 780));
    await tester.pump();
    expect(activeCalls.last, isFalse);
    await mouse.moveTo(const Offset(400, 350));
    await tester.pump();
    expect(activeCalls.last, isTrue);
    await mouse.removePointer();
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
