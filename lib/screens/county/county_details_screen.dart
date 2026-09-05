import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/lottery_activity.dart';
import '../../models/south_carolina_retailer.dart';
import '../../models/state_model.dart';
import '../../services/lottery_activity_repository.dart';
import '../../services/map_focus_service.dart';
import '../../services/south_carolina_retailer_repository.dart';
import '../../widgets/map/map_filter_state.dart';

class CountyDetailsScreen extends StatelessWidget {
  const CountyDetailsScreen({
    super.key,
    required this.state,
    required this.countyName,
    required this.countyFips,
  });

  final StateModel state;
  final String countyName;
  final String countyFips;

  @override
  Widget build(BuildContext context) {
    final activity =
        LotteryActivityRepository.activity
            .where(
              (item) =>
                  item.state == state.abbreviation &&
                  _normalizedCounty(item.county) ==
                      _normalizedCounty(countyName),
            )
            .toList()
          ..sort((a, b) => b.drawDate.compareTo(a.drawDate));
    final winningTickets = activity.fold<int>(
      0,
      (total, item) => total + item.winningTickets,
    );
    final prizeTotal = activity.fold<int>(
      0,
      (total, item) => total + item.prizeAmount,
    );
    final isSouthCarolina = state.abbreviation == 'SC';
    final retailers = isSouthCarolina
        ? SouthCarolinaRetailerRepository.retailers
              .where(
                (retailer) =>
                    _normalizedCounty(retailer.county) ==
                    _normalizedCounty(countyName),
              )
              .toList(growable: false)
        : const <SouthCarolinaRetailer>[];
    final activityRetailers = activity
        .where(
          (record) =>
              record.retailerName != null && record.retailerAddress != null,
        )
        .toList(growable: false);
    final scratchOffActivity = activity
        .where((item) => item.game == LotteryGame.scratchOff)
        .toList(growable: false);

    return Scaffold(
      backgroundColor: const Color(0xFF071827),
      appBar: AppBar(
        title: Text(countyName),
        backgroundColor: const Color(0xFF071827),
        foregroundColor: Colors.white,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          Text(
            state.abbreviation,
            style: const TextStyle(
              color: Color(0xFF60A5FA),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            countyName,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 30,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${state.name} Lottery • County FIPS: $countyFips',
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          const Text(
            'COUNTY ACTIVITY',
            style: TextStyle(
              color: Color(0xFF93C5FD),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          _CountySummary(
            activity: activity,
            winningTickets: winningTickets,
            prizeTotal: prizeTotal,
          ),
          const SizedBox(height: 8),
          Text(
            LotteryActivityRepository.isSampleData
                ? 'Sample map activity is shown until a published lottery feed is connected.'
                : 'Published activity from ${LotteryActivityRepository.activitySourceLabel}.',
            style: const TextStyle(color: Colors.white54, fontSize: 12),
          ),
          const SizedBox(height: 26),
          const Text(
            'RECENT WINNING LOCATIONS',
            style: TextStyle(
              color: Color(0xFF93C5FD),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          if (activity.isEmpty)
            _NoActivityCard(stateName: state.name)
          else
            ...activity.map((item) => _ActivityRow(activity: item)),
          const SizedBox(height: 16),
          const Text(
            'EXPLORE THIS COUNTY',
            style: TextStyle(
              color: Color(0xFF93C5FD),
              fontSize: 13,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 10),
          _CountyActionCard(
            icon: Icons.location_city_outlined,
            title: 'Cities & Winning Locations',
            subtitle: activity.isEmpty
                ? 'No qualifying locations under the current published data'
                : 'Review ${activity.length} qualifying ${activity.length == 1 ? 'record' : 'records'} by city',
            onTap: () => _showCityActivity(context, activity),
          ),
          _CountyActionCard(
            icon: Icons.storefront_outlined,
            title: 'Retailers',
            subtitle: isSouthCarolina
                ? retailers.isEmpty
                      ? 'No reported retailer claim locations for this county yet'
                      : '${retailers.length} reported ${retailers.length == 1 ? 'retailer' : 'retailers'} with directions'
                : activityRetailers.isEmpty
                ? 'No named retailer locations in the current published county activity'
                : '${activityRetailers.length} reported ${activityRetailers.length == 1 ? 'retailer location' : 'retailer locations'} with directions',
            onTap: () => _showRetailers(
              context,
              retailers: retailers,
              activityRetailers: activityRetailers,
              isSouthCarolina: isSouthCarolina,
            ),
          ),
          _CountyActionCard(
            icon: Icons.confirmation_number_outlined,
            title: 'Scratch-Off Games',
            subtitle: scratchOffActivity.isEmpty
                ? 'No qualifying scratch-off claims under the current published data'
                : '${scratchOffActivity.length} qualifying scratch-off ${scratchOffActivity.length == 1 ? 'claim' : 'claims'}',
            onTap: () => _showScratchOffActivity(context, scratchOffActivity),
          ),
        ],
      ),
    );
  }

  Future<void> _showCityActivity(
    BuildContext context,
    List<LotteryActivity> activity,
  ) {
    final byCity = <String, List<LotteryActivity>>{};
    for (final record in activity) {
      byCity.putIfAbsent(record.city, () => <LotteryActivity>[]).add(record);
    }
    final cities = byCity.keys.toList()..sort();

    return _showCountySheet(
      context,
      title: 'Winning Locations',
      emptyMessage:
          'No qualifying county activity is available for the current data and filters.',
      children: cities
          .map((city) {
            final records = byCity[city]!;
            final prizeTotal = records.fold<int>(
              0,
              (total, record) => total + record.prizeAmount,
            );
            return _CountyListRow(
              icon: Icons.location_city_rounded,
              title: city,
              subtitle:
                  '${records.length} ${records.length == 1 ? 'record' : 'records'} · reported total \$${prizeTotal.toStringAsFixed(0)}',
              onTap: () {
                MapFocusService.focusCity(
                  stateName: state.name,
                  city: city,
                  location: records.first.location,
                );
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            );
          })
          .toList(growable: false),
    );
  }

  Future<void> _showRetailers(
    BuildContext context, {
    required List<SouthCarolinaRetailer> retailers,
    required List<LotteryActivity> activityRetailers,
    required bool isSouthCarolina,
  }) {
    final sortedRetailers = [...retailers]
      ..sort((left, right) => right.claimDate.compareTo(left.claimDate));
    final sortedActivityRetailers = [...activityRetailers]
      ..sort((left, right) => right.drawDate.compareTo(left.drawDate));
    return _showCountySheet(
      context,
      title: 'Reported Retailers',
      emptyMessage:
          'No named retailer claim locations are available for this county under the current published data.',
      children: isSouthCarolina
          ? sortedRetailers
                .map(
                  (retailer) => _RetailerListRow(
                    retailer: retailer,
                    onDirections: () => _openDirections(context, retailer),
                  ),
                )
                .toList(growable: false)
          : sortedActivityRetailers
                .map(
                  (activity) => _ActivityRetailerListRow(
                    activity: activity,
                    onDirections: () =>
                        _openActivityRetailerDirections(context, activity),
                  ),
                )
                .toList(growable: false),
    );
  }

  Future<void> _showScratchOffActivity(
    BuildContext context,
    List<LotteryActivity> activity,
  ) {
    final sortedActivity = [...activity]
      ..sort((left, right) => right.drawDate.compareTo(left.drawDate));
    return _showCountySheet(
      context,
      title: 'Scratch-Off Activity',
      emptyMessage:
          'No qualifying scratch-off claims are available for this county under the current published data.',
      children: sortedActivity
          .map(
            (record) => _CountyListRow(
              icon: Icons.confirmation_number_rounded,
              title: record.gameName ?? record.game.label,
              subtitle:
                  '${record.city} · ${record.winningTickets} ${record.winningTickets == 1 ? 'ticket' : 'tickets'} · ${record.formattedPrizeAmount}',
            ),
          )
          .toList(growable: false),
    );
  }

  Future<void> _openDirections(
    BuildContext context,
    SouthCarolinaRetailer retailer,
  ) async {
    final destination = '${retailer.address}, ${retailer.city}, SC';
    final directionsUri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });
    final opened = await launchUrl(
      directionsUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open directions for ${retailer.name}.'),
        ),
      );
    }
  }

  Future<void> _openActivityRetailerDirections(
    BuildContext context,
    LotteryActivity activity,
  ) async {
    final destination =
        activity.retailerAddress ??
        '${activity.location.latitude},${activity.location.longitude}';
    final directionsUri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
    });
    final opened = await launchUrl(
      directionsUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not open directions for ${activity.retailerName ?? 'this retailer'}.',
          ),
        ),
      );
    }
  }

  Future<void> _showCountySheet(
    BuildContext context, {
    required String title,
    required String emptyMessage,
    required List<Widget> children,
  }) => showModalBottomSheet<void>(
    context: context,
    backgroundColor: const Color(0xFF0B1D2C),
    isScrollControlled: true,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (sheetContext) => SafeArea(
      child: DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.58,
        minChildSize: 0.35,
        maxChildSize: 0.92,
        builder: (context, scrollController) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white24,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text(
              title,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 14),
            if (children.isEmpty)
              _EmptyCountySheet(message: emptyMessage)
            else
              ...children,
          ],
        ),
      ),
    ),
  );

  String _normalizedCounty(String value) {
    return value
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9 ]'), '')
        .replaceAll(RegExp(r'\b(county|parish|borough|census area)\b'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

class _CountySummary extends StatelessWidget {
  const _CountySummary({
    required this.activity,
    required this.winningTickets,
    required this.prizeTotal,
  });

  final List<LotteryActivity> activity;
  final int winningTickets;
  final int prizeTotal;

  String get _prizeLabel {
    if (prizeTotal >= 1000000) {
      return '\$${(prizeTotal / 1000000).toStringAsFixed(1)}M';
    }
    if (prizeTotal >= 1000) {
      return '\$${(prizeTotal / 1000).toStringAsFixed(0)}K';
    }
    return '\$$prizeTotal';
  }

  @override
  Widget build(BuildContext context) {
    if (activity.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: _cardDecoration(),
        child: const Row(
          children: [
            Icon(Icons.travel_explore_rounded, color: Color(0xFF60A5FA)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No qualifying published activity is listed here yet. Explore another county or change the map timeline.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
            ),
          ],
        ),
      );
    }

    final games = <LotteryGame>{for (final item in activity) item.game};
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _Metric(
                  label: 'WINNING TICKETS',
                  value: '$winningTickets',
                  icon: Icons.confirmation_number_rounded,
                ),
              ),
              Container(width: 1, height: 48, color: Colors.white12),
              Expanded(
                child: _Metric(
                  label: 'TOP PRIZE TOTAL',
                  value: _prizeLabel,
                  icon: Icons.workspace_premium_rounded,
                ),
              ),
            ],
          ),
          const Divider(height: 28, color: Colors.white12),
          Row(
            children: [
              const Icon(Icons.casino_rounded, color: Color(0xFF2CC36B)),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '${games.length} game ${games.length == 1 ? 'type' : 'types'} represented',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: const Color(0xFF102431),
    borderRadius: BorderRadius.circular(16),
    border: Border.all(color: const Color(0xFF24475D)),
  );
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value, required this.icon});

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Icon(icon, color: const Color(0xFF60A5FA), size: 19),
      const SizedBox(height: 5),
      Text(
        value,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 21,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 2),
      Text(
        label,
        textAlign: TextAlign.center,
        style: const TextStyle(color: Colors.white54, fontSize: 9),
      ),
    ],
  );
}

