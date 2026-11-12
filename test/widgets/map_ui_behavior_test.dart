import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show ScrollCacheExtent;
import 'package:flutter_test/flutter_test.dart';
import 'package:latlong2/latlong.dart';
import 'package:lottery_atlas/models/lottery_activity.dart';
import 'package:lottery_atlas/services/map_ranking_service.dart';
import 'package:lottery_atlas/services/state_game_filter_service.dart';
import 'package:lottery_atlas/widgets/cards/most_winning_state_card.dart';
import 'package:lottery_atlas/widgets/map/map_controls_overlay.dart';
import 'package:lottery_atlas/widgets/map/map_filter_state.dart';

void main() {
  test('National categories stay intact; state offerings do not need wins', () {
    expect(StateGameFilterService.forState(null), LotteryGame.values);
    expect(StateGameFilterService.forState('South Carolina'), [
      LotteryGame.allGames,
      LotteryGame.powerball,
      LotteryGame.megaMillions,
      LotteryGame.scratchOff,
      LotteryGame.stateDraw,
    ]);
    expect(
      StateGameFilterService.forState('Wyoming'),
      isNot(contains(LotteryGame.scratchOff)),
    );
    expect(
      StateGameFilterService.forState('North Dakota'),
      isNot(contains(LotteryGame.scratchOff)),
    );
    expect(StateGameFilterService.forState('Alabama'), [LotteryGame.allGames]);
    expect(
      StateGameFilterService.forState('Ohio'),
      contains(LotteryGame.gameShow),
    );
    expect(
      StateGameFilterService.normalize('South Carolina', LotteryGame.gameShow),
      LotteryGame.allGames,
    );
  });

  testWidgets(
    'State game sheet omits unrelated categories and resets stale choice',
    (tester) async {
      MapFilterState? applied;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapControlsOverlay(
              selectedStateName: 'South Carolina',
              filterState: MapFilterState.initial().copyWith(
                game: LotteryGame.gameShow,
              ),
              onFilterChanged: (value) => applied = value,
            ),
          ),
        ),
      );
      await tester.tap(find.text('Game Filter · Game Show Prizes'));
      await tester.pumpAndSettle();
      expect(find.text('Scratch-Offs'), findsOneWidget);
      expect(find.text('State Draw Games'), findsOneWidget);
      expect(find.text('Game Show Prizes'), findsNothing);
      expect(find.text('Terminal Instant Games'), findsNothing);
      await tester.tap(find.text('Apply Game Filter'));
      await tester.pumpAndSettle();
      expect(applied?.game, LotteryGame.allGames);
    },
  );

  for (final scale in [1.0, 2.0]) {
    for (final county in [false, true]) {
      testWidgets(
        'Rankings preserve scroll offset through 5/2/0/5 at $scale, county=$county',
        (tester) async {
          await tester.binding.setSurfaceSize(const Size(390, 844));
          addTearDown(() => tester.binding.setSurfaceSize(null));
          final previous = MapRankingService.snapshot.value;
          addTearDown(() => MapRankingService.snapshot.value = previous);
          final controller = ScrollController();
          addTearDown(controller.dispose);
          final records = List.generate(
            5,
            (i) => LotteryActivity(
              id: 'test-$i',
              location: const LatLng(35, -80),
              city: 'City $i',
              county: 'County $i',
              state: county ? 'SC' : ['SC', 'NC', 'GA', 'FL', 'VA'][i],
              game: LotteryGame.powerball,
              drawDate: DateTime(2026, 11, 1),
              winningTickets: 5 - i,
              prizeAmount: 100,
            ),
          );
          void publish(int count) =>
              MapRankingService.snapshot.value = MapRankingSnapshot(
                records: records.take(count).toList(),
                dateRangeStart: DateTime(2026, 11, 1),
                dateRangeEnd: DateTime(2026, 11, 2),
                countyIds: const {},
                stateName: county ? 'South Carolina' : null,
                stateAbbreviation: county ? 'SC' : null,
              );
          publish(5);
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(textScaler: TextScaler.linear(scale)),
                child: Scaffold(
                  body: ListView(
                    controller: controller,
                    scrollCacheExtent: const ScrollCacheExtent.pixels(3000),
                    children: const [
                      SizedBox(height: 750),
                      MostWinningStateCard(),
                      SizedBox(height: 18),
                    ],
                  ),
                ),
              ),
            ),
          );
          controller.jumpTo(controller.position.maxScrollExtent);
          await tester.pump();
          final offset = controller.offset;
          final slots = tester.getSize(
            find.byKey(const ValueKey('ranking-slots')),
          );
          for (final count in [2, 0, 5]) {
            publish(count);
            await tester.pump();
            expect(controller.offset, offset);
            expect(
              tester.getSize(find.byKey(const ValueKey('ranking-slots'))),
              slots,
            );
            if (count == 0) {
              expect(
                find.text(
                  'No verified activity matches the current map and timeline filters.',
                ),
                findsOneWidget,
              );
            }
            expect(tester.takeException(), isNull);
          }
          await tester.pumpWidget(const SizedBox.shrink());
        },
      );
    }
  }
}
