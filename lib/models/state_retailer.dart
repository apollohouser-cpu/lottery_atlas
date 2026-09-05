import 'package:latlong2/latlong.dart';

import 'state_model.dart';

/// A location published by an official state lottery retailer directory.
///
/// This is deliberately separate from [LotteryActivity]: a licensed retailer
/// is not, by itself, evidence that a winning ticket was sold there.
class StateRetailer {
  const StateRetailer({
    required this.id,
    required this.stateName,
    required this.name,
    required this.address,
    required this.city,
    required this.postalCode,
    required this.location,
    this.county,
  });

  final String id;
  final String stateName;
  final String name;
  final String address;
  final String city;
  final String postalCode;
  final LatLng location;
  final String? county;

  String get stateAbbreviation =>
      allStates.firstWhere((state) => state.name == stateName).abbreviation;

  factory StateRetailer.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim() ?? '';
    final stateName = json['stateName']?.toString().trim() ?? '';
    final name = json['name']?.toString().trim() ?? '';
    final address = json['address']?.toString().trim() ?? '';
    final city = json['city']?.toString().trim() ?? '';
    final postalCode = json['postalCode']?.toString().trim() ?? '';
    final county = json['county']?.toString().trim();
    final latitude = _number(json['latitude']);
    final longitude = _number(json['longitude']);
    final knownState = allStates.any((state) => state.name == stateName);

    if (id.isEmpty ||
        !knownState ||
        name.isEmpty ||
        address.isEmpty ||
        city.isEmpty ||
        postalCode.isEmpty ||
        latitude == null ||
        longitude == null ||
        latitude < -90 ||
        latitude > 90 ||
        longitude < -180 ||
        longitude > 180) {
      throw const FormatException(
        'An official retailer directory entry has missing or invalid fields.',
      );
    }

    return StateRetailer(
      id: id,
      stateName: stateName,
      name: name,
      address: address,
      city: city,
      postalCode: postalCode,
      county: county == null || county.isEmpty ? null : county,
      location: LatLng(latitude, longitude),
    );
  }

  Map<String, dynamic> toJson() => <String, dynamic>{
    'id': id,
    'stateName': stateName,
    'name': name,
    'address': address,
    'city': city,
    'postalCode': postalCode,
    if (county != null) 'county': county,
    'latitude': location.latitude,
    'longitude': location.longitude,
  };

  static double? _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
