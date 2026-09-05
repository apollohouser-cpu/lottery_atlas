import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/favorite_lottery_game.dart';
import '../../models/lottery_activity.dart';
import '../../services/favorite_games_service.dart';
import '../../services/lottery_activity_repository.dart';
import '../../services/map_focus_service.dart';
import '../../services/state_lottery_source_registry.dart';
import '../../services/south_carolina_lottery_map_filter_service.dart';
import '../../services/south_carolina_scratch_map_filter_service.dart';
import 'south_carolina_data_coverage_screen.dart';
import 'south_carolina_retailers_screen.dart';
import 'south_carolina_scratch_offs_screen.dart';

/// South Carolina's official lottery information is currently published on
/// the SC Education Lottery website, rather than through a documented public
/// data API. This screen links directly to those official resources instead
/// of attempting to scrape a consumer-facing website.
class SouthCarolinaLotteryScreen extends StatelessWidget {
  const SouthCarolinaLotteryScreen({super.key});

  Future<void> _openOfficialResource(BuildContext context, String url) async {
    final launched = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the official lottery site.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final source = StateLotterySourceRegistry.forState('South Carolina')!;
    return Scaffold(
      backgroundColor: const Color(0xFF071827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071827),
        foregroundColor: Colors.white,
        title: const Text('South Carolina Lottery'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF102638),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: const Color(0xFF355066)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'OFFICIAL SOUTH CAROLINA SOURCE',
                  style: TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 12,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Results and game details are opened directly from the South Carolina Education Lottery. Always verify a ticket with the official lottery.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          _MapActivityCard(
            onShowAll: () => _showAllSouthCarolinaActivity(context),
            onOpenCoverage: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SouthCarolinaDataCoverageScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          _RetailerClaimLocationsCard(
            onOpen: () {
              Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => const SouthCarolinaRetailersScreen(),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
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
                  'SCRATCH-OFF PRIZE FINDER',
                  style: TextStyle(
                    color: Color(0xFF60A5FA),
                    fontSize: 12,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Browse every game in the verified daily SC Scratch-Off winners snapshot. Filter a specific game by the prize amount you want to explore.',
                  style: TextStyle(color: Colors.white70, height: 1.35),
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) =>
                              const SouthCarolinaScratchOffsScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.confirmation_number_outlined),
                    label: const Text('Browse Scratch-Off prize tiers'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1478FF),
                      foregroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => _showAllScratchActivity(context),
                    icon: const Icon(Icons.map_outlined),
                    label: const Text('Show all Scratch-Off activity on map'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFF355066)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'DRAW GAMES — MAP FILTERS & SCHEDULE',
            style: TextStyle(
              color: Color(0xFF60A5FA),
              fontSize: 12,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          _ScheduleCard(
            icon: Icons.looks_3_outlined,
            title: 'Pick 3 Plus FIREBALL',
            time: 'Daily · 12:59 PM and 6:59 PM ET',
            note: 'No midday drawing on Sundays or Christmas Day.',
            onTap: () => _showDrawGame(context, 'Pick 3'),
          ),
          _ScheduleCard(
            icon: Icons.looks_4_outlined,
            title: 'Pick 4 Plus FIREBALL',
            time: 'Daily · 12:59 PM and 6:59 PM ET',
            note: 'No midday drawing on Sundays or Christmas Day.',
            onTap: () => _showDrawGame(context, 'Pick 4'),
          ),
          _ScheduleCard(
            icon: Icons.bolt_rounded,
            title: 'CASH POP',
            time: 'Daily · 12:59 PM and 6:59 PM ET',
            note: 'No midday drawing on Sundays or Christmas Day.',
            onTap: () => _showDrawGame(context, 'Cash Pop'),
          ),
          _ScheduleCard(
            icon: Icons.star_outline_rounded,
            title: 'Palmetto Cash 5',
            time: 'Daily · 6:59 PM ET',
            onTap: () => _showDrawGame(context, 'Palmetto Cash 5'),
          ),
          _ScheduleCard(
            icon: Icons.circle_outlined,
            title: 'Powerball',
            time: 'Mon, Wed, Sat · 10:59 PM ET',
            onTap: () => _showDrawGame(context, 'Powerball'),
          ),
          _ScheduleCard(
            icon: Icons.auto_awesome_outlined,
            title: 'Mega Millions',
            time: 'Tue, Fri · 11:00 PM ET',
            onTap: () => _showDrawGame(context, 'Mega Millions'),
          ),
          const SizedBox(height: 20),
          const Text(
            'OFFICIAL RESOURCES',
            style: TextStyle(
              color: Color(0xFF60A5FA),
              fontSize: 12,
              letterSpacing: 1.1,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 10),
          ...source.resources.map(
            (resource) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _ResourceButton(
                resource: resource,
                onTap: () => _openOfficialResource(context, resource.url),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showAllSouthCarolinaActivity(BuildContext context) {
    SouthCarolinaScratchMapFilterService.clear();
    SouthCarolinaLotteryMapFilterService.apply(
      const SouthCarolinaLotteryMapFilter.all(),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _showAllScratchActivity(BuildContext context) {
    SouthCarolinaLotteryMapFilterService.clear();
    SouthCarolinaScratchMapFilterService.apply(
      const SouthCarolinaScratchMapFilter(
        gameId: 'all',
        minimumPrize: 1,
        maximumPrize: 2500000,
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  Future<void> _showDrawGame(BuildContext context, String gameName) async {
    final filter = SouthCarolinaLotteryMapFilter.drawGames.firstWhere(
      (item) => item.gameName == gameName,
    );

    final activity = LotteryActivityRepository.activity
        .where(filter.matches)
        .toList(growable: false);
    final selected = await showModalBottomSheet<bool>(
      context: context,
      backgroundColor: const Color(0xFF0B1D2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (_) => _SouthCarolinaDrawGameSheet(
        gameName: gameName,
        activity: activity,
        onCountySelected: (selectedActivity) {
          SouthCarolinaScratchMapFilterService.clear();
          SouthCarolinaLotteryMapFilterService.apply(filter);
          MapFocusService.focusCity(
            stateName: 'South Carolina',
            city: selectedActivity.city,
            location: selectedActivity.location,
          );
          Navigator.of(context).popUntil((route) => route.isFirst);
        },
      ),
    );

    if (selected != true || !context.mounted) return;
    SouthCarolinaScratchMapFilterService.clear();
    SouthCarolinaLotteryMapFilterService.apply(filter);
    Navigator.of(context).popUntil((route) => route.isFirst);
  }
}

class _SouthCarolinaDrawGameSheet extends StatelessWidget {
  const _SouthCarolinaDrawGameSheet({
    required this.gameName,
    required this.activity,
    required this.onCountySelected,
  });

  final String gameName;
  final List<LotteryActivity> activity;
  final ValueChanged<LotteryActivity> onCountySelected;

  String _prizeLabel(int amount) {
    if (amount >= 1000000) return '\$${amount ~/ 1000000}M';
    if (amount >= 1000) return '\$${amount ~/ 1000}K';
    return '\$$amount';
  }

  @override
  Widget build(BuildContext context) {
    final counties = activity.map((item) => item.county).toSet().length;
    final tickets = activity.fold<int>(
      0,
      (total, item) => total + item.winningTickets,
    );
    final highestPrize = activity.fold<int>(
      0,
      (highest, item) =>
          item.prizeAmount > highest ? item.prizeAmount : highest,
    );
    final latestDate = activity.isEmpty
        ? null
        : (activity.map((item) => item.drawDate).toList()
                ..sort((a, b) => b.compareTo(a)))
              .first;
    final countyActivity = <String, _CountyGameActivity>{};
    for (final record in activity) {
      final key = record.county.trim().toLowerCase();
      countyActivity.update(
        key,
        (summary) => summary.add(record),
        ifAbsent: () => _CountyGameActivity.from(record),
      );
    }
    final topCounties = countyActivity.values.toList()
      ..sort(
        (first, second) =>
            second.winningTickets.compareTo(first.winningTickets),
      );

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 14, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
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
            Row(
              children: [
                const Icon(Icons.schedule_rounded, color: Color(0xFF60A5FA)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    gameName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 21,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            const Text(
              'South Carolina draw-game activity from the published official claim report.',
              style: TextStyle(color: Colors.white70, height: 1.3),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _Metric(
                  label: 'QUALIFYING RECORDS',
                  value: '${activity.length}',
                ),
                const SizedBox(width: 10),
                _Metric(label: 'COUNTIES', value: '$counties'),
                const SizedBox(width: 10),
                _Metric(label: 'TICKETS', value: '$tickets'),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF102638),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF355066)),
              ),
              child: Text(
                activity.isEmpty
                    ? 'There are no matching qualifying records in the current published feed.'
                    : 'Highest qualifying prize: ${_prizeLabel(highestPrize)}${latestDate == null ? '' : ' · Latest report: ${latestDate.month}/${latestDate.day}/${latestDate.year}'}',
                style: const TextStyle(color: Colors.white70, height: 1.3),
              ),
            ),
            if (topCounties.isNotEmpty) ...[
              const SizedBox(height: 18),
              const Text(
                'TOP COUNTIES FOR THIS GAME',
                style: TextStyle(
                  color: Color(0xFF93C5FD),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              ...topCounties
                  .take(3)
                  .map(
                    (county) => Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () => onCountySelected(county.representative),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 4,
                            vertical: 8,
                          ),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.location_on_outlined,
                                size: 18,
                                color: Color(0xFF60A5FA),
                              ),
                              const SizedBox(width: 9),
                              Expanded(
                                child: Text(
                                  '${county.county} County · ${county.winningTickets} ticket${county.winningTickets == 1 ? '' : 's'}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.map_outlined,
                                size: 18,
                                color: Colors.white54,
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              const Text(
                'Tap a county to open its reported game activity on the map.',
                style: TextStyle(color: Colors.white54, fontSize: 11),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () => Navigator.of(context).pop(true),
                icon: const Icon(Icons.map_outlined),
                label: const Text('Show this game on the heat map'),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF1478FF),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Map activity includes qualifying claims reported by the official South Carolina Education Lottery; it is not a complete list of every ticket sold or won.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 11,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountyGameActivity {
  _CountyGameActivity.from(LotteryActivity activity)
    : county = activity.county,
      winningTickets = activity.winningTickets,
      representative = activity;

  final String county;
  int winningTickets;
  LotteryActivity representative;

  _CountyGameActivity add(LotteryActivity activity) {
    winningTickets += activity.winningTickets;
    if (activity.drawDate.isAfter(representative.drawDate)) {
      representative = activity;
    }
    return this;
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF102638),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF355066)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(
              color: Color(0xFF60A5FA),
              fontWeight: FontWeight.w800,
              fontSize: 17,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 8,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5,
            ),
          ),
        ],
      ),
    ),
  );
}

class _MapActivityCard extends StatelessWidget {
  const _MapActivityCard({
    required this.onShowAll,
    required this.onOpenCoverage,
  });

  final VoidCallback onShowAll;
  final VoidCallback onOpenCoverage;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF0D2A30),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF1FAF77)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'SOUTH CAROLINA HEAT MAP',
          style: TextStyle(
            color: Color(0xFF86EFAC),
            fontSize: 12,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Explore official reported South Carolina claims by game, county, and date. The map uses county-centered placements so the heat index remains county-focused.',
          style: TextStyle(color: Colors.white70, height: 1.35),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: onShowAll,
            icon: const Icon(Icons.map_outlined),
            label: const Text('Show all SC activity on map'),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF1FAF77),
              foregroundColor: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onOpenCoverage,
            icon: const Icon(Icons.fact_check_outlined),
            label: const Text('Review SC map data coverage'),
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

class _RetailerClaimLocationsCard extends StatelessWidget {
  const _RetailerClaimLocationsCard({required this.onOpen});

  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) => Container(
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
        const Text(
          'Browse South Carolina retailers connected to verified reported claims. These pins stay separate from the county heat index.',
          style: TextStyle(color: Colors.white70, height: 1.35),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: onOpen,
            icon: const Icon(Icons.storefront_outlined),
            label: const Text('Browse retailer claim locations'),
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

class _ResourceButton extends StatelessWidget {
  const _ResourceButton({required this.resource, required this.onTap});

  final StateLotteryResource resource;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xFF102638),
    borderRadius: BorderRadius.circular(16),
    child: InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF355066)),
        ),
        child: Row(
          children: [
            Icon(_iconFor(resource.title), color: const Color(0xFF60A5FA)),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    resource.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    resource.subtitle,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.open_in_new_rounded, color: Colors.white54),
          ],
        ),
      ),
    ),
  );

  IconData _iconFor(String title) {
    if (title.contains('Scratch-Off winners')) {
      return Icons.celebration_outlined;
    }
    if (title.contains('Remaining')) return Icons.workspace_premium_outlined;
    if (title.contains('Drawing')) return Icons.schedule_rounded;
    if (title.contains('games')) return Icons.confirmation_number_outlined;
    return Icons.emoji_events_outlined;
  }
}

class _ScheduleCard extends StatelessWidget {
  const _ScheduleCard({
    required this.icon,
    required this.title,
    required this.time,
    this.note,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String time;
  final String? note;
  final VoidCallback? onTap;

  FavoriteLotteryGame get _favoriteGame => FavoriteLotteryGame(
    key:
        'state-draw:sc:${title.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-')}',
    gameId: title,
    name: title,
    subtitle: 'South Carolina draw game',
    kind: FavoriteLotteryGameKind.stateDraw,
  );

  Future<void> _toggleFavorite(BuildContext context) async {
    final isSaved = await FavoriteGamesService.toggle(_favoriteGame);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSaved
              ? '$title saved to favorite games.'
              : '$title removed from favorite games.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    FavoriteGamesService.load();
    return ValueListenableBuilder<List<FavoriteLotteryGame>>(
      valueListenable: FavoriteGamesService.games,
      builder: (context, favoriteGames, _) {
        final isFavorite = favoriteGames.any(
          (game) => game.key == _favoriteGame.key,
        );
        return Material(
          color: const Color(0xFF102638),
          borderRadius: BorderRadius.circular(14),
          child: InkWell(
            borderRadius: BorderRadius.circular(14),
            onTap: onTap,
            child: Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFF355066)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: const Color(0xFF86EFAC)),
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
                          time,
                          style: const TextStyle(color: Colors.white70),
                        ),
                        if (note != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            note!,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (onTap != null)
                    const Icon(Icons.map_outlined, color: Color(0xFF60A5FA)),
                  IconButton(
                    tooltip: isFavorite
                        ? 'Remove from favorite games'
                        : 'Save to favorite games',
                    onPressed: () => _toggleFavorite(context),
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                      color: isFavorite
                          ? const Color(0xFFE94B6A)
                          : Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
