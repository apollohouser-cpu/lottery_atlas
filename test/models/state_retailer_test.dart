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
