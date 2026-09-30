import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/models/lottery_activity.dart';
import 'package:lottery_atlas/services/south_carolina_lottery_map_filter_service.dart';
import 'package:lottery_atlas/widgets/map/map_filter_state.dart';

import '../../tooling/import_south_carolina_winners_report.dart' as importer;

void main() {
  test(
    'Xs and Os claims enter their draw filter, not Scratch or Powerball',
    () {
      final root =
          jsonDecode(
                File(
                  'data/south_carolina_current_winner_activity.generated.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      final rows = (root['activities'] as List).where(
        (row) => row['gameName'] == 'Xs and Os',
      );
      expect(rows, isNotEmpty);
      final filter = SouthCarolinaLotteryMapFilter.drawGames.singleWhere(
        (filter) => filter.gameName == 'Xs and Os',
      );
      final powerball = SouthCarolinaLotteryMapFilter.drawGames.singleWhere(
        (filter) => filter.gameName == 'Powerball',
      );
      for (final row in rows) {
        expect(importer.southCarolinaGameType(row['gameName']), 'state-draw');
        final activity = LotteryActivity.fromJson(
          Map<String, dynamic>.from(row),
        );
        expect(activity.game, LotteryGame.stateDraw);
        expect(filter.matches(activity), isTrue);
        expect(powerball.matches(activity), isFalse);
      }
      expect(importer.southCarolinaGameType('Powerball'), 'powerball');
      expect(importer.southCarolinaGameType('Mega Millions'), 'mega-millions');
      expect(
        importer.southCarolinaGameType('MAGNIFICENT JUMBO BUCKS'),
        'scratch-off',
      );
    },
  );
}
