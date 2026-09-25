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
      expect(find.text('2,465'), findsOneWidget);
      expect(
        find.textContaining('Source publication date unavailable'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Powerball Xs & Os').last);
      await tester.pumpAndSettle();
      expect(find.text('831'), findsOneWidget);
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Powerball').last);
      await tester.pumpAndSettle();
      expect(find.text('7,152'), findsOneWidget);
      expect(find.text('1,324'), findsOneWidget);
      expect(
        find.textContaining('included in Kentucky winners'),
        findsOneWidget,
      );
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Powerball Double Play').last);
      await tester.pumpAndSettle();
      expect(find.text('704'), findsOneWidget);
      expect(find.textContaining('separate drawing'), findsOneWidget);
      expect(find.text('2,465'), findsNothing);
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
}
