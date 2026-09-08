import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/lottery_schedule_service.dart';

Map<String, dynamic> _readObject(String path) =>
    Map<String, dynamic>.from(jsonDecode(File(path).readAsStringSync()) as Map);

void main() {
  test('Ohio generated Scratch-Off catalog is complete and valid', () {
    final root = _readObject('data/ohio_scratch_catalog.generated.json');
    final catalog = Map<String, dynamic>.from(
      (root['catalogs'] as List).single as Map,
    );
    final games = (catalog['games'] as List)
        .map((game) => Map<String, dynamic>.from(game as Map))
        .toList(growable: false);

    expect(catalog['state'], 'Ohio');
    expect(games.length, greaterThanOrEqualTo(60));
    expect(games.map((game) => game['id']).toSet(), hasLength(games.length));
    for (final game in games) {
      expect(game['name'].toString().trim(), isNotEmpty);
      expect(game['cost'] as num, greaterThan(0));
      expect(game['topPrize'] as num, greaterThan(0));
      expect(game['topPrizesRemaining'] as num, greaterThanOrEqualTo(0));
    }
  });

  test('Ohio directory includes every official active retailer', () {
    final root = _readObject('data/ohio_retailer_directory.generated.json');
    final directory = Map<String, dynamic>.from(
      (root['directories'] as List).single as Map,
    );
    final retailers = (directory['retailers'] as List)
        .map((retailer) => Map<String, dynamic>.from(retailer as Map))
        .toList(growable: false);

    expect(directory['state'], 'Ohio');
    expect(retailers.length, greaterThanOrEqualTo(9000));
    expect(
      retailers.map((retailer) => retailer['id']).toSet(),
      hasLength(retailers.length),
    );
    expect(
      retailers.map((retailer) => retailer['county']).toSet(),
      hasLength(88),
    );
    for (final retailer in retailers) {
      expect(retailer['name'].toString().trim(), isNotEmpty);
      expect(retailer['address'].toString().trim(), isNotEmpty);
      expect(retailer['city'].toString().trim(), isNotEmpty);
      expect(retailer['county'].toString(), endsWith('County'));
      expect(retailer['latitude'] as num, inInclusiveRange(38.3, 42.1));
      expect(retailer['longitude'] as num, inInclusiveRange(-85.0, -80.4));
      expect(retailer['coordinateSource'].toString().trim(), isNotEmpty);
    }
  });

  test('Ohio current recurring draw menu is verified', () {
    final names = LotteryScheduleService.stateDrawsFor(
      'Ohio',
    ).map((draw) => draw.name).toSet();
    expect(
      names,
      containsAll(<String>{
        'Pick 3 · Midday',
        'Pick 3 · Evening',
        'Pick 4 · Midday',
        'Pick 4 · Evening',
        'Pick 5 · Midday',
        'Pick 5 · Evening',
        'Rolling Cash 5',
        'Classic Lotto',
        'Kicker',
      }),
    );
  });

  test('combined public state feeds include Ohio', () {
    final catalogStates =
        (_readObject('docs/state_scratch_catalogs.json')['catalogs'] as List)
            .map((item) => (item as Map)['state'])
            .toSet();
    final directoryStates =
        (_readObject('docs/state_retailer_directories.json')['directories']
                as List)
            .map((item) => (item as Map)['state'])
            .toSet();
    expect(catalogStates, contains('Ohio'));
    expect(directoryStates, contains('Ohio'));
  });
}
