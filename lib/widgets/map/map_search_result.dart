import 'package:latlong2/latlong.dart';

class MapSearchResult {
  const MapSearchResult({
    required this.label,
    required this.subtitle,
    required this.location,
    required this.zoom,
    this.stateName,
  });

  final String label;
  final String subtitle;
  final LatLng location;
  final double zoom;
  final String? stateName;
}
