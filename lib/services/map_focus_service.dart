import 'package:flutter/foundation.dart';
import 'package:latlong2/latlong.dart';

enum MapFocusKind { state, county, city, retailer }

class MapFocusRequest {
  const MapFocusRequest.state(this.stateName)
    : kind = MapFocusKind.state,
      countyId = null,
      city = null,
      location = null,
      retailerId = null;

  const MapFocusRequest.county({
    required this.stateName,
    required this.countyId,
  }) : kind = MapFocusKind.county,
       city = null,
       location = null,
       retailerId = null;

  const MapFocusRequest.city({
    required this.stateName,
    required this.city,
    required this.location,
  }) : kind = MapFocusKind.city,
       countyId = null,
       retailerId = null;

  const MapFocusRequest.retailer({
    required this.stateName,
    required this.retailerId,
  }) : kind = MapFocusKind.retailer,
       countyId = null,
       city = null,
       location = null;

  final MapFocusKind kind;
  final String stateName;
  final String? countyId;
  final String? city;
  final LatLng? location;
  final String? retailerId;
}

/// Lightweight local navigation from a favorite or dashboard card back to map.
class MapFocusService {
  MapFocusService._();

  static final ValueNotifier<MapFocusRequest?> requestedFocus =
      ValueNotifier<MapFocusRequest?>(null);

  static void focusState(String stateName) {
    requestedFocus.value = MapFocusRequest.state(stateName);
  }

  static void focusCounty({
    required String stateName,
    required String countyId,
  }) {
    requestedFocus.value = MapFocusRequest.county(
      stateName: stateName,
      countyId: countyId,
    );
  }

  static void focusCity({
    required String stateName,
    required String city,
    required LatLng location,
  }) {
    requestedFocus.value = MapFocusRequest.city(
      stateName: stateName,
      city: city,
      location: location,
    );
  }

  static void focusRetailer({
    required String stateName,
    required String retailerId,
  }) {
    requestedFocus.value = MapFocusRequest.retailer(
      stateName: stateName,
      retailerId: retailerId,
    );
  }

  static void clear() {
    if (requestedFocus.value != null) requestedFocus.value = null;
  }
}
