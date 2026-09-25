import 'dart:convert';
import 'dart:io';
import 'package:lottery_atlas/models/lottery_activity.dart';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lottery_atlas/services/state_scratch_catalog_feed_service.dart';
import 'package:lottery_atlas/services/state_scratch_catalog_registry.dart';
import 'package:lottery_atlas/services/state_retailer_directory_feed_service.dart';
import 'package:lottery_atlas/services/state_retailer_directory_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:lottery_atlas/services/lottery_activity_feed_service.dart';
import 'package:lottery_atlas/services/lottery_activity_repository.dart';
import 'package:lottery_atlas/services/lottery_schedule_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Map<String, dynamic> _read(String path) =>
    Map<String, dynamic>.from(jsonDecode(File(path).readAsStringSync()) as Map);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  setUp(() async => SharedPreferencesAsync().clear());

  test('Texas live Scratch catalog is complete', () {
    final catalog = Map<String, dynamic>.from(
      (_read('data/texas_scratch_catalog.generated.json')['catalogs'] as List)
              .single
          as Map,
    );
    final games = (catalog['games'] as List).cast<Map>();
    expect(catalog['state'], 'Texas');
    expect(games.length, greaterThanOrEqualTo(70));
    expect(games.map((game) => game['id']).toSet(), hasLength(games.length));
    for (final game in games) {
      expect(game['cost'] as num, greaterThan(0));
      expect(game['topPrize'] as num, greaterThan(0));
      expect(game['topPrizesRemaining'] as num, greaterThanOrEqualTo(0));
    }
  });

  test('Texas statewide directory has verified address coordinates', () {
    final directory = Map<String, dynamic>.from(
      (_read('data/texas_retailer_directory.generated.json')['directories']
                  as List)
              .single
          as Map,
    );
    final retailers = (directory['retailers'] as List).cast<Map>();
    expect(directory['state'], 'Texas');
    expect(retailers.length, greaterThanOrEqualTo(10000));
    expect(
      retailers.map((row) => row['id']).toSet(),
      hasLength(retailers.length),
    );
    expect(
      retailers.map((row) => row['county']).toSet().length,
      greaterThanOrEqualTo(240),
    );
    for (final retailer in retailers) {
      expect(retailer['address'].toString(), isNotEmpty);
      expect(retailer['latitude'] as num, inInclusiveRange(25.7, 36.6));
      expect(retailer['longitude'] as num, inInclusiveRange(-106.7, -93.4));
      expect(retailer['coordinateSource'].toString(), isNotEmpty);
    }
  });

  test('Texas current recurring state draw menu is complete', () {
    final names = LotteryScheduleService.stateDrawsFor(
      'Texas',
    ).map((draw) => draw.name).toSet();
    expect(
      names,
      containsAll(<String>{
        'Lotto Texas',
        'Texas Two Step',
        'Cash Five',
        'Pick 3 · Morning',
        'Pick 3 · Day',
        'Pick 3 · Evening',
        'Pick 3 · Night',
        'Daily 4 · Morning',
        'Daily 4 · Day',
        'Daily 4 · Evening',
        'Daily 4 · Night',
        'All or Nothing · Morning',
        'All or Nothing · Day',
        'All or Nothing · Evening',
        'All or Nothing · Night',
      }),
    );
  });

  test('legacy Texas ticket IDs migrate to stable opaque IDs', () {
    const legacy = 'tx-2026-01-01-test-retailer-pack-ticket';
    const expected =
        'tx-claim-d666175dff415436be1c80b7651b27f1f295f8f7038b58af3f6656a66fdcd595';
    expect(LotteryActivity.normalizeRecordId(legacy), expected);
    expect(LotteryActivity.normalizeRecordId(expected), expected);
    expect(
      LotteryActivity.normalizeRecordId('tx-draw-example'),
      'tx-draw-example',
    );
  });

  test('Texas activity contains exact official 2026 retailer winners', () {
    final records =
        (_read('data/texas_winner_activity.generated.json')['activities']
                as List)
            .cast<Map>();
    expect(records.length, greaterThanOrEqualTo(100));
    expect(
      records
          .map((row) => DateTime.parse(row['drawDate'] as String).month)
          .toSet()
          .length,
      greaterThanOrEqualTo(6),
    );
    for (final record in records) {
      expect(record['state'], 'TX');
      expect(record['id'], matches(RegExp(r'^tx-claim-[0-9a-f]{64}$')));
      expect(record['sourceLabel'], contains('report as of'));
      expect(record['game'], 'scratch-off');
      expect(record['retailerName'].toString(), isNotEmpty);
      expect(record['retailerAddress'].toString(), isNotEmpty);
      expect(
        record['sourceUrl'].toString(),
        startsWith('https://www.texaslottery.com/'),
      );
      expect(record['prizeAmount'] as num, greaterThan(0));
    }
  });

  test('Texas heat activity is bundled for offline use', () async {
    await LotteryActivityFeedService.loadConfiguredFeed(
      client: MockClient((_) async => http.Response('offline', 503)),
    );
    final texas = LotteryActivityRepository.activity
        .where((row) => row.state == 'TX')
        .toList();
    expect(texas.length, greaterThanOrEqualTo(100));
    expect(texas.any((r) => r.gameName == 'Powerball'), isTrue);
    expect(texas.any((r) => r.gameName == 'Mega Millions'), isTrue);
    for (final game in [
      'Lotto Texas',
      'Texas Two Step',
      'Cash Five',
      'All or Nothing',
    ]) {
      expect(texas.any((r) => r.gameName == game), isTrue, reason: game);
    }
  });
  test(
    'Texas downloaded claims survive offline reload and reconnect unchanged',
    () async {
      final original =
          (_read('data/texas_winner_activity.generated.json')['activities']
                      as List)
                  .first
              as Map;
      final record = Map<String, dynamic>.from(original)
        ..['id'] = 'texas-cache-regression';
      final remote = jsonEncode({
        'source': 'Texas offline regression fixture',
        'updatedAt': '2026-09-24T00:00:00Z',
        'sourceLastUpdated': '2026-09-23T00:00:00Z',
        'activities': [record],
      });
      await LotteryActivityFeedService.loadConfiguredFeed(
        client: MockClient((_) async => http.Response(remote, 200)),
      );
      final before = LotteryActivityRepository.activity
          .map((r) => r.toJson())
          .toList();
      final updated = LotteryActivityRepository.activityUpdatedAt;
      final sourceUpdated = LotteryActivityRepository.activitySourceLastUpdated;
      expect(before.any((r) => r['id'] == 'texas-cache-regression'), isTrue);
      await LotteryActivityFeedService.loadConfiguredFeed(
        client: MockClient((_) async => http.Response('offline', 503)),
      );
      expect(
        LotteryActivityRepository.activity.map((r) => r.toJson()).toList(),
        before,
      );
      expect(LotteryActivityRepository.isCachedActivityData, isTrue);
      expect(LotteryActivityRepository.activityUpdatedAt, updated);
      expect(
        LotteryActivityRepository.activitySourceLastUpdated,
        sourceUpdated,
      );
      await LotteryActivityFeedService.loadConfiguredFeed(
        client: MockClient((_) async => http.Response(remote, 200)),
      );
      expect(
        LotteryActivityRepository.activity.map((r) => r.toJson()).toList(),
        before,
      );
      expect(LotteryActivityRepository.isCachedActivityData, isFalse);
      expect(LotteryActivityRepository.activityUpdatedAt, updated);
      expect(
        LotteryActivityRepository.activitySourceLastUpdated,
        sourceUpdated,
      );
    },
  );
  test(
    'Texas catalog and directory load offline without creating claims',
    () async {
      final claimsBefore = LotteryActivityRepository.activity
          .map((r) => r.toJson())
          .toList();
      final offline = MockClient((_) async => http.Response('offline', 503));
      await StateScratchCatalogFeedService.loadConfiguredFeed(client: offline);
      await StateRetailerDirectoryFeedService.loadBundledDirectories(
        client: offline,
      );
      final catalog =
          (_read('data/texas_scratch_catalog.generated.json')['catalogs']
                      as List)
                  .single
              as Map;
      expect(
        StateScratchCatalogRegistry.gamesFor('Texas').length,
        (catalog['games'] as List).length,
      );
      final directory =
          (_read('data/texas_retailer_directory.generated.json')['directories']
                      as List)
                  .single
              as Map;
      expect(
        StateRetailerDirectoryRepository.countFor('Texas'),
        (directory['retailers'] as List).length,
      );
      expect(
        StateRetailerDirectoryRepository.sourceFor('Texas'),
        directory['source'],
      );
      expect(
        LotteryActivityRepository.activity.map((r) => r.toJson()).toList(),
        claimsBefore,
      );
    },
  );

  test(
    'Texas cached catalog retains source timestamp across offline and reconnect',
    () async {
      final feed = _read('data/texas_scratch_catalog.generated.json');
      final catalog = (feed['catalogs'] as List).single as Map;
      // Future fixture freshness isolates the cache from moving bundle dates.
      catalog['timestampScope'] = 'state';
      catalog['updatedAt'] = '2099-01-01T00:00:00Z';
      (catalog['games'] as List).removeLast();
      final remote = jsonEncode(feed);
      await StateScratchCatalogFeedService.loadConfiguredFeed(
        client: MockClient((_) async => http.Response(remote, 200)),
      );
      final before = StateScratchCatalogRegistry.gamesFor(
        'Texas',
      ).map((g) => g.toJson()).toList();
      Future<dynamic> cachedTexas() async {
        final saved = await SharedPreferencesAsync().getString(
          'lottery_atlas.state_scratch_catalogs.v1',
        );
        return (jsonDecode(saved!)['catalogs'] as List).singleWhere(
          (c) => c['state'] == 'Texas',
        );
      }

      final savedBefore = await cachedTexas();
      await StateScratchCatalogFeedService.loadConfiguredFeed(
        client: MockClient((_) async => http.Response('offline', 503)),
      );
      expect(
        StateScratchCatalogRegistry.gamesFor(
          'Texas',
        ).map((g) => g.toJson()).toList(),
        before,
      );
      expect(await cachedTexas(), savedBefore);
      await StateScratchCatalogFeedService.loadConfiguredFeed(
        client: MockClient((_) async => http.Response(remote, 200)),
      );
      expect(await cachedTexas(), savedBefore);
    },
  );
}
