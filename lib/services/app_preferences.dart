import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../widgets/map/map_detail_mode.dart';

/// Small, local preferences store for display choices that should survive an
/// app restart. It is deliberately separate from the future lottery data API.
class AppPreferences {
  AppPreferences._();

  static const _mapDetailModeKey = 'lottery_atlas.map_detail_mode';
  static const _showTimeZonesKey = 'lottery_atlas.show_time_zones';
  static const _homeStateKey = 'lottery_atlas.home_state';

  static final SharedPreferencesAsync _store = SharedPreferencesAsync();
  static final ValueNotifier<int> changes = ValueNotifier<int>(0);

  static Future<MapDetailMode> getMapDetailMode() async {
    final stored = await _store.getString(_mapDetailModeKey);
    return MapDetailMode.values.firstWhere(
      (mode) => mode.name == stored,
      orElse: () => MapDetailMode.standard,
    );
  }

  static Future<bool> getShowTimeZones() async {
    return await _store.getBool(_showTimeZonesKey) ?? false;
  }

  /// The user's optional preferred state. This is selected manually; Lottery
  /// Atlas does not request or store device location.
  static Future<String?> getHomeState() => _store.getString(_homeStateKey);

  static Future<void> setMapDetailMode(MapDetailMode mode) async {
    await _store.setString(_mapDetailModeKey, mode.name);
    _notifyChanged();
  }

  static Future<void> setShowTimeZones(bool showTimeZones) async {
    await _store.setBool(_showTimeZonesKey, showTimeZones);
    _notifyChanged();
  }

  static Future<void> setHomeState(String stateName) async {
    await _store.setString(_homeStateKey, stateName);
    _notifyChanged();
  }

  static Future<void> clearHomeState() async {
    await _store.remove(_homeStateKey);
    _notifyChanged();
  }

  static Future<void> resetMapPreferences() async {
    await _store.remove(_mapDetailModeKey);
    await _store.remove(_showTimeZonesKey);
    _notifyChanged();
  }

  static void _notifyChanged() {
    changes.value++;
  }
}
