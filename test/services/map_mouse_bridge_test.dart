import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/map_mouse_bridge.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  tearDown(() => debugDefaultTargetPlatformOverride = null);
  for (final platform in [TargetPlatform.iOS, TargetPlatform.android]) {
    test('$platform map actions need no desktop plugin', () async {
      debugDefaultTargetPlatformOverride = platform;
      // No mock handler: calling the desktop channel would throw.
      await MapMouseBridge.setMapActive(false);
      await MapMouseBridge.setMapActive(true);
    });
  }
  test('macOS still suspends and restores native scroll handling', () async {
    debugDefaultTargetPlatformOverride = TargetPlatform.macOS;
    final calls = <Object?>[];
    const channel = MethodChannel('lottery_atlas/magic_mouse');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          expect(call.method, 'setMapActive');
          calls.add(call.arguments);
          return null;
        });
    addTearDown(
      () => TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null),
    );
    await MapMouseBridge.setMapActive(false);
    await MapMouseBridge.setMapActive(true);
    expect(calls, [false, true]);
  });
}
