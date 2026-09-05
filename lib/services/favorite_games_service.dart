import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/favorite_lottery_game.dart';

/// Stores a compact list of games a player wants to reach quickly.
class FavoriteGamesService {
  FavoriteGamesService._();

  static const _storageKey = 'lottery_atlas.favorite_games.v1';
  static final SharedPreferencesAsync _store = SharedPreferencesAsync();
  static final ValueNotifier<List<FavoriteLotteryGame>> games = ValueNotifier(
    const <FavoriteLotteryGame>[],
  );

  static bool _didLoad = false;

  static Future<void> load() async {
    if (_didLoad) return;
    final saved = await _store.getStringList(_storageKey) ?? const <String>[];
    final byKey = <String, FavoriteLotteryGame>{};
    for (final raw in saved) {
      try {
        final game = FavoriteLotteryGame.decode(raw);
        byKey[game.key] = game;
      } on FormatException {
        // A single old or malformed saved entry cannot block Favorites.
      }
    }
    games.value = byKey.values.toList()
      ..sort((a, b) => a.name.compareTo(b.name));
    _didLoad = true;
  }

  static bool contains(String key) => games.value.any((game) => game.key == key);

  /// Returns true when the game is now saved, false when it was removed.
  static Future<bool> toggle(FavoriteLotteryGame game) async {
    await load();
    final updated = List<FavoriteLotteryGame>.from(games.value);
    final existingIndex = updated.indexWhere((item) => item.key == game.key);
    final isSaved = existingIndex < 0;
    if (isSaved) {
      updated.add(game);
    } else {
      updated.removeAt(existingIndex);
    }
    updated.sort((a, b) => a.name.compareTo(b.name));
    games.value = List.unmodifiable(updated);
    await _store.setStringList(
      _storageKey,
      updated.map((item) => item.encode()).toList(growable: false),
    );
    return isSaved;
  }

  static Future<void> remove(String key) async {
    await load();
    final updated = games.value.where((game) => game.key != key).toList();
    games.value = List.unmodifiable(updated);
    await _store.setStringList(
      _storageKey,
      updated.map((item) => item.encode()).toList(growable: false),
    );
  }
}
