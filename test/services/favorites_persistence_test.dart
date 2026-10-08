import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';
import 'package:lottery_atlas/models/favorite_lottery_game.dart';
import 'package:lottery_atlas/models/favorite_place.dart';
import 'package:lottery_atlas/services/favorite_games_service.dart';
import 'package:lottery_atlas/services/favorite_places_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'game favorites recover valid entries and persist independent removal',
    () async {
      const key = 'lottery_atlas.favorite_games.v1';
      const game = FavoriteLotteryGame(
        key: 'test:powerball',
        gameId: 'powerball',
        name: 'Powerball',
        subtitle: 'Synthetic test',
        kind: FavoriteLotteryGameKind.nationalDraw,
      );
      const other = FavoriteLotteryGame(
        key: 'test:state-draw',
        gameId: 'test-draw',
        name: 'Synthetic draw',
        subtitle: 'Synthetic test',
        kind: FavoriteLotteryGameKind.stateDraw,
      );
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            key: ['invalid json', game.encode(), '{}', game.encode()],
          });
      final reader = SharedPreferencesAsync();
      await FavoriteGamesService.load();
      expect(FavoriteGamesService.games.value.map((g) => g.key), [game.key]);
      expect(await FavoriteGamesService.toggle(other), isTrue);
      final persisted = (await reader.getStringList(
        key,
      ))!.map(FavoriteLotteryGame.decode).toList();
      expect(persisted.map((g) => g.key).toSet(), {game.key, other.key});
      expect(persisted.first.kind, FavoriteLotteryGameKind.nationalDraw);
      await FavoriteGamesService.remove(game.key);
      expect(
        (await reader.getStringList(
          key,
        ))!.map(FavoriteLotteryGame.decode).single.key,
        other.key,
      );
      expect(await FavoriteGamesService.toggle(other), isFalse);
      expect(await reader.getStringList(key), isEmpty);
      expect(FavoriteGamesService.games.value, isEmpty);
    },
  );

  test(
    'place favorites preserve destination and remove only selected key',
    () async {
      const key = 'lottery_atlas.favorite_places.v1';
      const state = FavoritePlace(
        key: 'test:state',
        title: 'South Carolina',
        subtitle: 'Synthetic state favorite',
        kind: FavoritePlaceKind.state,
        stateName: 'South Carolina',
      );
      const county = FavoritePlace(
        key: 'test:county',
        title: 'Synthetic county',
        subtitle: 'Synthetic county favorite',
        kind: FavoritePlaceKind.county,
        stateName: 'South Carolina',
        countyId: 'test-county',
      );
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.withData({
            key: ['[]', state.encode(), '{broken', state.encode()],
          });
      final reader = SharedPreferencesAsync();
      await FavoritePlacesService.load();
      expect(FavoritePlacesService.places.value.map((p) => p.key), [state.key]);
      expect(await FavoritePlacesService.toggle(county), isTrue);
      final persisted = (await reader.getStringList(
        key,
      ))!.map(FavoritePlace.decode).toList();
      expect(persisted.map((p) => p.key), [state.key, county.key]);
      expect(persisted.last.countyId, 'test-county');
      expect(persisted.last.stateName, 'South Carolina');
      await FavoritePlacesService.remove(state.key);
      expect(
        (await reader.getStringList(key))!.map(FavoritePlace.decode).single.key,
        county.key,
      );
      expect(await FavoritePlacesService.toggle(county), isFalse);
      expect(await reader.getStringList(key), isEmpty);
      expect(FavoritePlacesService.places.value, isEmpty);
    },
  );
}
