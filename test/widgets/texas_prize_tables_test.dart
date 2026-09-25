import 'dart:convert';
import 'dart:io';
import 'package:lottery_atlas/services/texas_prize_tables_loader.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/texas_prize_tables_sheet.dart';

void main() {
  testWidgets(
    'offline bundled table supports game selection and coverage dialog',
    (tester) async {
      final raw = File(
        'data/texas_draw_tiers.generated.json',
      ).readAsStringSync();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TexasPrizeTablesSheet(
              loader: TexasPrizeTablesLoader(
                readCache: () async => null,
                fetchRemote: () async => throw const SocketException('offline'),
                readBundle: () async => raw,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(DropdownButton<int>), findsOneWidget);
      await tester.tap(find.text('Missing games?'));
      await tester.pumpAndSettle();
      expect(find.text('Pick 3 and Daily 4 coverage'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'Texas statewide report is separate, dated, scrollable and switches games',
    (tester) async {
      final data =
          jsonDecode(
                File('data/texas_draw_tiers.generated.json').readAsStringSync(),
              )
              as Map<String, dynamic>;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: TexasPrizeTablesSheet(reportsOverride: data)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.text('Reported winners by tier • Not retailer map counts'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Source publication date unavailable'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      final dropdown = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>),
      );
      final mm = (data['reports'] as List).indexWhere(
        (r) => r['gameName'] == 'Mega Millions',
      );
      dropdown.onChanged!(mm);
      await tester.pumpAndSettle();
      expect(find.text('10X Winners'), findsOneWidget);
      expect(find.text('Open official draw report'), findsOneWidget);
      await tester.tap(find.text('Missing games?'));
      await tester.pumpAndSettle();
      expect(find.text('Pick 3 and Daily 4 coverage'), findsOneWidget);
      expect(
        find.textContaining('does not mean there were zero winners'),
        findsOneWidget,
      );
      expect(find.text('Pick 3 official results'), findsOneWidget);
      expect(find.text('Daily 4 official results'), findsOneWidget);
      await tester.tap(find.text('Close'));
      await tester.pumpAndSettle();
      expect(find.text('Mega Millions'), findsWidgets);
      expect(tester.takeException(), isNull);
    },
  );
}
