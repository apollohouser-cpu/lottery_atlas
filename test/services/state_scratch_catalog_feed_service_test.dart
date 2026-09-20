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
