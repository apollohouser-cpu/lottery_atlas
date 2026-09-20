import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lottery_atlas/services/state_scratch_catalog_feed_service.dart';
import 'package:lottery_atlas/services/state_scratch_catalog_registry.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  setUp(() async {
    await SharedPreferencesAsync().clear();
  });

  String feed({String date = '2099-01-01T00:00:00Z'}) => jsonEncode({
    'updatedAt': date,
    'catalogs': [
      {
        'state': 'Wisconsin',
        'source': 'https://www.wilottery.com/games/instant-games/scratch-games',
        'games': [
          {
            'id': 'test-current',
            'name': 'Updated official catalog',
            'cost': 5,
            'topPrize': 50000,
            'topPrizeLabel': r'$50,000 instant prize',
            'inventoryNote':
                'Remaining count unavailable; verification date unpublished.',
          },
        ],
      },
    ],
  });

  test(
    'published catalog preserves Wisconsin unknown counts and Washington labels',
    () async {
      final raw = File('docs/state_scratch_catalogs.json').readAsStringSync();
      await StateScratchCatalogFeedService.loadConfiguredFeed(
        client: MockClient((_) async => http.Response(raw, 200)),
      );
      final wi = StateScratchCatalogRegistry.gamesFor('Wisconsin');
      expect(wi, isNotEmpty);
      expect(wi.where((g) => g.topPrizesRemaining == null), isNotEmpty);
      expect(
        wi.every(
          (g) =>
              g.inventoryNote?.contains('verification date unpublished') ??
              false,
        ),
        isTrue,
      );
      final wa = StateScratchCatalogRegistry.gamesFor('Washington');
      expect(
        wa.firstWhere((g) => g.id == '1780').topPrizeLabel,
        r'$40,000/yr/25 years',
      );
      expect(wa.firstWhere((g) => g.id == '2004').topPrizeLabel, 'BRONCO');
    },
  );

  test('Kansas inventory is available offline with coverage caveats', () async {
    await StateScratchCatalogFeedService.loadConfiguredFeed(
      client: MockClient((_) async => http.Response('offline', 503)),
    );
    final games = StateScratchCatalogRegistry.gamesFor('Kansas');
    expect(games, hasLength(45));
    expect(games.every((g) => g.topPrizesRemaining != null), isTrue);
    expect(
      games.every(
        (g) => g.inventoryNote?.contains('launch dates conflict') ?? false,
      ),
      isTrue,
    );
  });

  test(
    'Nebraska offline inventory preserves dated and unknown counts',
    () async {
      await StateScratchCatalogFeedService.loadConfiguredFeed(
        client: MockClient((_) async => http.Response('offline', 503)),
      );
      final games = StateScratchCatalogRegistry.gamesFor('Nebraska');
      expect(games, hasLength(25));
      expect(
        games.firstWhere((g) => g.id == '1344').topPrizesRemaining,
        isNull,
      );
      final dated = games.firstWhere((g) => g.id == '1335');
      expect(dated.topPrizesRemaining, 10);
      expect(dated.inventoryNote, contains('2026-09-13'));
    },
  );

  test('South Dakota offline catalog discloses subset coverage', () async {
    await StateScratchCatalogFeedService.loadConfiguredFeed(
      client: MockClient((_) async => http.Response('offline', 503)),
    );
    final games = StateScratchCatalogRegistry.gamesFor('South Dakota');
    expect(games, hasLength(32));
    expect(games.firstWhere((g) => g.id == '1197').topPrize, 75000);
    expect(
      games.every((g) => g.inventoryNote?.contains('subset') ?? false),
      isTrue,
    );
  });

  test(
    'New Mexico offline catalog excludes expired games and labels estimates',
    () async {
      await StateScratchCatalogFeedService.loadConfiguredFeed(
        client: MockClient((_) async => http.Response('offline', 503)),
      );
      final games = StateScratchCatalogRegistry.gamesFor('New Mexico');
      expect(games, hasLength(54));
      expect(games.where((g) => g.id == '639'), isEmpty);
      expect(
        games.firstWhere((g) => g.id == '581').inventoryNote,
        contains('redeem by 2026-11-19'),
      );
      expect(
        games.every((g) => g.inventoryNote?.contains('Estimated') ?? false),
        isTrue,
      );
    },
  );

  test('newer downloaded catalog survives an offline reload', () async {
    await StateScratchCatalogFeedService.loadConfiguredFeed(
      client: MockClient((_) async => http.Response(feed(), 200)),
    );
    await StateScratchCatalogFeedService.loadConfiguredFeed(
      client: MockClient((_) async => http.Response('offline', 503)),
    );
    final wi = StateScratchCatalogRegistry.gamesFor('Wisconsin');
    expect(wi.single.id, 'test-current');
    expect(wi.single.topPrizesRemaining, isNull);
    expect(wi.single.inventoryNote, contains('unavailable'));
  });

  test('older cached catalog cannot replace a newer bundled catalog', () async {
    await SharedPreferencesAsync().setString(
      'lottery_atlas.state_scratch_catalogs.v1',
      feed(date: '2000-01-01T00:00:00Z'),
    );
    await StateScratchCatalogFeedService.loadConfiguredFeed(
      client: MockClient((_) async => http.Response('offline', 503)),
    );
    expect(
      StateScratchCatalogRegistry.gamesFor(
        'Wisconsin',
      ).any((g) => g.id == 'test-current'),
      isFalse,
    );
  });

  test(
    'older network response cannot roll back a newer cached catalog',
    () async {
      await StateScratchCatalogFeedService.loadConfiguredFeed(
        client: MockClient((_) async => http.Response(feed(), 200)),
      );
      final old = File(
        'data/wisconsin_scratch_catalog.initial.json',
      ).readAsStringSync();
      await StateScratchCatalogFeedService.loadConfiguredFeed(
        client: MockClient((_) async => http.Response(old, 200)),
      );
      expect(
        StateScratchCatalogRegistry.gamesFor('Wisconsin').single.id,
        'test-current',
      );
    },
  );
}
