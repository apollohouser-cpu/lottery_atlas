import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/south_carolina_retailer.dart';
import '../../services/south_carolina_retailer_map_service.dart';
import '../../services/south_carolina_retailer_feed_service.dart';
import '../../services/south_carolina_retailer_repository.dart';
import 'south_carolina_nearby_screen.dart';

/// A transparent, claim-location view for the South Carolina retailer starter
/// data. This is deliberately distinct from the winning-ticket heat map.
class SouthCarolinaRetailersScreen extends StatefulWidget {
  const SouthCarolinaRetailersScreen({super.key});

  @override
  State<SouthCarolinaRetailersScreen> createState() =>
      _SouthCarolinaRetailersScreenState();
}

class _SouthCarolinaRetailersScreenState
    extends State<SouthCarolinaRetailersScreen> {
  static const MethodChannel _magicMouseChannel = MethodChannel(
    'lottery_atlas/magic_mouse',
  );

  final TextEditingController _queryController = TextEditingController();
  String _query = '';
  bool _isRefreshing = false;
  String? _lastRefreshMessage;

  @override
  void initState() {
    super.initState();
    // Let the list receive Magic Mouse scrolling instead of the map behind it.
    _magicMouseChannel.invokeMethod<void>('setMapActive', false);
    SouthCarolinaRetailerRepository.changes.addListener(_onRetailersChanged);
    _refreshRetailers();
  }

  @override
  void dispose() {
    SouthCarolinaRetailerRepository.changes.removeListener(_onRetailersChanged);
    _queryController.dispose();
    _magicMouseChannel.invokeMethod<void>('setMapActive', true);
    super.dispose();
  }

  void _onRetailersChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _refreshRetailers({bool showMessage = false}) async {
    if (_isRefreshing) return;

    setState(() => _isRefreshing = true);
    SouthCarolinaRetailerFeedRefreshResult? result;
    try {
      result = await SouthCarolinaRetailerFeedService.loadConfiguredFeed();
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _lastRefreshMessage = result?.message;
        });
      }
    }

    if (!mounted) return;

    if (showMessage) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(result.message)));
    }
  }

  String _sourceUpdateLabel(BuildContext context) {
    final updatedAt = SouthCarolinaRetailerRepository.updatedAt;
    if (updatedAt == null) {
      return SouthCarolinaRetailerRepository.isCached
          ? 'Saved data available on this device'
          : 'Built-in starter data';
    }

    final localizations = MaterialLocalizations.of(context);
    final localTime = updatedAt.toLocal();
    return 'Updated ${localizations.formatMediumDate(localTime)} at '
        '${localizations.formatTimeOfDay(TimeOfDay.fromDateTime(localTime))}';
  }

  List<SouthCarolinaRetailer> get _visibleRetailers {
    final normalizedQuery = _query.trim().toLowerCase();
    final retailers = SouthCarolinaRetailerRepository.retailers;
    if (normalizedQuery.isEmpty) return retailers;

    return retailers
        .where((retailer) {
          final haystack = [
            retailer.name,
            retailer.address,
            retailer.city,
            retailer.county,
            retailer.gameName,
          ].join(' ').toLowerCase();
          return haystack.contains(normalizedQuery);
        })
        .toList(growable: false);
  }

  void _showOnMap() {
    SouthCarolinaRetailerMapService.show();
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _openDirections(SouthCarolinaRetailer retailer) async {
    final destination = '${retailer.address}, ${retailer.city}, SC';
    final directionsUri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });

    final opened = await launchUrl(
      directionsUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open directions for ${retailer.name}.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final retailers = _visibleRetailers;
    return Scaffold(
      backgroundColor: const Color(0xFF071827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071827),
        foregroundColor: Colors.white,
        title: const Text('SC Retailer Claim Locations'),
        actions: [
          IconButton(
            tooltip: 'Refresh retailer data',
            onPressed: _isRefreshing
                ? null
                : () => _refreshRetailers(showMessage: true),
            icon: _isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
          IconButton(
            tooltip: 'Find nearby retailers',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const SouthCarolinaNearbyScreen(),
              ),
            ),
            icon: const Icon(Icons.near_me_rounded),
          ),
          IconButton(
            tooltip: 'Show on map',
            onPressed: _showOnMap,
            icon: const Icon(Icons.map_outlined),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF102638),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF355066)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'RETAILER CLAIM LOCATIONS',
                  style: TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 12,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  SouthCarolinaRetailerFeedService.isConfigured
                      ? 'Published retailer claim locations are refreshed from your configured South Carolina feed. These are reported prize locations, not every lottery retailer in the state.'
                      : 'This verified starter set is based on the official South Carolina Winners Report. It shows retailers connected to recently reported claimed prizes, not every lottery retailer in the state.',
                  style: const TextStyle(color: Colors.white70, height: 1.35),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Map pins are city-level until each retailer address has been verified and geocoded.',
                  style: TextStyle(
                    color: Color(0xFF93C5FD),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0B2131),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF28526C)),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        SouthCarolinaRetailerRepository.isCached
                            ? Icons.cloud_done_outlined
                            : Icons.verified_outlined,
                        color: const Color(0xFF34D399),
                        size: 20,
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              SouthCarolinaRetailerRepository.sourceLabel,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _sourceUpdateLabel(context),
                              style: const TextStyle(
                                color: Color(0xFF93C5FD),
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (_lastRefreshMessage != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _lastRefreshMessage!,
                    style: const TextStyle(
                      color: Color(0xFF93C5FD),
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _showOnMap,
              icon: const Icon(Icons.storefront_rounded),
              label: Text(
                'Show ${SouthCarolinaRetailerRepository.retailers.length} locations on map',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1478FF),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SouthCarolinaNearbyScreen(),
                ),
              ),
              icon: const Icon(Icons.near_me_rounded),
              label: const Text('Find nearby reported retailers'),
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF93C5FD),
                side: const BorderSide(color: Color(0xFF355066)),
                minimumSize: const Size.fromHeight(46),
              ),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            controller: _queryController,
            onChanged: (value) => setState(() => _query = value),
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Search retailer, city, county, or game',
              hintStyle: const TextStyle(color: Colors.white54),
              prefixIcon: const Icon(Icons.search, color: Colors.white70),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      onPressed: () {
                        _queryController.clear();
                        setState(() => _query = '');
                      },
                      icon: const Icon(Icons.close_rounded),
                    ),
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
          const SizedBox(height: 16),
          Text(
            '${retailers.length} reported claim location${retailers.length == 1 ? '' : 's'}',
            style: const TextStyle(
              color: Colors.white70,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          ...retailers.map(_retailerCard),
          if (retailers.isEmpty)
            const Padding(
              padding: EdgeInsets.only(top: 34),
              child: Center(
                child: Text(
                  'No retailer claim locations match that search.',
                  style: TextStyle(color: Colors.white60),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _retailerCard(SouthCarolinaRetailer retailer) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    decoration: BoxDecoration(
      color: const Color(0xFF102638),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF355066)),
    ),
    child: ListTile(
      contentPadding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
      leading: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: const Color(0x261478FF),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFF1478FF)),
        ),
        child: const Icon(Icons.storefront_rounded, color: Color(0xFF93C5FD)),
      ),
      title: Text(
        retailer.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          '${retailer.address}\n${retailer.city}, SC · ${retailer.county} County\n${retailer.gameName} · ${retailer.formattedPrize}',
          style: const TextStyle(color: Colors.white70, height: 1.3),
        ),
      ),
      isThreeLine: true,
      onTap: () => _openDirections(retailer),
      trailing: IconButton(
        tooltip: 'Get directions',
        onPressed: () => _openDirections(retailer),
        icon: const Icon(Icons.directions_rounded, color: Color(0xFF93C5FD)),
      ),
    ),
  );
}
