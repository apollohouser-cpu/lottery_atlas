import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/south_carolina_prize_tables_sheet.dart';

void main() {
  for (final size in [const Size(800, 632), const Size(1280, 900)]) {
    testWidgets('SC reports fit $size and expose dated session choices', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final data =
          jsonDecode(
                File(
                  'data/south_carolina_draw_reports.generated.json',
                ).readAsStringSync(),
              )
              as Map<String, dynamic>;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SouthCarolinaPrizeTablesSheet(reportsOverride: data),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('South Carolina draw reports'), findsOneWidget);
      expect(find.text('Open official draw report'), findsOneWidget);
      expect(tester.takeException(), isNull);
      for (var i = 0; i < (data['reports'] as List).length; i++) {
        tester
            .widget<DropdownButton<int>>(find.byType(DropdownButton<int>))
            .onChanged!(i);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
