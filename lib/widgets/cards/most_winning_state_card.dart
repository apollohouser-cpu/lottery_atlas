import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/state_winning_ticket_total.dart';
import '../../services/map_focus_service.dart';
import '../../services/map_ranking_service.dart';
import '../../services/state_navigation_service.dart';
import '../../services/state_winning_ticket_total_service.dart';

/// Timeline-aware top-five rankings for the exact activity visible on the map.
/// The same card drills from states to counties, cities, retailers, and games.
class MostWinningStateCard extends StatelessWidget {
  const MostWinningStateCard({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MapRankingSnapshot>(
      valueListenable: MapRankingService.snapshot,
      builder: (context, snapshot, _) {
        final rankings = MapRankingService.rankings(snapshot);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1D2C),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF456074)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1478FF).withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.leaderboard_rounded,
                      color: Color(0xFF60A5FA),
                    ),
                  ),
                  const SizedBox(width: 11),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _heading(snapshot),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _rangeLabel(snapshot),
                          style: const TextStyle(
                            color: Color(0xFF93C5FD),
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Text(
                    'WINNING TICKETS',
                    style: TextStyle(
                      color: Colors.white38,
                      fontSize: 9,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (snapshot.level == MapRankingLevel.state)
                ValueListenableBuilder<List<StateWinningTicketTotal>>(
                  valueListenable: StateWinningTicketTotalService.totals,
                  builder: (context, totals, _) => _officialTotals(totals),
                ),
              if (rankings.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded, color: Colors.white38),
                      SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'No verified activity matches the current map and timeline filters.',
                          style: TextStyle(color: Colors.white60),
                        ),
                      ),
                    ],
                  ),
                )
              else
                ...rankings.indexed.map(
                  (ranked) => _rankingRow(
                    snapshot: snapshot,
                    rank: ranked.$1 + 1,
                    entry: ranked.$2,
                    showDivider: ranked.$1 < rankings.length - 1,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _officialTotals(List<StateWinningTicketTotal> totals) {
    if (totals.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 10),
        child: Text(
          'Statewide winning-ticket totals are awaiting verified official feeds. Retailer locations cannot be inferred from game counts.',
          style: TextStyle(color: Color(0xFFFDE68A), fontSize: 11),
        ),
      );
    }
    final sorted = [...totals]..sort((a, b) => b.count.compareTo(a.count));
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'OFFICIAL STATE TOTALS · SOURCE PERIODS VARY',
          style: TextStyle(
            color: Color(0xFFFDE68A),
            fontSize: 10,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Counts include only the games and prize tiers each source reports. Rankings may not be directly comparable. Retailer locations are not verified by these totals.',
          style: TextStyle(color: Colors.white60, fontSize: 10),
        ),
        const SizedBox(height: 7),
        for (final total in sorted.take(5))
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            title: Text(
              '${StateNavigationService.getStateByAbbreviation(total.state)?.name ?? total.state}  ·  ${_numberText(total.count)}',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
            subtitle: Text(
              '${total.coverage} · through ${_month(total.periodEnd.month)} ${total.periodEnd.day}, ${total.periodEnd.year} · source ${_month(total.sourceDate.month)} ${total.sourceDate.day}',
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
            trailing: const Icon(
              Icons.open_in_new,
              size: 15,
              color: Colors.white54,
            ),
            onTap: () => launchUrl(Uri.parse(total.sourceUrl)),
          ),
        const Divider(color: Colors.white24),
        const Text(
          'LOCATION-VERIFIED RANKINGS',
          style: TextStyle(color: Color(0xFF93C5FD), fontSize: 10),
        ),
        const SizedBox(height: 6),
      ],
    );
  }

  Widget _rankingRow({
    required MapRankingSnapshot snapshot,
    required int rank,
    required MapRankingEntry entry,
    required bool showDivider,
  }) {
    final canOpen =
        snapshot.level != MapRankingLevel.game &&
        (snapshot.level != MapRankingLevel.county || entry.countyId != null);
    final games = entry.gameBreakdown.entries
        .take(3)
        .map((game) => '${game.key} ${_numberText(game.value)}');
    final breakdown = snapshot.level == MapRankingLevel.game
        ? '${entry.records} published ${entry.records == 1 ? 'record' : 'records'}'
        : games.join('  ·  ');

    return Column(
      children: [
        Material(
          color: Colors.transparent,
          child: InkWell(
            borderRadius: BorderRadius.circular(13),
            onTap: canOpen ? () => _open(snapshot, entry) : null,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 9),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: rank == 1
                          ? const Color(0x33F5B301)
                          : const Color(0x1A60A5FA),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: rank == 1
                            ? const Color(0xFFF5B301)
                            : const Color(0xFF456074),
                      ),
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        color: rank == 1
                            ? const Color(0xFFFFD54F)
                            : const Color(0xFF93C5FD),
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          breakdown.isEmpty
                              ? 'Game details unavailable'
                              : breakdown,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        _numberText(entry.winningTickets),
                        style: const TextStyle(
                          color: Color(0xFF60A5FA),
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      Text(
                        '${_prizeText(entry.publishedPrizeTotal)} prizes',
                        style: const TextStyle(
                          color: Color(0xFF4ADE80),
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                  if (canOpen) ...[
                    const SizedBox(width: 3),
                    const Icon(
                      Icons.chevron_right_rounded,
                      color: Colors.white38,
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
        if (showDivider) const Divider(height: 1, color: Colors.white10),
      ],
    );
  }

  void _open(MapRankingSnapshot snapshot, MapRankingEntry entry) {
    switch (snapshot.level) {
      case MapRankingLevel.state:
        if (entry.stateName != null) {
          MapFocusService.focusState(entry.stateName!);
        }
      case MapRankingLevel.county:
        if (entry.stateName != null && entry.countyId != null) {
          MapFocusService.focusCounty(
            stateName: entry.stateName!,
            countyId: entry.countyId!,
          );
        }
      case MapRankingLevel.city:
        if (entry.stateName != null) {
          MapFocusService.focusCity(
            stateName: entry.stateName!,
            city: entry.label,
            location: entry.location,
            countyId: entry.countyId,
          );
        }
      case MapRankingLevel.retailer:
        if (entry.stateName != null && entry.retailerActivityId != null) {
          MapFocusService.focusRetailer(
            stateName: entry.stateName!,
            retailerId: entry.retailerActivityId!,
          );
        }
      case MapRankingLevel.game:
        break;
    }
  }

  String _heading(MapRankingSnapshot snapshot) {
    return switch (snapshot.level) {
      MapRankingLevel.state => 'TOP 5 WINNING STATES',
      MapRankingLevel.county =>
        'TOP 5 WINNING COUNTIES · ${snapshot.stateName}',
      MapRankingLevel.city =>
        'TOP 5 WINNING CITIES / TOWNS · ${snapshot.countyName}',
      MapRankingLevel.retailer =>
        'TOP 5 WINNING RETAILERS · ${snapshot.cityName}',
      MapRankingLevel.game => 'MOST WINNING GAMES · ${snapshot.retailerName}',
    };
  }

  String _rangeLabel(MapRankingSnapshot snapshot) {
    final start = snapshot.dateRangeStart;
    final end = snapshot.dateRangeEnd;
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day &&
        start.hour == end.hour) {
      return '${_month(start.month)} ${start.day}, ${start.year} · ${_hour(start.hour)}';
    }
    if (start.year == end.year &&
        start.month == end.month &&
        start.day == end.day) {
      return '${_month(start.month)} ${start.day}, ${start.year}';
    }
    return '${_month(start.month)} ${start.day} – ${_month(end.month)} ${end.day}, ${end.year}';
  }

  String _month(int month) => const <String>[
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  String _hour(int hour) {
    final display = hour % 12 == 0 ? 12 : hour % 12;
    return '$display ${hour < 12 ? 'AM' : 'PM'}';
  }

  String _numberText(int value) {
    final raw = value.toString();
    final buffer = StringBuffer();
    for (var index = 0; index < raw.length; index++) {
      if (index > 0 && (raw.length - index) % 3 == 0) buffer.write(',');
      buffer.write(raw[index]);
    }
    return buffer.toString();
  }

  String _prizeText(int amount) {
    if (amount >= 1000000000) {
      return '\$${(amount / 1000000000).toStringAsFixed(1)}B';
    }
    if (amount >= 1000000) {
      return '\$${(amount / 1000000).toStringAsFixed(amount % 1000000 == 0 ? 0 : 1)}M';
    }
    if (amount >= 1000) return '\$${(amount / 1000).toStringAsFixed(0)}K';
    return '\$$amount';
  }
}
