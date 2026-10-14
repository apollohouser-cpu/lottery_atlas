import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/louisiana_draw_reports_sheet.dart';

void main() {
  final data =
      jsonDecode(
            File(
              'data/louisiana_draw_reports.generated.json',
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
      final index = reports.indexWhere((r) => r['game'] == 'Mega Millions');
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: LouisianaDrawReportsSheet(
              reportsOverride: data,
              initialIndex: index,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Source warning:'), findsWidgets);
      await tester.scrollUntilVisible(
        find.textContaining('Retrieved:'),
        300,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 160,
      );
      final selector = tester.widget<DropdownButton<int>>(
        find.byType(DropdownButton<int>),
      );
      selector.onChanged!(index + 1);
      await tester.pumpAndSettle();
      expect(find.textContaining('Source warning:'), findsWidgets);
      expect(
        find.textContaining('These entries are not summed'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('long Pick 5 combinations do not merge payout semantics', (
    tester,
  ) async {
    final semantics = tester.ensureSemantics();

    final reports = data['reports'] as List;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: LouisianaDrawReportsSheet(
            reportsOverride: data,
            initialIndex: reports.indexWhere((r) => r['game'] == 'Pick 5'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final payout = find.text(r'Payout (50¢): $400');
    await tester.scrollUntilVisible(
      payout,
      250,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 160,
    );
    await tester.pumpAndSettle();
    expect(tester.getSemantics(payout).label, r'Payout (50¢): $400');
    semantics.dispose();
    expect(tester.takeException(), isNull);
  });
  for (final size in [const Size(390, 844), const Size(1400, 1000)]) {
    testWidgets('all reports and footer at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (var i = 0; i < 14; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: LouisianaDrawReportsSheet(
                key: ValueKey(i),
                reportsOverride: data,
                initialIndex: i,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Louisiana draw reports'), findsOneWidget);
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.textContaining('Retrieved:'),
          300,
          scrollable: find.byType(Scrollable).last,
          maxScrolls: 160,
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
