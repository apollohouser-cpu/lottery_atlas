import 'package:flutter/material.dart';

import '../../models/lottery_activity.dart';
import '../../services/lottery_activity_repository.dart';
import '../../services/map_focus_service.dart';
import '../../services/state_navigation_service.dart';

/// A small, honest summary of the activity currently published to the map.
/// It intentionally avoids presenting sample or cached records as official
/// statewide lottery totals.
class MostWinningStateCard extends StatefulWidget {
  const MostWinningStateCard({super.key});

  @override
  State<MostWinningStateCard> createState() => _MostWinningStateCardState();
}

class _MostWinningStateCardState extends State<MostWinningStateCard> {
  int _currentIndex = 0;

  List<_ActiveState> _rankedStates() {
    final grouped = <String, List<LotteryActivity>>{};
    for (final activity in LotteryActivityRepository.activity) {
      grouped.putIfAbsent(activity.state, () => <LotteryActivity>[]).add(activity);
    }

    final states = grouped.entries.map((entry) {
      final records = entry.value;
      final tickets = records.fold<int>(
        0,
        (total, activity) => total + activity.winningTickets,
      );
      final topPrize = records.reduce(
        (highest, activity) => activity.prizeAmount > highest.prizeAmount
            ? activity
            : highest,
      );
      final state = StateNavigationService.getStateByAbbreviation(entry.key);

      return _ActiveState(
        abbreviation: entry.key,
        name: state?.name ?? entry.key,
        records: records.length,
        tickets: tickets,
        topPrize: topPrize.prizeAmount,
      );
    }).toList();

    states.sort((left, right) {
      final ticketOrder = right.tickets.compareTo(left.tickets);
      return ticketOrder != 0 ? ticketOrder : right.records.compareTo(left.records);
    });
    return states;
  }

