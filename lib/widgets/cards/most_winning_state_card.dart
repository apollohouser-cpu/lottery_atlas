import '../map/map_filter_state.dart';
import 'package:flutter/material.dart';

import '../../services/map_focus_service.dart';
import '../../services/map_ranking_service.dart';

/// Timeline-aware top-five rankings for the exact activity visible on the map.
/// The same card drills from states to counties, cities, retailers, and games.
class MostWinningStateCard extends StatefulWidget {
  const MostWinningStateCard({super.key});

  @override
  State<MostWinningStateCard> createState() => _MostWinningStateCardState();
}

class _MostWinningStateCardState extends State<MostWinningStateCard> {
  MapRankingLevel? _level;
  RankingGameKind _kind = RankingGameKind.all;
  String? _gameName;
  String? _state;
  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<MapRankingSnapshot>(
      valueListenable: MapRankingService.snapshot,
      builder: (context, source, _) {
        if (_state != source.stateName) {
          _state = source.stateName;
          _level = null;
          _kind = RankingGameKind.all;
          _gameName = null;
        }
        final level = source.stateName == null
            ? MapRankingLevel.state
            : (_level ?? source.level);
        final snapshot =
            _level == null && _kind == RankingGameKind.all && _gameName == null
            ? source
            : source.forRanking(level, kind: _kind, gameName: _gameName);
        final available =
            source
                .forRanking(level, kind: _kind)
                .records
                .map((r) => r.gameName ?? r.game.label)
                .toSet()
                .toList()
              ..sort();
        if (_gameName != null && !available.contains(_gameName)) {
          available.add(_gameName!);
        }
        final rankings = MapRankingService.rankings(snapshot);
        // Reserve all five slots even when a timeline frame has no results.
        // Otherwise the home ListView clamps its offset as this card shrinks.
        final scaler = MediaQuery.textScalerOf(context);
        final rowHeight = (scaler.scale(16) * 1.5 + scaler.scale(10) * 1.5 + 22)
            .clamp(64.0, double.infinity);
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1D2C),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF456074)),
          ),
          child: Material(
            color: Colors.transparent,
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
                    Text(
                      snapshot.stateName == 'Colorado'
                          ? 'REPORTED RECORDS'
                          : (snapshot.stateName == 'Texas' ||
                                snapshot.stateName == 'Kentucky')
                          ? 'PUBLISHED RECORDS'
                          : 'WINNING TICKETS',
                      style: const TextStyle(
                        color: Colors.white38,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                if (snapshot.stateName == 'Texas')
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Selected Scratch top-prize claims and selected draw-game Where Sold records with verified retailer matches only. '
                      'Rankings reflect the current filters, not all Texas wins or all prize tiers.',
                      style: TextStyle(color: Color(0xFFFDE68A), fontSize: 11),
                    ),
                  ),
                if (snapshot.stateName == 'Colorado')
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Counts are selected retailer-matched winner records, not verified distinct tickets. '
                      'Includes retained historical records; not complete statewide claims. '
                      'Dates are source dates with unverified draw, claim or publication meanings.',
                      style: TextStyle(color: Color(0xFFFDE68A), fontSize: 11),
                    ),
                  ),
                if (snapshot.stateName == 'Kentucky')
                  const Padding(
                    padding: EdgeInsets.only(bottom: 10),
                    child: Text(
                      'Selected official winner records dated January 1, 2026 onward with verified retailer matches only. '
                      'Rankings reflect the current filters, not all Kentucky wins or all prize tiers. '
                      'Statewide draw summaries are separate and do not add retailer wins.',
                      style: TextStyle(color: Color(0xFFFDE68A), fontSize: 11),
                    ),
                  ),
                if (source.stateName != null)
                  Wrap(
                    spacing: 12,
                    runSpacing: 8,
                    children: [
                      DropdownButton<MapRankingLevel>(
                        key: const ValueKey('ranking-category'),
                        isExpanded: true,
                        itemHeight: null,
                        value: level,
                        dropdownColor: const Color(0xFF0B1D2C),
                        items: const [
                          DropdownMenuItem(
                            value: MapRankingLevel.county,
                            child: Text('Counties'),
                          ),
                          DropdownMenuItem(
                            value: MapRankingLevel.city,
                            child: Text('Cities / towns'),
                          ),
                          DropdownMenuItem(
                            value: MapRankingLevel.game,
                            child: Text('Games'),
                          ),
                          DropdownMenuItem(
                            value: MapRankingLevel.retailer,
                            child: Text('Retailers'),
                          ),
                        ],
                        onChanged: (v) => setState(() => _level = v),
                      ),
                      DropdownButton<RankingGameKind>(
                        key: const ValueKey('ranking-game-kind'),
                        isExpanded: true,
                        itemHeight: null,
                        value: _kind,
                        dropdownColor: const Color(0xFF0B1D2C),
                        items: const [
                          DropdownMenuItem(
                            value: RankingGameKind.all,
                            child: Text('All games'),
                          ),
                          DropdownMenuItem(
                            value: RankingGameKind.drawings,
                            child: Text('Drawings'),
                          ),
                          DropdownMenuItem(
                            value: RankingGameKind.scratchOff,
                            child: Text('Scratch-Offs'),
                          ),
                        ],
                        onChanged: (v) => setState(() {
                          _level = level;
                          _kind = v!;
                          _gameName = null;
                        }),
                      ),
                      SizedBox(
                        width: 240,
                        child: DropdownButton<String>(
                          key: const ValueKey('ranking-game-name'),
                          isExpanded: true,
                          value: available.contains(_gameName)
                              ? _gameName
                              : null,
                          hint: const Text('All matching game names'),
                          dropdownColor: const Color(0xFF0B1D2C),
                          items: [
                            const DropdownMenuItem<String>(
                              value: null,
                              child: Text('All matching game names'),
                            ),
                            ...available.map(
                              (g) => DropdownMenuItem(
                                value: g,
                                child: Text(g, overflow: TextOverflow.ellipsis),
                              ),
                            ),
                          ],
                          onChanged: (v) => setState(() {
                            _level = level;
                            _gameName = v;
                          }),
                        ),
                      ),
                    ],
                  ),
                const Text(
                  'Verified published activity in the selected timeline; coverage varies. Missing data is not zero wins.',
                  style: TextStyle(color: Colors.white60, fontSize: 11),
                ),
                SizedBox(
                  key: const ValueKey('ranking-slots'),
                  height: rowHeight * 5,
                  child: rankings.isEmpty
                      ? const Align(
                          alignment: Alignment.topLeft,
                          child: Padding(
                            padding: EdgeInsets.symmetric(vertical: 24),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline_rounded,
                                  color: Colors.white38,
                                ),
                                SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    'No verified activity matches the current map and timeline filters.',
                                    style: TextStyle(color: Colors.white60),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      : Column(
                          children: rankings.indexed
                              .map(
                                (ranked) => SizedBox(
                                  height: rowHeight,
                                  child: Center(
                                    child: _rankingRow(
                                      snapshot: snapshot,
                                      rank: ranked.$1 + 1,
                                      entry: ranked.$2,
                                      showDivider:
                                          ranked.$1 < rankings.length - 1,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                ),
              ],
            ),
          ),
        );
      },
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
    if (snapshot.stateName == 'Texas' || snapshot.stateName == 'Kentucky') {
      return switch (snapshot.level) {
        MapRankingLevel.county =>
          'TOP COUNTIES BY PUBLISHED RECORDS · ${snapshot.stateName}',
        MapRankingLevel.city =>
          'TOP CITIES BY PUBLISHED RECORDS · ${snapshot.countyName ?? snapshot.stateName}',
        MapRankingLevel.retailer =>
          'TOP RETAILERS BY PUBLISHED RECORDS · ${snapshot.cityName ?? snapshot.stateName}',
        MapRankingLevel.game =>
          'GAMES BY PUBLISHED RECORDS · ${snapshot.retailerName ?? snapshot.stateName}',
        MapRankingLevel.state => 'TOP 5 WINNING STATES',
      };
    }
    return switch (snapshot.level) {
      MapRankingLevel.state => 'TOP 5 WINNING STATES',
      MapRankingLevel.county =>
        'TOP 5 WINNING COUNTIES · ${snapshot.stateName}',
      MapRankingLevel.city =>
        'TOP 5 WINNING CITIES / TOWNS · ${snapshot.countyName ?? snapshot.stateName}',
      MapRankingLevel.retailer =>
        'TOP 5 WINNING RETAILERS · ${snapshot.cityName ?? snapshot.stateName}',
      MapRankingLevel.game =>
        'MOST WINNING GAMES · ${snapshot.retailerName ?? snapshot.stateName}',
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
