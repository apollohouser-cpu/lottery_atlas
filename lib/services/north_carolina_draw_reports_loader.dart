import 'north_carolina_draw_reports_validator.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NorthCarolinaDrawReportsLoader {
  NorthCarolinaDrawReportsLoader({
    this.readCache,
    this.writeCache,
    this.fetchRemote,
    this.readBundle,
  });
  static const cacheKey = 'north_carolina_draw_reports_v1';
  final Future<String?> Function()? readCache;
  final Future<void> Function(String)? writeCache;
  final Future<String> Function()? fetchRemote;
  final Future<String> Function()? readBundle;

  Map<String, dynamic> _decode(String raw) =>
      NorthCarolinaDrawReportsValidator.decode(raw);
  void _checkContinuity(Map<String, dynamic> old, Map<String, dynamic> next) =>
      NorthCarolinaDrawReportsValidator.continuity(old, next);

  Future<Map<String, dynamic>> load() async {
    late final prefs = SharedPreferencesAsync();
    Map<String, dynamic>? cached;
    try {
      final raw = await (readCache?.call() ?? prefs.getString(cacheKey));
      if (raw != null) cached = _decode(raw);
    } catch (_) {}
    if (cached == null) {
      try {
        cached = _decode(
          await (readBundle?.call() ??
              rootBundle.loadString(
                'data/north_carolina_draw_reports.generated.json',
              )),
        );
      } catch (_) {}
    }
    try {
      final raw = await (fetchRemote?.call() ?? _fetch()).timeout(
        const Duration(seconds: 8),
      );
      final data = _decode(raw);
      if (cached != null) _checkContinuity(cached, data);
      // Persistence failure must not discard a valid response.
      try {
        if (writeCache != null) {
          await writeCache!(raw);
        } else {
          await prefs.setString(cacheKey, raw);
        }
      } catch (_) {}
      return data;
    } catch (_) {}
    return cached ??
        _decode(
          await (readBundle?.call() ??
              rootBundle.loadString(
                'data/north_carolina_draw_reports.generated.json',
              )),
        );
  }

  Future<String> _fetch() async {
    final response = await http.get(
      Uri.parse(
        'https://apollohouser-cpu.github.io/lottery_atlas/north_carolina_draw_reports.json',
      ),
    );
    if (response.statusCode != 200) {
      throw StateError('Catalog HTTP ${response.statusCode}');
    }
    return response.body;
  }
}
