import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Coordinates the macOS scroll bridge without blocking mobile map actions.
class MapMouseBridge {
  static Future<void> setMapActive(bool active) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.macOS) return;
    await const MethodChannel(
      'lottery_atlas/magic_mouse',
    ).invokeMethod<void>('setMapActive', active);
  }
}
