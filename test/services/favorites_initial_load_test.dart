import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:lottery_atlas/models/favorite_lottery_game.dart';
import 'package:lottery_atlas/models/favorite_place.dart';
import 'package:lottery_atlas/services/favorite_games_service.dart';
import 'package:lottery_atlas/services/favorite_places_service.dart';

final class DelayedReadStore extends InMemorySharedPreferencesAsync {
  DelayedReadStore() : super.empty();
  final release = Completer<void>();
  final reads = <String, int>{};

  @override
  Future<List<String>?> getStringList(
    String key,
    SharedPreferencesOptions options,
  ) async {
    final saved = await super.getStringList(key, options);
    reads[key] = (reads[key] ?? 0) + 1;
    if (reads[key] == 1) await release.future;
    return saved;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'startup loads cannot overwrite concurrent favorite additions',
    () async {
      final store = DelayedReadStore();
      SharedPreferencesAsyncPlatform.instance = store;
      const game = FavoriteLotteryGame(
        key: 'test:game',
        gameId: 'powerball',
        name: 'Synthetic game',
        subtitle: 'Test',
        kind: FavoriteLotteryGameKind.nationalDraw,
      );
      const place = FavoritePlace(
        key: 'test:place',
        title: 'Synthetic state',
        subtitle: 'Test',
        kind: FavoritePlaceKind.state,
        stateName: 'Montana',
      );
      final loads = [FavoriteGamesService.load(), FavoritePlacesService.load()];
      await Future<void>.delayed(Duration.zero);
      final changes = [
        FavoriteGamesService.toggle(game),
        FavoritePlacesService.toggle(place),
      ];
      await Future<void>.delayed(Duration.zero);
      store.release.complete();
      await Future.wait(loads);
      expect(await Future.wait(changes), [true, true]);
      expect(FavoriteGamesService.contains(game.key), isTrue);
      expect(FavoritePlacesService.contains(place.key), isTrue);
      final reader = SharedPreferencesAsync();
      expect(await reader.getStringList('lottery_atlas.favorite_games.v1'), [
        game.encode(),
      ]);
      expect(await reader.getStringList('lottery_atlas.favorite_places.v1'), [
        place.encode(),
      ]);
    },
  );
}
