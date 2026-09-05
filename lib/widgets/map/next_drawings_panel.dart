import 'dart:async';

import 'package:flutter/material.dart';

import '../../models/favorite_lottery_game.dart';
import '../../services/favorite_games_service.dart';
import '../../services/lottery_schedule_service.dart';
import '../../services/musl_draw_service.dart';

/// A compact, expandable view of upcoming national and verified state draws.
///
/// The schedule remains useful without an API key. When a MUSL key is
/// configured, the app refreshes official results when the map opens and
/// shows the latest result and current jackpot estimate when expanded.
class NextDrawingsPanel extends StatefulWidget {
  const NextDrawingsPanel({
    super.key,
    this.stateName,
    required this.isExpanded,
    required this.onExpandedChanged,
    this.onViewNationalResults,
    this.onStateDrawSelected,
    this.width,
    this.showStateLabel = false,
  });

  final String? stateName;
  final bool isExpanded;
  final ValueChanged<bool> onExpandedChanged;
  final VoidCallback? onViewNationalResults;
  final ValueChanged<String>? onStateDrawSelected;
  final double? width;
  final bool showStateLabel;

  @override
  State<NextDrawingsPanel> createState() => _NextDrawingsPanelState();
}

class _NextDrawingsPanelState extends State<NextDrawingsPanel> {
  final MuslDrawService _drawService = MuslDrawService();
  late final Timer _clockTimer;
  Future<List<NationalDrawResult>>? _results;

  @override
  void initState() {
    super.initState();
    LotteryScheduleService.initialize();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
    // Keep the national-result cache fresh for the day even when this compact
    // panel remains closed. If the network is unavailable, MuslDrawService
    // safely falls back to a saved result.
    _loadLiveResults();
    FavoriteGamesService.load();
  }

