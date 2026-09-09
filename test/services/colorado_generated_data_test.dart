import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:lottery_atlas/services/lottery_activity_feed_service.dart';
import 'package:lottery_atlas/services/lottery_activity_repository.dart';
import 'package:lottery_atlas/services/lottery_schedule_service.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

Map<String, dynamic> _read(String path) =>
    Map<String, dynamic>.from(jsonDecode(File(path).readAsStringSync()) as Map);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Colorado live Scratch catalog is complete', () {
    final catalog = Map<String, dynamic>.from(
      (_read('data/colorado_scratch_catalog.generated.json')['catalogs']
                  as List)
              .single
          as Map,
    );
    final games = (catalog['games'] as List).cast<Map>();
    expect(catalog['state'], 'Colorado');
    expect(games.length, greaterThanOrEqualTo(80));
    expect(games.map((game) => game['id']).toSet(), hasLength(games.length));
    for (final game in games) {
      expect(game['cost'] as num, greaterThan(0));
      expect(game['topPrize'] as num, greaterThan(0));
      expect(game['topPrizesRemaining'] as num, greaterThanOrEqualTo(0));
    }
  });

  test('Colorado directory covers all counties with official coordinates', () {
    final directory = Map<String, dynamic>.from(
      (_read('data/colorado_retailer_directory.generated.json')['directories']
                  as List)
              .single
          as Map,
    );
    final retailers = (directory['retailers'] as List).cast<Map>();
    expect(directory['state'], 'Colorado');
    expect(retailers.length, greaterThanOrEqualTo(2800));
    expect(
      retailers.map((row) => row['id']).toSet(),
      hasLength(retailers.length),
    );
    expect(retailers.map((row) => row['county']).toSet(), hasLength(64));
    for (final retailer in retailers) {
      expect(retailer['address'].toString(), isNotEmpty);
      expect(retailer['latitude'] as num, inInclusiveRange(36.9, 41.1));
      expect(retailer['longitude'] as num, inInclusiveRange(-109.1, -101.9));
      expect(
        retailer['coordinateSource'],
        'Colorado Lottery published retailer coordinate',
      );
    }
  });

  test('Colorado current recurring state draw menu is verified', () {
    final names = LotteryScheduleService.stateDrawsFor(
      'Colorado',
    ).map((draw) => draw.name).toSet();
    expect(
      names,
      containsAll(<String>{
        'Colorado Lotto+',
        'Cash 5',
        'Pick 3 · Midday',
        'Pick 3 · Evening',
      }),
    );
  });

  test('Colorado activity is exact retailer-verified throughout 2026', () {
    final records =
        (_read('data/colorado_winner_activity.generated.json')['activities']
                as List)
            .cast<Map>();
    final latest = records
        .map((row) => DateTime.parse(row['drawDate'] as String))
        .reduce((a, b) => a.isAfter(b) ? a : b);
    final months = records
        .map((row) => DateTime.parse(row['drawDate'] as String).month)
        .toSet();
    expect(records.length, greaterThanOrEqualTo(900));
    expect(
      months,
      containsAll(<int>[
        for (var month = 1; month <= latest.month; month++) month,
      ]),
    );
    expect(
      records.where((row) => row['game'] == 'scratch-off').length,
      greaterThanOrEqualTo(500),
    );
    for (final record in records) {
      expect(record['state'], 'CO');
      expect(record['retailerName'].toString(), isNotEmpty);
      expect(record['retailerAddress'].toString(), isNotEmpty);
      expect(
        record['sourceUrl'].toString(),
        startsWith('https://www.coloradolottery.com/'),
      );
      expect(record['prizeAmount'] as num, greaterThan(0));
    }
  });

  test('Colorado heat activity is bundled for offline use', () async {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await LotteryActivityFeedService.loadConfiguredFeed(
      client: MockClient((_) async => http.Response('offline', 503)),
    );
    final colorado = LotteryActivityRepository.activity
        .where((row) => row.state == 'CO')
        .toList();
    expect(colorado.length, greaterThanOrEqualTo(900));
    expect(colorado.map((row) => row.drawDate.month).toSet(), contains(9));
  });
}
