import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottery_atlas/models/south_carolina_retailer.dart';
import 'package:lottery_atlas/services/south_carolina_retailer_repository.dart';

void main() {
  test('city-level starter addresses remain listed but cannot become pins', () {
    expect(SouthCarolinaRetailerRepository.retailers, isNotEmpty);
    final approximate = SouthCarolinaRetailerRepository.retailers
        .where((retailer) => retailer.cityLevelPlacement)
        .map((r) => r.id)
        .toSet();
    expect(approximate, isNotEmpty);
    expect(
      SouthCarolinaRetailerRepository.mappableRetailers.any(
        (r) => approximate.contains(r.id),
      ),
      isFalse,
    );
  });

  test(
    'mixed feed excludes city positions without discarding address records',
    () {
      final original = SouthCarolinaRetailerRepository.retailers;
      final source = SouthCarolinaRetailerRepository.sourceLabel;
      addTearDown(
        () => SouthCarolinaRetailerRepository.usePublishedRetailers(
          original,
          sourceLabel: source,
        ),
      );
      SouthCarolinaRetailer row(String id, bool cityLevel) =>
          SouthCarolinaRetailer(
            id: id,
            name: 'Test retailer',
            address: 'Test address',
            city: 'Test city',
            county: 'Test county',
            location: const LatLng(34, -81),
            gameName: 'Pick 3',
            claimDate: DateTime(2026, 9, 1),
            reportedPrizeAmount: 500,
            cityLevelPlacement: cityLevel,
          );
      SouthCarolinaRetailerRepository.usePublishedRetailers([
        row('city', true),
        row('address', false),
      ], sourceLabel: 'test fixture');
      expect(SouthCarolinaRetailerRepository.retailers, hasLength(2));
      expect(
        SouthCarolinaRetailerRepository.mappableRetailers.map((r) => r.id),
        ['address'],
      );
    },
  );
}
