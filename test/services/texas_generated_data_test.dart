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
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    await LotteryActivityFeedService.loadConfiguredFeed(
      client: MockClient((_) async => http.Response('offline', 503)),
    );
    final texas = LotteryActivityRepository.activity
        .where((row) => row.state == 'TX')
        .toList();
    expect(texas.length, greaterThanOrEqualTo(100));
  });
}
