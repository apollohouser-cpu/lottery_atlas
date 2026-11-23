import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/connecticut_report_sheet.dart';

void main() {
  Future<void> show(
    WidgetTester tester,
    String game,
    List<Map> rows, {
    List<Map>? doublePlay,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConnecticutReportSheet(
          report: {
            'game': game,
            'drawDate': '2026-11-22',
            'dateEvidence': 'Dated request; response echoes draw ID only',
            'sourceUrl': 'https://ctlottery.com/api/winning-payouts',
            'limitations': ['Groups overlap; do not sum.'],
            'rows': rows,
            'doublePlayRows': ?doublePlay,
          },
        ),
      ),
    );
  }

  testWidgets('winning plays and reference prize are not ticket payouts', (
    tester,
  ) async {
    await show(tester, 'play3', [
      {
        'match': 'Straight',
        'reportedWinningPlays': 3,
        'minimumWagerPrizeLabel': '\$250',
      },
    ]);
    expect(find.text('Winning Plays: 3'), findsOneWidget);
    expect(find.text('Minimum-wager reference prize: \$250'), findsOneWidget);
    expect(find.text('Groups overlap; do not sum.'), findsOneWidget);
    expect(find.textContaining('Reported winning tickets:'), findsNothing);
  });
  testWidgets('missing Power Play count remains unknown, not zero', (
    tester,
  ) async {
    await show(tester, 'powerball', [
      {'match': '5', 'reportedWinningTickets': 0, 'withPowerPlay': null},
    ]);
    expect(find.text('Power Play count: Not supplied'), findsOneWidget);
    expect(find.text('Power Play count: 0'), findsNothing);
  });
  testWidgets('life prize label retains reason for withholding numeric value', (
    tester,
  ) async {
    await show(tester, 'mfl', [
      {
        'match': '5',
        'reportedWinningTickets': 0,
        'prizeLabel': '\$100,000 a Year for Life',
        'numericPrizeWithheldReason': 'API amount meaning unverified',
      },
    ]);
    expect(find.text('\$100,000 a Year for Life'), findsOneWidget);
    expect(
      find.text('Numeric prize withheld: API amount meaning unverified'),
      findsOneWidget,
    );
    expect(find.textContaining('Reported prize amount:'), findsNothing);
  });
  testWidgets('Double Play is separately labeled without Power Play count', (
    tester,
  ) async {
    await show(
      tester,
      'powerball',
      [],
      doublePlay: [
        {'match': '5', 'reportedWinningTickets': 1},
      ],
    );
    expect(find.text('Double Play — separate report tiers'), findsOneWidget);
    expect(find.textContaining('Power Play count:'), findsNothing);
  });
}
