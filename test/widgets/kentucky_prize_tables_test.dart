import 'dart:io';
import 'dart:convert';
import 'package:lottery_atlas/services/kentucky_prize_tables_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/kentucky_prize_tables_sheet.dart';

void main() {
  testWidgets(
    'Kentucky offline tiers stay separate and switch distinct games',
    (tester) async {
      final raw = File(
        'data/kentucky_draw_tiers.generated.json',
      ).readAsStringSync();
      final reports =
          (jsonDecode(raw) as Map<String, dynamic>)['reports'] as List;
      void expectDisplayedTotals(int reportIndex) {
        final table = tester.widget<DataTable>(find.byType(DataTable));
        final displayed = table.rows.last.cells.map((cell) {
          final value = (cell.child as SizedBox).child! as Text;
          return value.data;
        }).toList();
        expect(displayed, reports[reportIndex]['reportedTotals']);
        expect(
          find.textContaining('Draw date: ${reports[reportIndex]['drawDate']}'),
          findsOneWidget,
        );
      }

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: KentuckyPrizeTablesSheet(
              loader: KentuckyPrizeTablesLoader(
                readCache: () async => null,
                fetchRemote: () async => throw const SocketException('offline'),
                readBundle: () async => raw,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Kentucky statewide prize tables'), findsOneWidget);
      expect(
        find.text('Reported winners by tier • Not retailer map counts'),
        findsOneWidget,
      );
      expectDisplayedTotals(0);
      expect(
        find.textContaining('Source publication date unavailable'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Powerball Xs & Os').last);
      await tester.pumpAndSettle();
      expectDisplayedTotals(1);
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Powerball').last);
      await tester.pumpAndSettle();
      expectDisplayedTotals(2);
      expect(
        find.textContaining('included in Kentucky winners'),
        findsOneWidget,
      );
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Powerball Double Play').last);
      await tester.pumpAndSettle();
      expectDisplayedTotals(3);
      expect(find.textContaining('separate drawing'), findsOneWidget);
      expect(find.text('Open official draw report'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'state reports retain each session, EZ separation and life limitation',
    (tester) async {
      final data =
          jsonDecode(
                File(
                  'data/kentucky_draw_tiers.generated.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: KentuckyPrizeTablesSheet(reportsOverride: data)),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 4; i < 10; i++) {
        tester
            .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .onChanged!(i);
        await tester.pumpAndSettle();
        final report = data['reports'][i];
        expect(
          find.textContaining('Draw date: ${report['drawDate']}'),
          findsOneWidget,
        );
        expect(find.text(report['tableNote']), findsOneWidget);
        if (i == 4) {
          expect(
            find.textContaining('annuity/cash basis not established'),
            findsOneWidget,
          );
        }
        if (i == 5) {
          expect(
            find.textContaining('Excluded from base totals'),
            findsOneWidget,
          );
        }
        if (i >= 6) {
          expect(
            find.text('${report['gameName']} · ${report['drawingSession']}'),
            findsOneWidget,
          );
        }
        expect(tester.takeException(), isNull);
      }
    },
  );
  testWidgets(
    'aggregate games disclose draw identity and switch back to tiers',
    (tester) async {
      final data =
          jsonDecode(
                File(
                  'data/kentucky_draw_tiers.generated.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: KentuckyPrizeTablesSheet(reportsOverride: data)),
        ),
      );
      await tester.pumpAndSettle();
      for (var i = 10; i < 12; i++) {
        tester
            .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .onChanged!(i);
        await tester.pumpAndSettle();
        final report = data['aggregateSnapshot']['reports'][i - 10];
        expect(
          find.textContaining('Draw ID: ${report['drawId']}'),
          findsOneWidget,
        );
        expect(
          find.textContaining(
            'Reported Kentucky winners: ${report['reportedWinners']}',
          ),
          findsOneWidget,
        );
        expect(find.textContaining('not a live four-minute'), findsOneWidget);
        expect(find.byType(DataTable), findsNothing);
        expect(tester.takeException(), isNull);
      }
      tester
          .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
          .onChanged!(0);
      await tester.pumpAndSettle();
      expect(find.byType(DataTable), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
