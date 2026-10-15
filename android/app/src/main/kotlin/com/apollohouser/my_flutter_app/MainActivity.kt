package com.apollohouser.my_flutter_app

import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterActivity() {
    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "lottery_atlas/magic_mouse")
            .setMethodCallHandler { call, result ->
                // Shared navigation toggles macOS mouse handling. Android needs
                // no native mouse-mode change when entering or leaving the map.
                if (call.method == "setMapActive") {
                    result.success(null)
                } else {
                    result.notImplemented()
                }
            }
    }
}
