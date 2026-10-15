import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/kansas_scratch_catalog_sheet.dart';

void main() {
  final data =
      jsonDecode(
            File(
              'data/kansas_scratch_catalog.generated.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  for (final size in [const Size(390, 844), const Size(1400, 1000)]) {
    testWidgets('all catalog tiers and source footer at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (var i = 0; i < (data['catalogs'][0]['games'] as List).length; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: KansasScratchCatalogSheet(
                key: ValueKey(i),
                catalogOverride: data,
                initialIndex: i,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final game = data['catalogs'][0]['games'][i];
        expect(
          find.text('Source launch metadata: ${game['sourceLaunchMetadata']}'),
          findsOneWidget,
        );
        expect(
          find.text(
            'Source displayed launch date: ${game['sourceLaunchDisplayed']}',
          ),
          findsOneWidget,
        );
        for (final tier in game['prizeTiers']) {
          await tester.scrollUntilVisible(
            find.text(tier['prizeLabel']),
            80,
            scrollable: find.byType(Scrollable).last,
            maxScrolls: 60,
          );
          await tester.pumpAndSettle();
          expect(find.text('Remaining: ${tier['remaining']}'), findsWidgets);
          expect(tester.takeException(), isNull);
        }
        await tester.scrollUntilVisible(
          find.text('Open official Scratch list'),
          250,
          scrollable: find.byType(Scrollable).last,
          maxScrolls: 50,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
  testWidgets('short landscape leaves readable inventory viewport', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: SizedBox(
              width: 640,
              child: KansasScratchCatalogSheet(catalogOverride: data),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(tester.getSize(find.byType(ListView)).height, greaterThan(110));
    await tester.scrollUntilVisible(
      find.text('Open official Scratch list'),
      180,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 50,
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });
  testWidgets('search and price filter recover from empty selection', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: KansasScratchCatalogSheet(catalogOverride: data)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'no such game xyz');
    await tester.pumpAndSettle();
    expect(find.text('No matching games.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '257');
    await tester.pumpAndSettle();
    expect(find.textContaining('1 of 46'), findsOneWidget);
    await tester.tap(find.byType(DropdownButton<int>));
    await tester.pumpAndSettle();
    await tester.tap(find.text(r'Ticket price: $5').last);
    await tester.pumpAndSettle();
    expect(find.text('No matching games.'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '');
    await tester.pumpAndSettle();
    expect(find.text('No matching games.'), findsNothing);
    await tester.tap(find.text('Reset filters'));
    await tester.pumpAndSettle();
    expect(find.textContaining('46 of 46'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      isEmpty,
    );
    expect(tester.takeException(), isNull);
  });
}
