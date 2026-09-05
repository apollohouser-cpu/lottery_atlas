import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/favorite_place.dart';

class FavoritePlacesService {
  FavoritePlacesService._();

  static const _storageKey = 'lottery_atlas.favorite_places.v1';
  static final SharedPreferencesAsync _store = SharedPreferencesAsync();
  static final ValueNotifier<List<FavoritePlace>> places = ValueNotifier(
    const <FavoritePlace>[],
  );

  static bool _didLoad = false;

  static Future<void> load() async {
    if (_didLoad) return;
    final saved = await _store.getStringList(_storageKey) ?? const <String>[];
    final byKey = <String, FavoritePlace>{};
    for (final raw in saved) {
      try {
        final place = FavoritePlace.decode(raw);
        byKey[place.key] = place;
      } on FormatException {
        // An old malformed favorite cannot block the rest of the list.
      }
    }
    places.value = _sorted(byKey.values);
    _didLoad = true;
  }

  static bool contains(String key) => places.value.any((place) => place.key == key);

  /// Returns true when the place is now saved, false when it was removed.
  static Future<bool> toggle(FavoritePlace place) async {
    await load();
    final updated = List<FavoritePlace>.from(places.value);
    final existingIndex = updated.indexWhere((item) => item.key == place.key);
    final isSaved = existingIndex < 0;
    if (isSaved) {
      updated.add(place);
    } else {
      updated.removeAt(existingIndex);
    }
    await _persist(updated);
    return isSaved;
  }

  static Future<void> remove(String key) async {
    await load();
    await _persist(places.value.where((place) => place.key != key));
  }

  static List<FavoritePlace> _sorted(Iterable<FavoritePlace> values) {
    final sorted = values.toList()
      ..sort((a, b) {
        final kindOrder = a.kind.index.compareTo(b.kind.index);
        return kindOrder != 0 ? kindOrder : a.title.compareTo(b.title);
      });
    return List.unmodifiable(sorted);
  }

  static Future<void> _persist(Iterable<FavoritePlace> values) async {
    final sorted = _sorted(values);
    places.value = sorted;
    await _store.setStringList(
      _storageKey,
      sorted.map((place) => place.encode()).toList(growable: false),
    );
  }
}
