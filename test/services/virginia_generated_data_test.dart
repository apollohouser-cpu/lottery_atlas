import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/lottery_schedule_service.dart';

Map<String, dynamic> _readObject(String path) =>
    Map<String, dynamic>.from(jsonDecode(File(path).readAsStringSync()) as Map);

void main() {
  test('Virginia generated Scratcher catalog is complete and valid', () {
    final root = _readObject('data/virginia_scratch_catalog.generated.json');
    final catalog = Map<String, dynamic>.from(
      (root['catalogs'] as List).single as Map,
    );
    final games = (catalog['games'] as List)
        .map((game) => Map<String, dynamic>.from(game as Map))
        .toList(growable: false);

    expect(catalog['state'], 'Virginia');
    expect(games.length, greaterThanOrEqualTo(85));
    expect(games.map((game) => game['id']).toSet(), hasLength(games.length));
    for (final game in games) {
      expect(game['name'].toString().trim(), isNotEmpty);
      expect(game['cost'] as num, greaterThan(0));
      expect(game['topPrize'] as num, greaterThan(0));
      expect(game['topPrizesRemaining'] as num, greaterThanOrEqualTo(0));
    }
  });

  test('Virginia directory retains every official retailer row', () {
    final root = _readObject('data/virginia_retailer_directory.generated.json');
    final directory = Map<String, dynamic>.from(
      (root['directories'] as List).single as Map,
    );
    final retailers = (directory['retailers'] as List)
        .map((retailer) => Map<String, dynamic>.from(retailer as Map))
        .toList(growable: false);
    final unresolved = (directory['unresolvedRetailers'] as List)
        .map((retailer) => Map<String, dynamic>.from(retailer as Map))
        .toList(growable: false);

    expect(directory['state'], 'Virginia');
    expect(retailers.length, greaterThanOrEqualTo(5300));
    expect(retailers.length + unresolved.length, greaterThanOrEqualTo(5400));
    expect(
      retailers.map((retailer) => retailer['id']).toSet(),
      hasLength(retailers.length),
    );
    for (final retailer in retailers) {
      expect(retailer['name'].toString().trim(), isNotEmpty);
      expect(retailer['address'].toString().trim(), isNotEmpty);
      expect(retailer['city'].toString().trim(), isNotEmpty);
      expect(retailer['county'].toString().trim(), isNotEmpty);
      expect(retailer['latitude'] as num, inInclusiveRange(36.4, 39.6));
      expect(retailer['longitude'] as num, inInclusiveRange(-83.8, -75.0));
      expect(retailer['coordinateSource'].toString().trim(), isNotEmpty);
    }
  });

  test('Virginia activity is retailer-verified for every year since 2024', () {
    final root = _readObject('data/virginia_winner_activity.generated.json');
    final records = (root['activities'] as List)
        .map((record) => Map<String, dynamic>.from(record as Map))
        .toList(growable: false);
    final currentYear = DateTime.now().year;
    final years = records
        .map((record) => DateTime.parse(record['drawDate'] as String).year)
        .toSet();

    expect(records.length, greaterThanOrEqualTo(90));
    expect(
      years,
      containsAll(<int>[
        for (var year = 2024; year <= currentYear; year++) year,
      ]),
    );
    for (final record in records) {
      expect(record['state'], 'VA');
      expect(record['retailerName'].toString().trim(), isNotEmpty);
      expect(record['retailerAddress'].toString().trim(), isNotEmpty);
      expect(
        record['sourceUrl'].toString(),
        startsWith('https://www.valottery.com/'),
      );
      expect(record['coordinateSource'].toString().trim(), isNotEmpty);
      expect(record['latitude'], isA<num>());
      expect(record['longitude'], isA<num>());
    }
  });

  test('Virginia current recurring draw menu is verified', () {
    final names = LotteryScheduleService.stateDrawsFor(
      'Virginia',
    ).map((draw) => draw.name).toSet();
    expect(
      names,
      containsAll(<String>{
        'Pick 3 · Day',
        'Pick 3 · Night',
        'Pick 4 · Day',
        'Pick 4 · Night',
        'Pick 5 · Day',
        'Pick 5 · Night',
        'Cash 5 with EZ Match',
        'Millionaire for Life',
        'Bank a Million',
        'Keno · Every 4 minutes',
        'Cash Pop · Coffee Break',
        'Cash Pop · Lunch Break',
        'Cash Pop · Rush Hour',
        'Cash Pop · Prime Time',
        'Cash Pop · After Hours',
      }),
    );
  });

  test('combined public state feeds include Kentucky and Virginia', () {
    final catalogStates =
        (_readObject('docs/state_scratch_catalogs.json')['catalogs'] as List)
            .map((item) => (item as Map)['state'])
            .toSet();
    final directoryStates =
        (_readObject('docs/state_retailer_directories.json')['directories']
                as List)
            .map((item) => (item as Map)['state'])
            .toSet();
    expect(catalogStates, containsAll(<String>{'Kentucky', 'Virginia'}));
    expect(directoryStates, containsAll(<String>{'Kentucky', 'Virginia'}));
  });
}
