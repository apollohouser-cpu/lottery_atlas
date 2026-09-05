import 'package:flutter/material.dart';

enum LotteryGame { allGames, powerball, megaMillions, scratchOff, stateDraw }

/// Controls which records are allowed onto the national map. State views keep
/// their local lottery activity available regardless of this setting.
enum MapActivityScope { nationalOnly, allLotteries }

extension MapActivityScopeDetails on MapActivityScope {
  String get label {
    switch (this) {
      case MapActivityScope.nationalOnly:
        return 'National lotteries only';
      case MapActivityScope.allLotteries:
        return 'All lotteries';
    }
  }

  String get description {
    switch (this) {
      case MapActivityScope.nationalOnly:
        return 'Powerball and Mega Millions only on the U.S. map.';
      case MapActivityScope.allLotteries:
        return 'Include state draw games and Scratch-Off activity.';
    }
  }
}

extension LotteryGameDetails on LotteryGame {
  String get label {
    switch (this) {
      case LotteryGame.allGames:
        return 'All Games';
      case LotteryGame.powerball:
        return 'Powerball';
      case LotteryGame.megaMillions:
        return 'Mega Millions';
      case LotteryGame.scratchOff:
        return 'Scratch-Offs';
      case LotteryGame.stateDraw:
        return 'State Draw Games';
    }
  }

  IconData get icon {
    switch (this) {
      case LotteryGame.allGames:
        return Icons.apps_rounded;
      case LotteryGame.powerball:
        return Icons.circle_outlined;
      case LotteryGame.megaMillions:
        return Icons.stars_rounded;
      case LotteryGame.scratchOff:
        return Icons.confirmation_number_outlined;
      case LotteryGame.stateDraw:
        return Icons.casino_outlined;
    }
  }
}

class MapFilterState {
  const MapFilterState({
    this.game = LotteryGame.allGames,
    required this.dateRange,
    this.activityScope = MapActivityScope.nationalOnly,
    this.minimumPrize = 1,
    this.maximumPrize,
    this.showWinnersOnly = false,
    this.showFavoritesOnly = false,
  });

  factory MapFilterState.initial() {
    return MapFilterState(
      dateRange: DateTimeRange(
        start: DateTime(2015, 1, 1),
        end: DateTime.now(),
      ),
    );
  }

  final LotteryGame game;
  final DateTimeRange dateRange;
  final MapActivityScope activityScope;
  final int minimumPrize;
  final int? maximumPrize;
  final bool showWinnersOnly;
  final bool showFavoritesOnly;

  MapFilterState copyWith({
    LotteryGame? game,
    DateTimeRange? dateRange,
    MapActivityScope? activityScope,
    int? minimumPrize,
    int? maximumPrize,
    bool replaceMaximumPrize = false,
    bool? showWinnersOnly,
    bool? showFavoritesOnly,
  }) {
    return MapFilterState(
      game: game ?? this.game,
      dateRange: dateRange ?? this.dateRange,
      activityScope: activityScope ?? this.activityScope,
      minimumPrize: minimumPrize ?? this.minimumPrize,
      maximumPrize: replaceMaximumPrize ? maximumPrize : this.maximumPrize,
      showWinnersOnly: showWinnersOnly ?? this.showWinnersOnly,
      showFavoritesOnly: showFavoritesOnly ?? this.showFavoritesOnly,
    );
  }

  String get dateRangeLabel {
    return '${_monthYear(dateRange.start)} – ${_monthYear(dateRange.end)}';
  }

  static String _monthYear(DateTime date) {
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

    return '${months[date.month - 1]} ${date.year}';
  }
}
