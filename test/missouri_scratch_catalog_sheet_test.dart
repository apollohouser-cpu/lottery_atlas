import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/missouri_scratch_catalog_sheet.dart';

void main() {
  final data =
      jsonDecode(
            File(
              'data/missouri_scratch_catalog.generated.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  for (final size in [const Size(390, 844), const Size(1400, 1000)]) {
    testWidgets('all catalog tiers and source footer at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (var i = 0; i < (data['games'] as List).length; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: MissouriScratchCatalogSheet(
                key: ValueKey(i),
                catalogOverride: data,
                initialIndex: i,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.scrollUntilVisible(
          find.text('Open official Scratchers list'),
          250,
          scrollable: find.byType(Scrollable).last,
          maxScrolls: 50,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
  testWidgets('search and price filter recover from empty selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MissouriScratchCatalogSheet(catalogOverride: data),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'no such game xyz');
    await tester.pumpAndSettle();
    expect(find.text('No matching games.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '359');
    await tester.pumpAndSettle();
    expect(find.textContaining('1 of 73'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(r'Ticket price: $1').last);
    await tester.pumpAndSettle();
    expect(find.text('No matching games.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('No matching games.'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
