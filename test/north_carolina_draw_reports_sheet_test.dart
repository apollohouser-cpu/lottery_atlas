import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/north_carolina_draw_reports_sheet.dart';

void main() {
  final data =
      jsonDecode(
            File(
              'data/north_carolina_draw_reports.generated.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  testWidgets(
    'warnings are visible before prize rows and selection resets scroll',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final reports = data['reports'] as List;
      final index = reports.indexWhere((r) => r['game'] == 'Powerball');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NorthCarolinaDrawReportsSheet(
              reportsOverride: data,
              initialIndex: index,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Source warning:'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.textContaining('Retrieved:'),
        300,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 60,
      );
      final selector = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>),
      );
      selector.onChanged!(
        reports.indexWhere((r) => r['game'] == 'Mega Millions'),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Source warning:'), findsOneWidget);
      expect(find.textContaining('accessibility label says 2'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  for (final size in [const Size(390, 844), const Size(1400, 1000)]) {
    testWidgets('all reports and footer at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (var i = 0; i < 28; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NorthCarolinaDrawReportsSheet(
                key: ValueKey(i),
                reportsOverride: data,
                initialIndex: i,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('North Carolina draw reports'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.textContaining('Retrieved:'),
          300,
          scrollable: find.byType(Scrollable).last,
          maxScrolls: 60,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
      await tester.scrollUntilVisible(
        find.textContaining('Retrieved:'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Retrieved:'), findsOneWidget);
      expect(tester.takeException(), isNull);
      await tester.scrollUntilVisible(
        find.text('Open this official report'),
        400,
        scrollable: find.byType(Scrollable).last,
      );
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