  void _changeState(int direction, int stateCount) {
    setState(() {
      _currentIndex = (_currentIndex + direction) % stateCount;
      if (_currentIndex < 0) _currentIndex = stateCount - 1;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<int>(
      valueListenable: LotteryActivityRepository.changes,
      builder: (context, _, _) {
        final states = _rankedStates();
        if (states.isEmpty) return _emptyCard();

        final index = _currentIndex % states.length;
        final state = states[index];
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: const Color(0xFF0B1D2C),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: const Color(0xFF456074)),
          ),
          child: LayoutBuilder(
            builder: (context, constraints) {
              final compact = constraints.maxWidth < 540;
              return SizedBox(
                height: compact ? 200 : 154,
                child: compact
                    ? _compactCard(state, states.length)
                    : _wideCard(state, states.length),
              );
            },
          ),
        );
      },
    );
  }

  Widget _emptyCard() => Container(
    margin: const EdgeInsets.symmetric(horizontal: 16),
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: const Color(0xFF0B1D2C),
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: const Color(0xFF456074)),
    ),
    child: const Row(
      children: [
        Icon(Icons.insights_outlined, color: Color(0xFF60A5FA)),
        SizedBox(width: 12),
        Expanded(
          child: Text(
            'Published map activity will appear here when data is available.',
            style: TextStyle(color: Colors.white70),
          ),
        ),
      ],
    ),
  );

  Widget _wideCard(_ActiveState state, int stateCount) => Row(
    children: [
      _arrowButton(Icons.chevron_left_rounded, () => _changeState(-1, stateCount)),
      const SizedBox(width: 8),
      _stateBadge(state, 86),
      const SizedBox(width: 18),
      Expanded(flex: 3, child: _activityDetails(state)),
      _divider(),
      _recordDetails(state),
      _divider(),
      Expanded(child: _prizeDetails(state)),
      const SizedBox(width: 8),
      _arrowButton(Icons.chevron_right_rounded, () => _changeState(1, stateCount)),
    ],
  );

  Widget _compactCard(_ActiveState state, int stateCount) => Column(
    children: [
      Expanded(
        child: Row(
          children: [
            _arrowButton(Icons.chevron_left_rounded, () => _changeState(-1, stateCount)),
            const SizedBox(width: 8),
            _stateBadge(state, 64),
            const SizedBox(width: 14),
            Expanded(child: _activityDetails(state, compact: true)),
            _arrowButton(Icons.chevron_right_rounded, () => _changeState(1, stateCount)),
          ],
        ),
      ),
      const Divider(color: Colors.white12),
      Expanded(
        child: Row(
          children: [
            Expanded(child: _recordDetails(state, compact: true)),
            Container(width: 1, height: 48, color: Colors.white12),
            Expanded(child: _prizeDetails(state, compact: true)),
          ],
        ),
      ),
    ],
  );

  Widget _arrowButton(IconData icon, VoidCallback onPressed) => IconButton(
    tooltip: icon == Icons.chevron_left_rounded
        ? 'Previous active state'
        : 'Next active state',
    onPressed: onPressed,
    icon: Icon(icon, color: Colors.white70, size: 32),
  );

  Widget _stateBadge(_ActiveState state, double size) => Tooltip(
    message: 'Open ${state.name} on the map',
    child: MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => MapFocusService.focusState(state.name),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: size,
              height: size,
              decoration: BoxDecoration(
                color: const Color(0xFF1478FF).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: const Color(0xFF1478FF).withValues(alpha: 0.85),
                ),
              ),
              child: Center(
                child: Text(
                  state.abbreviation,
                  style: TextStyle(
                    color: const Color(0xFF60A5FA),
                    fontSize: size * 0.32,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 3),
            const Text(
              'OPEN MAP',
              style: TextStyle(
                color: Color(0xFF93C5FD),
                fontSize: 8,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _activityDetails(_ActiveState state, {bool compact = false}) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        'MOST ACTIVE STATE',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: const Color(0xFF1478FF),
          fontSize: compact ? 10 : 11,
          letterSpacing: 0.7,
          fontWeight: FontWeight.w700,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        state.name,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 22 : 27,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(
        _numberText(state.tickets),
        style: TextStyle(
          color: const Color(0xFF1478FF),
          fontSize: compact ? 28 : 34,
          fontWeight: FontWeight.w800,
        ),
      ),
      Text(
        'PUBLISHED WINNING TICKETS',
        style: TextStyle(
          color: Colors.white60,
          fontSize: compact ? 9 : 10,
          letterSpacing: 0.5,
        ),
      ),
    ],
  );

  Widget _recordDetails(_ActiveState state, {bool compact = false}) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      const Icon(Icons.receipt_long_outlined, color: Color(0xFF60A5FA)),
      const SizedBox(height: 4),
      Text(
        _numberText(state.records),
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 19 : 25,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(
        'PUBLISHED RECORDS',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white60,
          fontSize: compact ? 8 : 9,
          letterSpacing: 0.5,
        ),
      ),
    ],
  );

  Widget _prizeDetails(_ActiveState state, {bool compact = false}) => Column(
    mainAxisAlignment: MainAxisAlignment.center,
    children: [
      Icon(
        Icons.workspace_premium_outlined,
        color: const Color(0xFFF5B301),
        size: compact ? 22 : 28,
      ),
      const SizedBox(height: 4),
      Text(
        _prizeText(state.topPrize),
        style: TextStyle(
          color: Colors.white,
          fontSize: compact ? 19 : 22,
          fontWeight: FontWeight.w700,
        ),
      ),
      Text(
        'HIGHEST PRIZE',
        textAlign: TextAlign.center,
        style: TextStyle(
          color: Colors.white60,
          fontSize: compact ? 8 : 9,
          letterSpacing: 0.5,
        ),
      ),
    ],
  );

  Widget _divider() => Container(
    width: 1,
    height: 88,
    margin: const EdgeInsets.symmetric(horizontal: 14),
    color: Colors.white12,
  );

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
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      return '\$${millions.toStringAsFixed(millions == millions.roundToDouble() ? 0 : 1)}M';
    }
    if (amount >= 1000) return '\$${(amount / 1000).toStringAsFixed(0)}K';
    return '\$$amount';
  }
}

class _ActiveState {
  const _ActiveState({
    required this.abbreviation,
    required this.name,
    required this.records,
    required this.tickets,
    required this.topPrize,
  });

  final String abbreviation;
  final String name;
  final int records;
  final int tickets;
  final int topPrize;
}
