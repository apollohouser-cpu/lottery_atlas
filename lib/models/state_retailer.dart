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
    this.sellsVideo,
    this.sellsDrawGames,
    this.sellsKeno,
    this.sellsInstant,
  });

  final String id;
  final String stateName;
  final String name;
  final String address;
  final String city;
  final String postalCode;
  final LatLng location;
  final String? county;
  final bool? sellsVideo;
  final bool? sellsDrawGames;
  final bool? sellsKeno;
  final bool? sellsInstant;

  /// Source flags describe offered products, never current ticket inventory.
  String? get productSummary {
    if ([
      sellsVideo,
      sellsDrawGames,
      sellsKeno,
      sellsInstant,
    ].every((value) => value == null)) {
      return null;
    }
    final products = <String>[
      if (sellsDrawGames == true) 'Draw games',
      if (sellsKeno == true) 'Keno',
      if (sellsInstant == true) 'Scratch',
      if (sellsVideo == true) 'Video Lottery',
    ];
    return products.isEmpty
        ? 'No products flagged in the source'
        : 'Source-listed products: ${products.join(' · ')}';
  }

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
    final productFlags = <String, bool?>{};
    for (final key in [
      'sellsVideo',
      'sellsDrawGames',
      'sellsKeno',
      'sellsInstant',
    ]) {
      final value = json[key];
      if ((value != null && value is! bool) ||
          (stateName == 'Oregon' && value is! bool)) {
        throw const FormatException('Invalid retailer product flag.');
      }
      productFlags[key] = value as bool?;
    }
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
      sellsVideo: productFlags['sellsVideo'],
      sellsDrawGames: productFlags['sellsDrawGames'],
      sellsKeno: productFlags['sellsKeno'],
      sellsInstant: productFlags['sellsInstant'],
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
    if (sellsVideo != null) 'sellsVideo': sellsVideo,
    if (sellsDrawGames != null) 'sellsDrawGames': sellsDrawGames,
    if (sellsKeno != null) 'sellsKeno': sellsKeno,
    if (sellsInstant != null) 'sellsInstant': sellsInstant,
    'latitude': location.latitude,
    'longitude': location.longitude,
  };

  static double? _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }
}
