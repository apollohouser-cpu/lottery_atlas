import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/connecticut_scratch_detail.dart';

void main() {
  final game = <String, dynamic>{
    'id': '100',
    'name': 'Synthetic fixture',
    'cost': 30,
    'sourceDate': '2026-11-21',
    'status': 'ended',
    'startDate': '2025-01-01',
    'endDate': '2026-10-01',
    'topPrize': 825000,
    'topPrizeLabel': '\$1,000,000 annuity',
    'inventoryNote': 'Retained source note',
    'sourceUrl': 'https://www.ctlottery.org/games/scratch-games/100',
    'prizeTiers': [
      {
        'prizeLabel': '\$1,000,000',
        'total': 3,
        'remaining': 1,
        'prizeCategory': 'annuity',
      },
    ],
  };
  Future<void> show(WidgetTester tester, Map<String, dynamic> value) async {
    await tester.pumpWidget(
      MaterialApp(home: ConnecticutScratchDetail(game: value)),
    );
  }

  testWidgets(
    'annuity and cash option remain distinct with original source date',
    (tester) async {
      await show(tester, game);
      expect(
        find.text('Advertised top prize: \$1,000,000 annuity'),
        findsOneWidget,
      );
      expect(find.text('Verified top cash option: \$825000'), findsOneWidget);
      expect(find.text('Source inventory date: 2026-11-21'), findsOneWidget);
      expect(find.text('Sales ended'), findsOneWidget);
      expect(
        find.text('Last day to claim: Not supplied / TBD'),
        findsOneWidget,
      );
    },
  );
  testWidgets('tier labels keep annuity and cumulative inventory semantics', (
    tester,
  ) async {
    await show(tester, game);
    await tester.scrollUntilVisible(find.text('Unclaimed prizes: 1'), 250);
    expect(find.text('Prize: \$1,000,000 (annuity)'), findsOneWidget);
    expect(find.text('Original prizes: 3'), findsOneWidget);
  });
  testWidgets('excluded game cannot display conflicting cash value', (
    tester,
  ) async {
    await show(tester, {...game, 'id': '1725'});
    expect(find.textContaining('Game 1725 excluded:'), findsOneWidget);
    expect(find.textContaining('Verified top cash option:'), findsNothing);
  });
}