class _ActivityRow extends StatelessWidget {
  const _ActivityRow({required this.activity});
  final LotteryActivity activity;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF102431),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF24475D)),
    ),
    child: Row(
      children: [
        CircleAvatar(
          backgroundColor: const Color(0x331478FF),
          child: Icon(activity.game.icon, color: const Color(0xFF60A5FA)),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${activity.city} • ${activity.game.label}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${activity.winningTickets} winning tickets • ${activity.formattedPrizeAmount}',
                style: const TextStyle(color: Colors.white60, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class _NoActivityCard extends StatelessWidget {
  const _NoActivityCard({required this.stateName});
  final String stateName;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF102431),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF24475D)),
    ),
    child: Text(
      'There are no qualifying published winning locations for this $stateName county under the current data and filters.',
      style: const TextStyle(color: Colors.white70),
    ),
  );
}

class _EmptyCountySheet extends StatelessWidget {
  const _EmptyCountySheet({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF102638),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF355066)),
    ),
    child: Row(
      children: [
        const Icon(Icons.info_outline_rounded, color: Color(0xFF93C5FD)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            message,
            style: const TextStyle(color: Colors.white70, height: 1.35),
          ),
        ),
      ],
    ),
  );
}

class _CountyListRow extends StatelessWidget {
  const _CountyListRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: onTap == null ? MouseCursor.defer : SystemMouseCursors.click,
    child: GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF102638),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF24475D)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF60A5FA)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            if (onTap != null)
              const Icon(Icons.chevron_right_rounded, color: Colors.white38),
          ],
        ),
      ),
    ),
  );
}

