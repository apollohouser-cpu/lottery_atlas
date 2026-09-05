import 'package:latlong2/latlong.dart';

class SouthCarolinaRetailer {
  const SouthCarolinaRetailer({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.county,
    required this.location,
    required this.gameName,
    required this.claimDate,
    required this.reportedPrizeAmount,
    this.cityLevelPlacement = true,
  });

  final String id;
  final String name;
  final String address;
  final String city;
  final String county;
  final LatLng location;
  final String gameName;
  final DateTime claimDate;
  final int reportedPrizeAmount;
  final bool cityLevelPlacement;

  factory SouthCarolinaRetailer.fromJson(Map<String, dynamic> json) {
    final id = json['id']?.toString().trim() ?? '';
    final name = json['name']?.toString().trim() ?? '';
    final address = json['address']?.toString().trim() ?? '';
    final city = json['city']?.toString().trim() ?? '';
    final county = json['county']?.toString().trim() ?? '';
    final gameName = json['gameName']?.toString().trim() ?? '';
    final latitude = _number(json['latitude']);
    final longitude = _number(json['longitude']);
    final claimDate = DateTime.tryParse(json['claimDate']?.toString() ?? '');
    final reportedPrizeAmount = _integer(json['reportedPrizeAmount']);

    if (id.isEmpty ||
        name.isEmpty ||
        address.isEmpty ||
        city.isEmpty ||
        county.isEmpty ||
        gameName.isEmpty ||
        latitude == null ||
        longitude == null ||
        claimDate == null ||
        reportedPrizeAmount == null) {
      throw const FormatException(
        'A retailer claim record has missing fields.',
      );
    }

    if (latitude < 31.5 ||
        latitude > 35.7 ||
        longitude < -83.8 ||
        longitude > -77.3) {
      throw const FormatException(
        'A South Carolina retailer claim has coordinates outside South Carolina.',
      );
    }

    if (reportedPrizeAmount < 0) {
      throw const FormatException(
        'A retailer claim cannot have a negative prize amount.',
      );
    }

    return SouthCarolinaRetailer(
      id: id,
      name: name,
      address: address,
      city: city,
      county: county,
      location: LatLng(latitude, longitude),
      gameName: gameName,
      claimDate: claimDate.toLocal(),
      reportedPrizeAmount: reportedPrizeAmount,
      cityLevelPlacement: json['cityLevelPlacement'] != false,
    );
  }

  static double? _number(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '');
  }

  static int? _integer(Object? value) {
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  String get formattedPrize {
    if (reportedPrizeAmount >= 1000000) {
      return '\$${(reportedPrizeAmount / 1000000).toStringAsFixed(1)}M';
    }
    if (reportedPrizeAmount >= 1000) {
      return '\$${(reportedPrizeAmount / 1000).toStringAsFixed(0)}K';
    }
    return '\$$reportedPrizeAmount';
  }
}
