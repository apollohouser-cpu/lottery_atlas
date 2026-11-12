import '../models/state_model.dart';
import '../widgets/map/map_filter_state.dart';
import 'lottery_activity_repository.dart';
import 'state_navigation_service.dart';

/// Product categories, independent of the selected date or winning records.
/// State source screens retain the detailed coverage limitations.
class StateGameFilterService {
  static const _nonLotteryStates = {
    'Alabama',
    'Alaska',
    'Hawaii',
    'Nevada',
    'Utah',
  };
  // Reviewed terminal products in the state source screens. Additional
  // categories in the complete retained activity feed are included below.
  static const _terminalStates = {
    'Arizona',
    'Idaho',
    'Iowa',
    'Kentucky',
    'Louisiana',
    'Maryland',
    'North Carolina',
    'Ohio',
    'Oklahoma',
    'Vermont',
  };

  static List<LotteryGame> forState(String? stateName) {
    if (stateName == null) return LotteryGame.values;
    if (_nonLotteryStates.contains(stateName) ||
        !allStates.any((state) => state.name == stateName)) {
      return const [LotteryGame.allGames];
    }
    final categories = <LotteryGame>{
      LotteryGame.allGames,
      LotteryGame.powerball,
      LotteryGame.megaMillions,
      // ND and WY offer draw products, without Scratch tickets.
      if (stateName != 'North Dakota' && stateName != 'Wyoming')
        LotteryGame.scratchOff,
      LotteryGame.stateDraw,
      if (_terminalStates.contains(stateName)) LotteryGame.terminalInstant,
      if (stateName == 'Ohio') LotteryGame.gameShow,
    };
    final abbreviation = StateNavigationService.getStateByName(
      stateName,
    )?.abbreviation;
    categories.addAll(
      LotteryActivityRepository.activity
          .where((record) => record.state == abbreviation)
          .map((record) => record.game),
    );
    return LotteryGame.values.where(categories.contains).toList();
  }

  static LotteryGame normalize(String? stateName, LotteryGame game) {
    if (stateName == null || game == LotteryGame.allGames) return game;
    return forState(stateName).contains(game) ? game : LotteryGame.allGames;
  }
}
