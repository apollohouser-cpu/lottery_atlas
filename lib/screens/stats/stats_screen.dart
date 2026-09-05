import 'package:flutter/material.dart';

import '../../models/lottery_activity.dart';
import '../../services/lottery_activity_repository.dart';
import '../../widgets/map/map_filter_state.dart';

class StatsScreen extends StatelessWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final activity = LotteryActivityRepository.activity;
    final totalTickets = activity.fold<int>(
      0,
      (total, item) => total + item.winningTickets,
    );
    final totalPrize = activity.fold<int>(
      0,
      (total, item) => total + item.prizeAmount,
    );
    final stateTotals = _totalsByState(activity);
    final gameTotals = _totalsByGame(activity);
    if (activity.isEmpty) {
      return Scaffold(
        backgroundColor: const Color(0xFF071827),
        appBar: AppBar(
          backgroundColor: const Color(0xFF071827),
          foregroundColor: Colors.white,
          title: const Text('Lottery Stats'),
        ),
        body: const Center(
          child: Padding(
            padding: EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.insights_outlined,
                  color: Color(0xFF60A5FA),
                  size: 42,
                ),
                SizedBox(height: 14),
                Text(
                  'Verified map activity is loading',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Stats will appear once an official lottery activity feed is available. Lottery Atlas does not substitute sample winners or retailer locations.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.white70, height: 1.4),
                ),
              ],
            ),
          ),
        ),
      );
    }
    final leadingState = stateTotals.first;
    final leadingGame = gameTotals.first;

    return Scaffold(
      backgroundColor: const Color(0xFF071827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071827),
        foregroundColor: Colors.white,
        title: const Text('Lottery Stats'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
        children: [
          const Text(
            'NATIONAL SNAPSHOT',
            style: TextStyle(
              color: Color(0xFF60A5FA),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  icon: Icons.confirmation_number_rounded,
                  label: 'WINNING TICKETS',
                  value: _formatCount(totalTickets),
                  accent: const Color(0xFF1478FF),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  icon: Icons.workspace_premium_rounded,
                  label: 'TOP PRIZE TOTAL',
                  value: _formatMoney(totalPrize),
                  accent: const Color(0xFFFFC107),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              color: const Color(0xFF102638),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF355066)),
            ),
            child: Row(
              children: [
                const CircleAvatar(
                  radius: 26,
                  backgroundColor: Color(0x332CC36B),
                  child: Icon(
                    Icons.emoji_events_rounded,
                    color: Color(0xFF2CC36B),
                    size: 30,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'MOST WINNING STATE',
                        style: TextStyle(
                          color: Colors.white54,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        leadingState.key,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 25,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      Text(
                        '${_formatCount(leadingState.value)} winning tickets',
                        style: const TextStyle(color: Colors.white60),
                      ),
                    ],
                  ),
                ),
                Text(
                  leadingState.key,
                  style: const TextStyle(
                    color: Color(0xFF2CC36B),
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const _SectionTitle('Top states'),
          const SizedBox(height: 10),
          ...stateTotals
              .take(5)
              .toList()
              .asMap()
              .entries
              .map(
                (entry) => _RankingRow(
                  rank: entry.key + 1,
                  label: entry.value.key,
                  value: entry.value.value,
                  maximum: leadingState.value,
                  color: const Color(0xFF1478FF),
                ),
              ),
          const SizedBox(height: 22),
          const _SectionTitle('Game activity'),
          const SizedBox(height: 10),
          ...gameTotals.asMap().entries.map(
            (entry) => _RankingRow(
              rank: entry.key + 1,
              label: entry.value.key.label,
              value: entry.value.value,
              maximum: leadingGame.value,
              color: _gameColor(entry.value.key),
              showRank: false,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Sample activity data — this screen will update automatically once official lottery sources are connected.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white54, fontSize: 12),
          ),
        ],
      ),
    );
  }

  static List<MapEntry<String, int>> _totalsByState(
    List<LotteryActivity> activity,
  ) {
    final totals = <String, int>{};
    for (final item in activity) {
      totals.update(
        item.state,
        (total) => total + item.winningTickets,
        ifAbsent: () => item.winningTickets,
      );
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  static List<MapEntry<LotteryGame, int>> _totalsByGame(
    List<LotteryActivity> activity,
  ) {
    final totals = <LotteryGame, int>{};
    for (final item in activity) {
      totals.update(
        item.game,
        (total) => total + item.winningTickets,
        ifAbsent: () => item.winningTickets,
      );
    }
    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    return entries;
  }

  static String _formatCount(int value) => value.toString();

  static String _formatMoney(int value) {
    if (value >= 1000000) {
      return '\$${(value / 1000000).toStringAsFixed(1)}M';
    }
    return '\$${(value / 1000).toStringAsFixed(0)}K';
  }

  static Color _gameColor(LotteryGame game) {
    switch (game) {
      case LotteryGame.powerball:
        return const Color(0xFFE94B6A);
      case LotteryGame.megaMillions:
        return const Color(0xFFFFC107);
      case LotteryGame.scratchOff:
        return const Color(0xFF2CC36B);
      case LotteryGame.stateDraw:
        return const Color(0xFF7C5CFC);
      case LotteryGame.allGames:
        return const Color(0xFF1478FF);
    }
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.accent,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF102638),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF355066)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: accent),
          const SizedBox(height: 18),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 25,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            label,
            style: const TextStyle(color: Colors.white54, fontSize: 10),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
    text.toUpperCase(),
    style: const TextStyle(
      color: Colors.white,
      fontSize: 17,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _RankingRow extends StatelessWidget {
  const _RankingRow({
    required this.rank,
    required this.label,
    required this.value,
    required this.maximum,
    required this.color,
    this.showRank = true,
  });

  final int rank;
  final String label;
  final int value;
  final int maximum;
  final Color color;
  final bool showRank;

  @override
  Widget build(BuildContext context) {
    final progress = maximum == 0 ? 0.0 : value / maximum;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          SizedBox(
            width: showRank ? 28 : 0,
            child: showRank
                ? Text(
                    '$rank',
                    style: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : null,
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(label, style: const TextStyle(color: Colors.white)),
                    Text(
                      '$value',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 7,
                    color: color,
                    backgroundColor: const Color(0xFF263C4F),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
