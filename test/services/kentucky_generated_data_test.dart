import 'dart:convert';
import 'dart:io';

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
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Map<String, dynamic> _readObject(String path) {
  return Map<String, dynamic>.from(
    jsonDecode(File(path).readAsStringSync()) as Map,
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  SharedPreferencesAsyncPlatform.instance =
      InMemorySharedPreferencesAsync.empty();
  setUp(() async => SharedPreferencesAsync().clear());
  test('Kentucky generated Scratch-Off catalog is complete and valid', () {
    final root = _readObject('data/kentucky_scratch_catalog.generated.json');
    final catalog = Map<String, dynamic>.from(
      (root['catalogs'] as List).single as Map,
    );
    final games = (catalog['games'] as List)
        .map((game) => Map<String, dynamic>.from(game as Map))
        .toList(growable: false);

    expect(catalog['state'], 'Kentucky');
    expect(games.length, greaterThanOrEqualTo(70));
    expect(games.map((game) => game['id']).toSet(), hasLength(games.length));
    for (final game in games) {
      expect(game['name'].toString().trim(), isNotEmpty);
      expect(game['cost'] as num, greaterThan(0));
      expect(game['topPrize'] as num, greaterThan(0));
      if (game['topPrizesRemaining'] case final num remaining) {
        expect(remaining, greaterThanOrEqualTo(0));
      }
    }
  });

  test('Kentucky generated retailer directory retains all official rows', () {
    final root = _readObject('data/kentucky_retailer_directory.generated.json');
    final directory = Map<String, dynamic>.from(
      (root['directories'] as List).single as Map,
    );
    final retailers = (directory['retailers'] as List)
        .map((retailer) => Map<String, dynamic>.from(retailer as Map))
        .toList(growable: false);
    final unresolved = (directory['unresolvedRetailers'] as List)
        .map((retailer) => Map<String, dynamic>.from(retailer as Map))
        .toList(growable: false);

    expect(directory['state'], 'Kentucky');
    expect(retailers.length, greaterThanOrEqualTo(3300));
    expect(retailers.length + unresolved.length, greaterThanOrEqualTo(3400));
    expect(
      retailers.map((retailer) => retailer['id']).toSet(),
      hasLength(retailers.length),
    );
    for (final retailer in retailers) {
      expect(retailer['name'].toString().trim(), isNotEmpty);
      expect(retailer['address'].toString().trim(), isNotEmpty);
      expect(retailer['city'].toString().trim(), isNotEmpty);
      expect(retailer['county'].toString(), endsWith(' County'));
      expect(retailer['latitude'] as num, inInclusiveRange(36.0, 40.0));
      expect(retailer['longitude'] as num, inInclusiveRange(-90.0, -81.5));
      expect(retailer['coordinateSource'].toString().trim(), isNotEmpty);
    }
  });

  test('Kentucky activity has verified coverage in every year since 2024', () {
    final records = <Map<String, dynamic>>[];
    for (final path in <String>[
      'data/kentucky_historical_activity.generated.json',
      'data/kentucky_winner_activity.initial.json',
      'data/kentucky_current_winner_activity.generated.json',
    ]) {
      final root = _readObject(path);
      records.addAll(
        (root['activities'] as List).map(
          (record) => Map<String, dynamic>.from(record as Map),
        ),
      );
    }

    final years = records
        .map((record) => DateTime.parse(record['drawDate'] as String).year)
        .toSet();
    expect(years, containsAll(<int>{2024, 2025, 2026}));
    for (final record in records) {
      expect(record['state'], 'KY');
      expect(record['retailerName'].toString().trim(), isNotEmpty);
      expect(record['retailerAddress'].toString().trim(), isNotEmpty);
      expect(record['sourceUrl'].toString(), startsWith('https://'));
      expect(record['latitude'], isA<num>());
      expect(record['longitude'], isA<num>());
    }
  });
  test(
    'Kentucky downloaded notices survive offline reload and reconnect unchanged',
    () async {
      final original =
          (_readObject(
                        'data/kentucky_current_winner_activity.generated.json',
                      )['activities']
                      as List)
                  .first
              as Map;
      final record = Map<String, dynamic>.from(original)
        ..['id'] = 'kentucky-cache-regression';
      final remote = jsonEncode({
        'source': 'Kentucky offline regression fixture (test only)',
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
      expect(before.any((r) => r['id'] == 'kentucky-cache-regression'), isTrue);
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
    'Kentucky catalog and directory load offline without creating claims',
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
          (_readObject(
                        'data/kentucky_scratch_catalog.generated.json',
                      )['catalogs']
                      as List)
                  .single
              as Map;
      expect(
        StateScratchCatalogRegistry.gamesFor('Kentucky').length,
        (catalog['games'] as List).length,
      );
      final directory =
          (_readObject(
                        'data/kentucky_retailer_directory.generated.json',
                      )['directories']
                      as List)
                  .single
              as Map;
      expect(
        StateRetailerDirectoryRepository.countFor('Kentucky'),
        (directory['retailers'] as List).length,
      );
      expect(
        StateRetailerDirectoryRepository.sourceFor('Kentucky'),
        directory['source'],
      );
      expect(
        LotteryActivityRepository.activity.map((r) => r.toJson()).toList(),
        claimsBefore,
      );
    },
  );
}
