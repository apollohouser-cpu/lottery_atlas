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

Map<String, dynamic> _readObject(String path) =>
    Map<String, dynamic>.from(jsonDecode(File(path).readAsStringSync()) as Map);

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('New York generated Scratch-Off catalog is complete and valid', () {
    final root = _readObject('data/new_york_scratch_catalog.generated.json');
    final catalog = Map<String, dynamic>.from(
      (root['catalogs'] as List).single as Map,
    );
    final games = (catalog['games'] as List)
        .map((game) => Map<String, dynamic>.from(game as Map))
        .toList(growable: false);

    expect(catalog['state'], 'New York');
    expect(games.length, greaterThanOrEqualTo(100));
    expect(games.map((game) => game['id']).toSet(), hasLength(games.length));
    for (final game in games) {
      expect(game['name'].toString().trim(), isNotEmpty);
      expect(game['cost'] as num, greaterThan(0));
      expect(game['topPrize'] as num, greaterThan(0));
      expect(game['topPrizesRemaining'] as num, greaterThanOrEqualTo(0));
    }
  });

  test('New York directory includes every official active retailer', () {
    final root = _readObject('data/new_york_retailer_directory.generated.json');
    final directory = Map<String, dynamic>.from(
      (root['directories'] as List).single as Map,
    );
    final retailers = (directory['retailers'] as List)
        .map((retailer) => Map<String, dynamic>.from(retailer as Map))
        .toList(growable: false);
    final unresolved = directory['unresolvedRetailers'] as List;

    expect(directory['state'], 'New York');
    expect(retailers.length, greaterThanOrEqualTo(12000));
    expect(unresolved, isEmpty);
    expect(
      retailers.map((retailer) => retailer['id']).toSet(),
      hasLength(retailers.length),
    );
    for (final retailer in retailers) {
      expect(retailer['name'].toString().trim(), isNotEmpty);
      expect(retailer['address'].toString().trim(), isNotEmpty);
      expect(retailer['city'].toString().trim(), isNotEmpty);
      expect(retailer['county'].toString(), endsWith('County'));
      expect(retailer['latitude'] as num, inInclusiveRange(40.3, 45.2));
      expect(retailer['longitude'] as num, inInclusiveRange(-79.9, -71.7));
      expect(retailer['coordinateSource'].toString().trim(), isNotEmpty);
    }
  });

  test('New York activity is retailer-verified for every year since 2024', () {
    final root = _readObject('data/new_york_winner_activity.generated.json');
    final records = (root['activities'] as List)
        .map((record) => Map<String, dynamic>.from(record as Map))
        .toList(growable: false);
    final currentYear = DateTime.now().year;
    final years = records
        .map((record) => DateTime.parse(record['drawDate'] as String).year)
        .toSet();
    final latest = records
        .map((record) => DateTime.parse(record['drawDate'] as String))
        .reduce((left, right) => left.isAfter(right) ? left : right);
    final months = records.map((record) {
      final date = DateTime.parse(record['drawDate'] as String);
      return '${date.year}-${date.month.toString().padLeft(2, '0')}';
    }).toSet();

    expect(records.length, greaterThanOrEqualTo(1000));
    expect(
      years,
      containsAll(<int>[
        for (var year = 2024; year <= currentYear; year++) year,
      ]),
    );
    expect(
      records.where((record) => record['game'] == 'scratch-off').length,
      greaterThanOrEqualTo(80),
    );
    for (
      var month = DateTime.utc(2024);
      !month.isAfter(DateTime.utc(latest.year, latest.month));
      month = DateTime.utc(month.year, month.month + 1)
    ) {
      expect(
        months,
        contains('${month.year}-${month.month.toString().padLeft(2, '0')}'),
      );
    }
    for (final record in records) {
      expect(record['state'], 'NY');
      expect(record['retailerName'].toString().trim(), isNotEmpty);
      expect(record['retailerAddress'].toString().trim(), isNotEmpty);
      expect(
        record['sourceUrl'].toString(),
        startsWith('https://nylottery.ny.gov/'),
      );
      expect(record['coordinateSource'].toString().trim(), isNotEmpty);
      expect(record['latitude'], isA<num>());
      expect(record['longitude'], isA<num>());
    }
  });

  test('New York current recurring draw menu is verified', () {
    final names = LotteryScheduleService.stateDrawsFor(
      'New York',
    ).map((draw) => draw.name).toSet();
    expect(
      names,
      containsAll(<String>{
        'NUMBERS · Midday',
        'NUMBERS · Evening',
        'Win4 · Midday',
        'Win4 · Evening',
        'Take 5 · Midday',
        'Take 5 · Evening',
        'Quick Draw',
        'Pick 10',
        'LOTTO',
        'Millionaire for Life',
      }),
    );
  });

  test('combined public state feeds include New York', () {
    final catalogStates =
        (_readObject('docs/state_scratch_catalogs.json')['catalogs'] as List)
            .map((item) => (item as Map)['state'])
            .toSet();
    final directoryStates =
        (_readObject('docs/state_retailer_directories.json')['directories']
                as List)
            .map((item) => (item as Map)['state'])
            .toSet();
    expect(catalogStates, contains('New York'));
    expect(directoryStates, contains('New York'));
  });

  test(
    'New York heat activity is available from bundled data offline',
    () async {
      SharedPreferencesAsyncPlatform.instance =
          InMemorySharedPreferencesAsync.empty();
      final offlineClient = MockClient(
        (_) async => http.Response('offline', 503),
      );

      await LotteryActivityFeedService.loadConfiguredFeed(
        client: offlineClient,
      );

      final newYork = LotteryActivityRepository.activity
          .where((activity) => activity.state == 'NY')
          .toList(growable: false);
      expect(newYork.length, greaterThanOrEqualTo(1000));
      expect(
        newYork.map((activity) => activity.drawDate.year).toSet(),
        containsAll(<int>[
          for (var year = 2024; year <= DateTime.now().year; year++) year,
        ]),
      );
    },
  );
}