  @override
  void didUpdateWidget(covariant NextDrawingsPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isExpanded && !oldWidget.isExpanded) _loadLiveResults();
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _drawService.dispose();
    super.dispose();
  }

  void _loadLiveResults() {
    if (!_drawService.isConfigured || _results != null) return;
    _results = Future.wait([
      _drawService.latestCachedOrRefresh('powerball'),
      _drawService.latestCachedOrRefresh('mega-millions'),
    ]);
  }

  String _drawingDateLabel(DateTime drawingTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final drawingDay = DateTime(
      drawingTime.year,
      drawingTime.month,
      drawingTime.day,
    );
    final dayDifference = drawingDay.difference(today).inDays;

    if (dayDifference == 0) return 'Tonight';
    if (dayDifference == 1) return 'Tomorrow';

    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
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
    ];
    return '${weekdays[drawingTime.weekday - 1]} · '
        '${months[drawingTime.month - 1]} ${drawingTime.day}';
  }

  String _timeLabel(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period ${time.timeZoneName}';
  }

  String _countdownLabel(Duration timeRemaining) {
    if (timeRemaining.isNegative) return 'Drawing now';
    final hours = timeRemaining.inHours;
    final minutes = timeRemaining.inMinutes.remainder(60);
    final seconds = timeRemaining.inSeconds.remainder(60);
    if (hours >= 24) return '${timeRemaining.inDays}d ${hours.remainder(24)}h';
    return '${hours}h ${minutes.toString().padLeft(2, '0')}m '
        '${seconds.toString().padLeft(2, '0')}s';
  }

  NationalDrawResult? _resultFor(
    LotteryDrawSchedule schedule,
    List<NationalDrawResult>? results,
  ) {
    if (results == null) return null;
    final scheduleName = schedule.name.toLowerCase();
    for (final result in results) {
      if (result.gameName.toLowerCase() == scheduleName) return result;
    }
    return null;
  }

  Widget _drawingRowFor(
    LotteryDrawSchedule schedule, {
    List<NationalDrawResult>? results,
  }) {
    final drawingTime = LotteryScheduleService.nextDrawing(
      schedule,
      stateName: widget.stateName,
    );
    return _DrawingRow(
      schedule: schedule,
      dateLabel: _drawingDateLabel(drawingTime),
      timeLabel: _timeLabel(drawingTime),
      countdown: _countdownLabel(drawingTime.difference(DateTime.now())),
      result: _resultFor(schedule, results),
      onTap: widget.onViewNationalResults,
      favoriteGame: _nationalFavoriteFor(schedule),
    );
  }

  FavoriteLotteryGame _nationalFavoriteFor(LotteryDrawSchedule schedule) {
    final isPowerball = schedule.name.toLowerCase().contains('powerball');
    return FavoriteLotteryGame(
      key: isPowerball
          ? 'national-draw:powerball'
          : 'national-draw:mega-millions',
      gameId: isPowerball ? 'powerball' : 'mega-millions',
      name: isPowerball ? 'Powerball' : 'Mega Millions',
      subtitle: 'National draw game',
      kind: FavoriteLotteryGameKind.nationalDraw,
    );
  }

  Widget _rows(List<NationalDrawResult>? results) => Column(
    children: [
      for (final schedule in LotteryScheduleService.nationalDraws) ...[
        _drawingRowFor(schedule, results: results),
        if (schedule != LotteryScheduleService.nationalDraws.last)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: Colors.white12, height: 1),
          ),
      ],
    ],
  );

  String _mapGameName(StateLotteryDrawSchedule schedule) {
    final name = schedule.name.toLowerCase();
    if (name.startsWith('carolina cash 5')) return 'Cash 5';
    if (name.startsWith('carolina pick 3')) return 'Pick 3';
    if (name.startsWith('carolina pick 4')) return 'Pick 4';
    if (name.startsWith('pick 3')) return 'Pick 3';
    if (name.startsWith('pick 4')) return 'Pick 4';
    if (name.startsWith('cash pop')) return 'Cash Pop';
    if (name.startsWith('carolina keno')) return 'Carolina Keno';
    if (name.startsWith('millionaire for life')) return 'Millionaire For Life';
    return schedule.name.split(' · ').first;
  }

  FavoriteLotteryGame _stateFavoriteFor(StateLotteryDrawSchedule schedule) {
    final mapGameName = _mapGameName(schedule);
    final isSouthCarolina = widget.stateName == 'South Carolina';
    final name = isSouthCarolina
        ? switch (mapGameName) {
            'Pick 3' => 'Pick 3 Plus FIREBALL',
            'Pick 4' => 'Pick 4 Plus FIREBALL',
            'Cash Pop' => 'CASH POP',
            _ => 'Palmetto Cash 5',
          }
        : mapGameName;
    final id = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final stateKey = (widget.stateName ?? 'state').toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '-',
    );
    return FavoriteLotteryGame(
      key: 'state-draw:$stateKey:$id',
      gameId: name,
      name: name,
      subtitle: '${widget.stateName} draw game',
      kind: FavoriteLotteryGameKind.stateDraw,
    );
  }

  Widget _stateRows() {
    final stateName = widget.stateName;
    if (stateName == null) return const SizedBox.shrink();

    final schedules = LotteryScheduleService.stateDrawsFor(stateName);
    if (schedules.isEmpty) {
      return const Padding(
        padding: EdgeInsets.only(bottom: 12),
        child: Text(
          'Verified state draw times are being connected. National lotteries remain available below.',
          style: TextStyle(color: Colors.white60, fontSize: 12, height: 1.35),
        ),
      );
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 7),
          child: Text(
            '${stateName.toUpperCase()} DRAW GAMES',
            style: TextStyle(
              color: Color(0xFF86EFAC),
              fontSize: 10,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.8,
            ),
          ),
        ),
        for (final schedule in schedules) ...[
          _StateDrawingRow(
            schedule: schedule,
            dateLabel: _drawingDateLabel(
              LotteryScheduleService.nextStateDrawing(
                schedule,
                stateName: stateName,
              ),
            ),
            timeLabel: _timeLabel(
              LotteryScheduleService.nextStateDrawing(
                schedule,
                stateName: stateName,
              ),
            ),
            countdown: _countdownLabel(
              LotteryScheduleService.nextStateDrawing(
                schedule,
                stateName: stateName,
              ).difference(DateTime.now()),
            ),
            onTap: widget.onStateDrawSelected == null
                ? null
                : () => widget.onStateDrawSelected!(_mapGameName(schedule)),
            favoriteGame: _stateFavoriteFor(schedule),
          ),
          if (schedule != schedules.last)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: Divider(color: Colors.white12, height: 1),
            ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasSelectedState = widget.stateName != null;
    final hasVerifiedStateDraws =
        widget.stateName != null &&
        LotteryScheduleService.hasVerifiedStateDraws(widget.stateName!);
    final showStateHeading = widget.showStateLabel && widget.stateName != null;
    // Keep the expanded menu within the visible map area. The list itself is
    // scrollable so state and national draws remain reachable on smaller
    // screens instead of passing wheel input through to the map.
    final expandedHeight = (MediaQuery.sizeOf(context).height - 205)
        .clamp(300.0, 520.0)
        .toDouble();
    return SizedBox(
      width: widget.width ?? 290,
      height: widget.isExpanded ? expandedHeight : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xED0A1824),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            mainAxisSize: widget.isExpanded
                ? MainAxisSize.max
                : MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: () => widget.onExpandedChanged(!widget.isExpanded),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.schedule_rounded,
                        color: Color(0xFF60A5FA),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          hasVerifiedStateDraws || showStateHeading
                              ? 'DRAWINGS IN ${widget.stateName!.toUpperCase()}'
                              : hasSelectedState
                              ? 'NEXT DRAWINGS'
                              : 'NATIONAL LOTTERIES',
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Icon(
                        widget.isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
              if (widget.isExpanded) ...[
                const SizedBox(height: 4),
                Expanded(
                  child: Scrollbar(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            hasSelectedState
                                ? 'Times shown in the state’s primary time zone'
                                : 'Times shown in your local time zone',
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 11,
                            ),
                          ),
                          const SizedBox(height: 10),
                          if (hasVerifiedStateDraws) ...[
                            _stateRows(),
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 10),
                              child: Divider(color: Colors.white24, height: 1),
                            ),
                            const Padding(
                              padding: EdgeInsets.only(bottom: 7),
                              child: Text(
                                'NATIONAL DRAW GAMES',
                                style: TextStyle(
                                  color: Color(0xFF93C5FD),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.8,
                                ),
                              ),
                            ),
                          ],
                          if (!_drawService.isConfigured)
                            _rows(null)
                          else
                            FutureBuilder<List<NationalDrawResult>>(
                              future: _results,
                              builder: (context, snapshot) {
                                if (!snapshot.hasData) return _rows(null);
                                final hasSavedResult = snapshot.data!.any(
                                  (result) => result.isCached,
                                );
                                return Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _rows(snapshot.data),
                                    const SizedBox(height: 8),
                                    Text(
                                      hasSavedResult
                                          ? 'Showing saved official results'
                                          : 'Official results refreshed',
                                      style: TextStyle(
                                        color: hasSavedResult
                                            ? const Color(0xFFFACC15)
                                            : const Color(0xFF86EFAC),
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          if (_drawService.isConfigured &&
                              widget.onViewNationalResults != null) ...[
                            const SizedBox(height: 10),
                            SizedBox(
                              width: double.infinity,
                              child: TextButton.icon(
                                onPressed: widget.onViewNationalResults,
                                icon: const Icon(
                                  Icons.confirmation_number_outlined,
                                  size: 17,
                                ),
                                label: const Text('VIEW NATIONAL RESULTS'),
                                style: TextButton.styleFrom(
                                  foregroundColor: const Color(0xFF93C5FD),
                                  textStyle: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.6,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StateDrawingRow extends StatelessWidget {
  const _StateDrawingRow({
    required this.schedule,
    required this.dateLabel,
    required this.timeLabel,
    required this.countdown,
    required this.onTap,
    required this.favoriteGame,
  });

  final StateLotteryDrawSchedule schedule;
  final String dateLabel;
  final String timeLabel;
  final String countdown;
  final VoidCallback? onTap;
  final FavoriteLotteryGame favoriteGame;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 22,
                decoration: BoxDecoration(
                  color: schedule.accentColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  schedule.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                countdown,
                style: const TextStyle(
                  color: Color(0xFF86EFAC),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _FavoriteGameButton(game: favoriteGame),
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Text(
              '$dateLabel · $timeLabel${onTap == null ? '' : ' · Show on map'}',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
        ],
      ),
    ),
  );
}

class _DrawingRow extends StatelessWidget {
  const _DrawingRow({
    required this.schedule,
    required this.dateLabel,
    required this.timeLabel,
    required this.countdown,
    required this.result,
    required this.onTap,
    required this.favoriteGame,
  });

  final LotteryDrawSchedule schedule;
  final String dateLabel;
  final String timeLabel;
  final String countdown;
  final NationalDrawResult? result;
  final VoidCallback? onTap;
  final FavoriteLotteryGame favoriteGame;

  @override
  Widget build(BuildContext context) => InkWell(
    borderRadius: BorderRadius.circular(10),
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 3),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 8,
                height: 22,
                decoration: BoxDecoration(
                  color: schedule.accentColor,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  schedule.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                countdown,
                style: const TextStyle(
                  color: Color(0xFF93C5FD),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
              _FavoriteGameButton(game: favoriteGame),
            ],
          ),
          const SizedBox(height: 3),
          Padding(
            padding: const EdgeInsets.only(left: 18),
            child: Text(
              '$dateLabel · $timeLabel',
              style: const TextStyle(color: Colors.white70, fontSize: 11),
            ),
          ),
          if (result?.nextPrizeText != null)
            Padding(
              padding: const EdgeInsets.only(left: 18, top: 4),
              child: Text(
                'Next prize: ${result!.nextPrizeText}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Color(0xFF86EFAC),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

class _FavoriteGameButton extends StatelessWidget {
  const _FavoriteGameButton({required this.game});

  final FavoriteLotteryGame game;

  Future<void> _toggle(BuildContext context) async {
    final isSaved = await FavoriteGamesService.toggle(game);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSaved
              ? '${game.name} saved to favorite games.'
              : '${game.name} removed from favorite games.',
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<List<FavoriteLotteryGame>>(
    valueListenable: FavoriteGamesService.games,
    builder: (context, favorites, _) {
      final isFavorite = favorites.any((favorite) => favorite.key == game.key);
      return IconButton(
        tooltip: isFavorite
            ? 'Remove from favorite games'
            : 'Save to favorite games',
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        padding: EdgeInsets.zero,
        onPressed: () => _toggle(context),
        icon: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 19,
          color: isFavorite ? const Color(0xFFE94B6A) : Colors.white70,
        ),
      );
    },
  );
}
