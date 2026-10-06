import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/models/state_retailer.dart';

void main() {
  test('accepts a complete official retailer directory entry', () {
    final retailer = StateRetailer.fromJson(<String, dynamic>{
      'id': 'mi-4001',
      'stateName': 'Michigan',
      'name': 'Example Lottery Retailer',
      'address': '100 Main Street',
      'city': 'Lansing',
      'postalCode': '48933',
      'latitude': 42.7325,
      'longitude': -84.5555,
    });

    expect(retailer.stateAbbreviation, 'MI');
    expect(retailer.county, isNull);
  });

  final oregon = <String, dynamic>{
    'id': 'or-test',
    'stateName': 'Oregon',
    'name': 'Fixture retailer',
    'address': '1 Test Street',
    'city': 'Salem',
    'postalCode': '97301',
    'latitude': 44.94,
    'longitude': -123.03,
    'sellsVideo': true,
    'sellsDrawGames': false,
    'sellsKeno': false,
    'sellsInstant': false,
  };

  test(
    'preserves video-only and mixed product flags through serialization',
    () {
      final video = StateRetailer.fromJson(oregon);
      expect(video.productSummary, 'Source-listed products: Video Lottery');
      expect(StateRetailer.fromJson(video.toJson()).sellsInstant, false);
      final mixed = StateRetailer.fromJson({...oregon, 'sellsKeno': true});
      expect(
        mixed.productSummary,
        'Source-listed products: Keno · Video Lottery',
      );
      final none = StateRetailer.fromJson({...oregon, 'sellsVideo': false});
      expect(none.productSummary, 'No products flagged in the source');
    },
  );

  test(
    'Oregon requires explicit boolean flags instead of inferred products',
    () {
      for (final key in [
        'sellsVideo',
        'sellsDrawGames',
        'sellsKeno',
        'sellsInstant',
      ]) {
        for (final value in [null, 'false', 0]) {
          expect(
            () => StateRetailer.fromJson({...oregon, key: value}),
            throwsFormatException,
          );
        }
      }
    },
  );

  test('Oregon public snapshot survives model and cache round trip', () {
    final feed = jsonDecode(
      File('data/oregon_retailer_directory.generated.json').readAsStringSync(),
    );
    final rows = feed['directories'][0]['retailers'] as List;
    expect(rows, isNotEmpty);
    for (final row in rows) {
      final retailer = StateRetailer.fromJson({
        ...Map<String, dynamic>.from(row),
        'stateName': 'Oregon',
      });
      final restored = StateRetailer.fromJson(retailer.toJson());
      expect(restored.productSummary, retailer.productSummary);
      for (final key in [
        'sellsVideo',
        'sellsDrawGames',
        'sellsKeno',
        'sellsInstant',
      ]) {
        expect(restored.toJson()[key], row[key]);
      }
    }
  });

  test('rejects a directory entry without an exact location', () {
    expect(
      () => StateRetailer.fromJson(<String, dynamic>{
        'id': 'mi-4001',
        'stateName': 'Michigan',
        'name': 'Example Lottery Retailer',
        'address': '100 Main Street',
        'city': 'Lansing',
        'postalCode': '48933',
        'latitude': 42.7325,
      }),
      throwsFormatException,
    );
  });
}
