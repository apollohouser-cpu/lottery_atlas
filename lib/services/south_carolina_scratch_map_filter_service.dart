import 'package:flutter/foundation.dart';

import '../models/lottery_activity.dart';
import '../widgets/map/map_filter_state.dart';
import 'south_carolina_scratch_catalog.dart';

class SouthCarolinaScratchMapFilter {
  const SouthCarolinaScratchMapFilter({
    required this.gameId,
    required this.minimumPrize,
    required this.maximumPrize,
    this.gameNameOverride,
  });

  final String gameId;
  final int minimumPrize;
  final int maximumPrize;
  final String? gameNameOverride;

  String? get gameName {
    if (gameId == 'all') return null;
    final override = gameNameOverride?.trim();
    if (override != null && override.isNotEmpty) return override;
    for (final game in SouthCarolinaScratchCatalog.games) {
      if (game.id == gameId) return game.name;
    }
    return null;
  }

  bool matches(LotteryActivity activity) {
    if (activity.state != 'SC' || activity.game != LotteryGame.scratchOff) {
      return false;
    }
    if (activity.prizeAmount < minimumPrize ||
        activity.prizeAmount > maximumPrize) {
      return false;
    }
    final selectedName = gameName;
    return selectedName == null || activity.gameName == selectedName;
  }

  String get label {
    final selectedName = gameName ?? 'All Scratch-Offs';
    return '$selectedName · ${_money(minimumPrize)}–${_money(maximumPrize)}';
  }
}

class SouthCarolinaScratchMapFilterService {
  SouthCarolinaScratchMapFilterService._();

  static final ValueNotifier<SouthCarolinaScratchMapFilter?> selection =
      ValueNotifier(null);

  static void apply(SouthCarolinaScratchMapFilter filter) {
    selection.value = filter;
  }

  static void clear() {
    if (selection.value != null) selection.value = null;
  }
}

String _money(int amount) {
  if (amount >= 1000000) {
    final millions = amount / 1000000;
    return r'$' +
        millions.toStringAsFixed(millions == millions.roundToDouble() ? 0 : 1) +
        'M';
  }
  if (amount >= 1000) return r'$' + (amount / 1000).toStringAsFixed(0) + 'K';
  return r'$' + amount.toString();
}