class _RetailerListRow extends StatelessWidget {
  const _RetailerListRow({required this.retailer, required this.onDirections});

  final SouthCarolinaRetailer retailer;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF102638),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF24475D)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          retailer.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          '${retailer.address}, ${retailer.city}, SC',
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          '${retailer.gameName} · ${retailer.formattedPrize}',
          style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 12),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onDirections,
            icon: const Icon(Icons.directions_rounded, size: 18),
            label: const Text('Directions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF93C5FD),
              side: const BorderSide(color: Color(0xFF355066)),
            ),
          ),
        ),
      ],
    ),
  );
}

class _ActivityRetailerListRow extends StatelessWidget {
  const _ActivityRetailerListRow({
    required this.activity,
    required this.onDirections,
  });

  final LotteryActivity activity;
  final VoidCallback onDirections;

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 10),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF102638),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF24475D)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          activity.retailerName!,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          activity.retailerAddress!,
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          '${activity.gameName ?? activity.game.label} · ${activity.formattedPrizeAmount}',
          style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 12),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onDirections,
            icon: const Icon(Icons.directions_rounded, size: 18),
            label: const Text('Directions'),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF93C5FD),
              side: const BorderSide(color: Color(0xFF355066)),
            ),
          ),
        ),
      ],
    ),
  );
}

class _CountyActionCard extends StatefulWidget {
  const _CountyActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  State<_CountyActionCard> createState() => _CountyActionCardState();
}

class _CountyActionCardState extends State<_CountyActionCard> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) => MouseRegion(
    cursor: SystemMouseCursors.click,
    onEnter: (_) => setState(() => _isHovered = true),
    onExit: (_) => setState(() => _isHovered = false),
    child: GestureDetector(
      onTap: widget.onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        transform: Matrix4.identity()
          ..scaleByDouble(
            _isHovered ? 1.015 : 1.0,
            _isHovered ? 1.015 : 1.0,
            1,
            1,
          ),
        decoration: BoxDecoration(
          color: _isHovered ? const Color(0xFF172A3A) : const Color(0xFF102431),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: _isHovered
                ? const Color(0xFF38BDF8)
                : const Color(0xFF24475D),
            width: _isHovered ? 1.6 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              widget.icon,
              color: _isHovered ? const Color(0xFF38BDF8) : Colors.white70,
              size: 28,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    widget.subtitle,
                    style: const TextStyle(color: Colors.white60, fontSize: 14),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white54,
              size: 18,
            ),
          ],
        ),
      ),
    ),
  );
}
