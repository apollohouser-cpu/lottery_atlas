import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:lottery_atlas/models/favorite_lottery_game.dart';
import 'package:lottery_atlas/models/favorite_place.dart';
import 'package:lottery_atlas/services/favorite_games_service.dart';
import 'package:lottery_atlas/services/favorite_places_service.dart';

final class FailingStore extends InMemorySharedPreferencesAsync {
  FailingStore() : super.empty();
  bool failWrites = false;
  @override
  Future<bool> setStringList(
    String key,
    List<String> value,
    SharedPreferencesOptions options,
  ) async {
    if (failWrites) throw StateError('Controlled storage failure');
    return super.setStringList(key, value, options);
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'failed favorite additions and removals preserve visible and stored data',
    () async {
      final store = FailingStore();
      SharedPreferencesAsyncPlatform.instance = store;
      final reader = SharedPreferencesAsync();
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
      await FavoriteGamesService.load();
      await FavoritePlacesService.load();
      var notifications = 0;
      void changed() => notifications++;
      FavoriteGamesService.games.addListener(changed);
      FavoritePlacesService.places.addListener(changed);
      addTearDown(() {
        FavoriteGamesService.games.removeListener(changed);
        FavoritePlacesService.places.removeListener(changed);
      });
      store.failWrites = true;
      await expectLater(FavoriteGamesService.toggle(game), throwsStateError);
      await expectLater(FavoritePlacesService.toggle(place), throwsStateError);
      expect(FavoriteGamesService.contains(game.key), isFalse);
      expect(FavoritePlacesService.contains(place.key), isFalse);
      expect(notifications, 0);
      store.failWrites = false;
      await FavoriteGamesService.toggle(game);
      await FavoritePlacesService.toggle(place);
      final games = await reader.getStringList(
        'lottery_atlas.favorite_games.v1',
      );
      final places = await reader.getStringList(
        'lottery_atlas.favorite_places.v1',
      );
      notifications = 0;
      store.failWrites = true;
      await expectLater(
        FavoriteGamesService.remove(game.key),
        throwsStateError,
      );
      await expectLater(
        FavoritePlacesService.remove(place.key),
        throwsStateError,
      );
      await expectLater(FavoriteGamesService.toggle(game), throwsStateError);
      await expectLater(FavoritePlacesService.toggle(place), throwsStateError);
      expect(FavoriteGamesService.contains(game.key), isTrue);
      expect(FavoritePlacesService.contains(place.key), isTrue);
      expect(notifications, 0);
      expect(
        await reader.getStringList('lottery_atlas.favorite_games.v1'),
        games,
      );
      expect(
        await reader.getStringList('lottery_atlas.favorite_places.v1'),
        places,
      );
      store.failWrites = false;
      await FavoriteGamesService.remove(game.key);
      await FavoritePlacesService.remove(place.key);
      expect(
        await Future.wait([
          FavoriteGamesService.toggle(game),
          FavoriteGamesService.toggle(game),
        ]),
        [true, false],
      );
      expect(
        await Future.wait([
          FavoritePlacesService.toggle(place),
          FavoritePlacesService.toggle(place),
        ]),
        [true, false],
      );
      expect(FavoriteGamesService.games.value, isEmpty);
      expect(FavoritePlacesService.places.value, isEmpty);
      expect(
        await reader.getStringList('lottery_atlas.favorite_games.v1'),
        isEmpty,
      );
      expect(
        await reader.getStringList('lottery_atlas.favorite_places.v1'),
        isEmpty,
      );
    },
  );
}
