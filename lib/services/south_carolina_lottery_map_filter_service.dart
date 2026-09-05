import 'package:flutter/foundation.dart';

import '../models/lottery_activity.dart';
import '../widgets/map/map_filter_state.dart';

/// A precise South Carolina game filter for the map, heat index, and timeline.
///
/// Game names intentionally match the official South Carolina Winners Report.
class SouthCarolinaLotteryMapFilter {
  const SouthCarolinaLotteryMapFilter._({
    required this.gameName,
    required this.game,
    required this.label,
  });

  const SouthCarolinaLotteryMapFilter.all()
    : gameName = null,
      game = LotteryGame.allGames,
      label = 'All South Carolina lottery activity';

  final String? gameName;
  final LotteryGame game;
  final String label;

  bool matches(LotteryActivity activity) {
    if (activity.state != 'SC') return false;
    final selectedGameName = gameName;
    return selectedGameName == null || activity.gameName == selectedGameName;
  }

  static const List<SouthCarolinaLotteryMapFilter> drawGames = [
    SouthCarolinaLotteryMapFilter._(
      gameName: 'Powerball',
      game: LotteryGame.powerball,
      label: 'SC Powerball',
    ),
    SouthCarolinaLotteryMapFilter._(
      gameName: 'Mega Millions',
      game: LotteryGame.megaMillions,
      label: 'SC Mega Millions',
    ),
    SouthCarolinaLotteryMapFilter._(
      gameName: 'Palmetto Cash 5',
      game: LotteryGame.stateDraw,
      label: 'SC Palmetto Cash 5',
    ),
    SouthCarolinaLotteryMapFilter._(
      gameName: 'Pick 4',
      game: LotteryGame.stateDraw,
      label: 'SC Pick 4',
    ),
    SouthCarolinaLotteryMapFilter._(
      gameName: 'Pick 3',
      game: LotteryGame.stateDraw,
      label: 'SC Pick 3',
    ),
    SouthCarolinaLotteryMapFilter._(
      gameName: 'Cash Pop',
      game: LotteryGame.stateDraw,
      label: 'SC CASH POP',
    ),
  ];
}

class SouthCarolinaLotteryMapFilterService {
  SouthCarolinaLotteryMapFilterService._();

  static final ValueNotifier<SouthCarolinaLotteryMapFilter?> selection =
      ValueNotifier(null);

  static void apply(SouthCarolinaLotteryMapFilter filter) {
    selection.value = filter;
  }

  static void clear() {
    if (selection.value != null) selection.value = null;
  }
}
