import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/south_carolina_retailer.dart';
import '../../services/lottery_activity_repository.dart';
import '../../services/map_focus_service.dart';
import '../../services/south_carolina_retailer_repository.dart';

/// Finds reported South Carolina retailer claim locations near a city or ZIP.
class SouthCarolinaNearbyScreen extends StatefulWidget {
  const SouthCarolinaNearbyScreen({super.key});

  @override
  State<SouthCarolinaNearbyScreen> createState() =>
      _SouthCarolinaNearbyScreenState();
}

class _SouthCarolinaNearbyScreenState extends State<SouthCarolinaNearbyScreen> {
  static const MethodChannel _magicMouseChannel = MethodChannel(
    'lottery_atlas/magic_mouse',
  );

  final TextEditingController _queryController = TextEditingController();
  _NearbySearchOrigin? _origin;
  String? _message;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _magicMouseChannel.invokeMethod<void>('setMapActive', false);
  }

  @override
  void dispose() {
    _queryController.dispose();
    _magicMouseChannel.invokeMethod<void>('setMapActive', true);
    super.dispose();
  }

  Future<void> _search() async {
    final query = _queryController.text.trim();
    if (query.isEmpty || _isSearching) return;

    setState(() {
      _isSearching = true;
      _message = null;
    });

    try {
      final origin = RegExp(r'^\d{5}(?:-\d{4})?$').hasMatch(query)
          ? await _originForZip(query.substring(0, 5))
          : _originForCity(query);
      if (!mounted) return;
      setState(() {
        _origin = origin;
        _message = origin == null
            ? 'No published South Carolina map location matches “$query”. Try a city with reported activity or a South Carolina ZIP code.'
            : null;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _origin = null;
        _message =
            'That ZIP code could not be located right now. Try entering a South Carolina city instead.';
      });
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  _NearbySearchOrigin? _originForCity(String query) {
    final normalizedQuery = _normalize(query);
    final candidates = <_NearbySearchOrigin>[];

    for (final retailer in SouthCarolinaRetailerRepository.retailers) {
      candidates.add(
        _NearbySearchOrigin(
          label: '${retailer.city}, SC',
          location: retailer.location,
          city: retailer.city,
        ),
      );
    }
    for (final activity in LotteryActivityRepository.activity) {
      if (activity.state != 'SC') continue;
      candidates.add(
        _NearbySearchOrigin(
          label: '${activity.city}, SC',
          location: activity.location,
          city: activity.city,
        ),
      );
    }

    final exact = candidates.where(
      (candidate) => _normalize(candidate.city) == normalizedQuery,
    );
    if (exact.isNotEmpty) return exact.first;

    final partial = candidates.where(
      (candidate) => _normalize(candidate.city).contains(normalizedQuery),
    );
    return partial.isEmpty ? null : partial.first;
  }

  Future<_NearbySearchOrigin?> _originForZip(String zip) async {
    final response = await http
        .get(Uri.https('api.zippopotam.us', '/us/$zip'))
        .timeout(const Duration(seconds: 8));
    if (response.statusCode != 200) return null;

    final decoded = jsonDecode(response.body);
    if (decoded is! Map) return null;
    if (decoded['state abbreviation']?.toString() != 'SC') return null;
    final places = decoded['places'];
    if (places is! List || places.isEmpty || places.first is! Map) return null;

    final place = Map<String, dynamic>.from(places.first as Map);
    final latitude = double.tryParse(place['latitude']?.toString() ?? '');
    final longitude = double.tryParse(place['longitude']?.toString() ?? '');
    final city = place['place name']?.toString().trim() ?? '';
    if (latitude == null || longitude == null || city.isEmpty) return null;

    return _NearbySearchOrigin(
      label: '$city, SC · $zip',
      location: LatLng(latitude, longitude),
      city: city,
    );
  }

  String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  List<_NearbyRetailer> get _nearbyRetailers {
    final origin = _origin;
    if (origin == null) return const <_NearbyRetailer>[];

    final results =
        SouthCarolinaRetailerRepository.retailers
            .map(
              (retailer) => _NearbyRetailer(
                retailer: retailer,
                milesAway: _milesBetween(origin.location, retailer.location),
              ),
            )
            .toList()
          ..sort((left, right) => left.milesAway.compareTo(right.milesAway));
    return results.take(12).toList(growable: false);
  }

  double _milesBetween(LatLng first, LatLng second) {
    const earthRadiusMiles = 3958.8;
    final latitudeDelta = _degreesToRadians(second.latitude - first.latitude);
    final longitudeDelta = _degreesToRadians(
      second.longitude - first.longitude,
    );
    final firstLatitude = _degreesToRadians(first.latitude);
    final secondLatitude = _degreesToRadians(second.latitude);
    final a =
        math.sin(latitudeDelta / 2) * math.sin(latitudeDelta / 2) +
        math.cos(firstLatitude) *
            math.cos(secondLatitude) *
            math.sin(longitudeDelta / 2) *
            math.sin(longitudeDelta / 2);
    return earthRadiusMiles * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  double _degreesToRadians(double value) => value * math.pi / 180;

  Future<void> _openDirections(SouthCarolinaRetailer retailer) async {
    final destination = '${retailer.address}, ${retailer.city}, SC';
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open directions for ${retailer.name}.'),
        ),
      );
    }
  }

  void _showOnMap(SouthCarolinaRetailer retailer) {
    MapFocusService.focusRetailer(
      stateName: 'South Carolina',
      retailerId: retailer.id,
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final origin = _origin;
    final retailers = _nearbyRetailers;

    return Scaffold(
      backgroundColor: const Color(0xFF071827),
      appBar: AppBar(
        title: const Text('Find Nearby in South Carolina'),
        backgroundColor: const Color(0xFF071827),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF102638),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF355066)),
            ),
            child: const Text(
              'Enter a South Carolina city or ZIP code to find nearby reported lottery-claim retailers. Distances are straight-line estimates; use Directions for the driving route.',
              style: TextStyle(color: Colors.white70, height: 1.4),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _queryController,
            textInputAction: TextInputAction.search,
            onSubmitted: (_) => _search(),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'City or ZIP code',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.location_searching_rounded),
              filled: true,
              fillColor: const Color(0xFF102638),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF355066)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFF355066)),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _isSearching ? null : _search,
              icon: _isSearching
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.near_me_rounded),
              label: Text(_isSearching ? 'Finding locations…' : 'Find nearby'),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1478FF),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          if (_message != null) ...[
            const SizedBox(height: 14),
            _MessageCard(message: _message!),
          ],
          if (origin != null) ...[
            const SizedBox(height: 22),
            Text(
              'NEAR ${origin.label.toUpperCase()}',
              style: const TextStyle(
                color: Color(0xFF93C5FD),
                fontSize: 12,
                letterSpacing: 1.1,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${retailers.length} closest reported claim locations',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 10),
            ...retailers.map(
              (result) => _NearbyRetailerCard(
                result: result,
                onDirections: () => _openDirections(result.retailer),
                onShowOnMap: () => _showOnMap(result.retailer),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _NearbySearchOrigin {
  const _NearbySearchOrigin({
    required this.label,
    required this.location,
    required this.city,
  });

  final String label;
  final LatLng location;
  final String city;
}

class _NearbyRetailer {
  const _NearbyRetailer({required this.retailer, required this.milesAway});

  final SouthCarolinaRetailer retailer;
  final double milesAway;

  String get distanceLabel => milesAway < 10
      ? '${milesAway.toStringAsFixed(1)} mi away'
      : '${milesAway.round()} mi away';
}

class _MessageCard extends StatelessWidget {
  const _MessageCard({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0x331478FF),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF355066)),
    ),
    child: Text(message, style: const TextStyle(color: Color(0xFFBFDBFE))),
  );
}

class _NearbyRetailerCard extends StatelessWidget {
  const _NearbyRetailerCard({
    required this.result,
    required this.onDirections,
    required this.onShowOnMap,
  });

  final _NearbyRetailer result;
  final VoidCallback onDirections;
  final VoidCallback onShowOnMap;

  @override
  Widget build(BuildContext context) {
    final retailer = result.retailer;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF102638),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF355066)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.storefront_rounded, color: Color(0xFF60A5FA)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  retailer.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                result.distanceLabel,
                style: const TextStyle(
                  color: Color(0xFF86EFAC),
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '${retailer.address}, ${retailer.city}, SC',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 3),
          Text(
            '${retailer.gameName} · ${retailer.formattedPrize}',
            style: const TextStyle(color: Color(0xFF93C5FD), fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onShowOnMap,
                  icon: const Icon(Icons.map_outlined, size: 18),
                  label: const Text('Map'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF93C5FD),
                    side: const BorderSide(color: Color(0xFF355066)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: FilledButton.icon(
                  onPressed: onDirections,
                  icon: const Icon(Icons.directions_rounded, size: 18),
                  label: const Text('Directions'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1478FF),
                    foregroundColor: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
