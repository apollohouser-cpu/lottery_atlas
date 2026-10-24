import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/idaho_product_sheet.dart';

void main() {
  final data =
      jsonDecode(File('test/fixtures/idaho_coverage_20261023.json').readAsStringSync())
          as Map<String, dynamic>;
  testWidgets(
    'four product types and details traverse at 2x portrait and landscape',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final size in [const Size(390, 844), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        for (final type in ['Scratch', 'InstaPlay', 'Tabs', 'Raffle']) {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(2),
                ),
                child: Scaffold(
                  body: IdahoProductSheet(
                    key: ValueKey('$size-$type'),
                    coverageOverride: data,
                    initialType: type,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          await tester.scrollUntilVisible(
            find.widgetWithText(
              ListTile,
              {
                'Scratch': 'Starry Night 1935',
                'InstaPlay': 'Jackpot USA 300005',
                'Tabs': 'Wild Thing - Touchtab 7551',
                'Raffle': 'Idaho Raffle 2026 ',
              }[type]!,
            ),
            200,
            scrollable: find.byType(Scrollable).first,
            maxScrolls: 40,
          );
          await Scrollable.ensureVisible(
            tester.element(find.byType(ListTile).first),
            alignment: 0.3,
          );
          await tester.pumpAndSettle();
          await tester.tap(find.byType(ListTile).first);
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull, reason: '$size $type detail');
          await tester.scrollUntilVisible(
            find.text('Official game details'),
            250,
            scrollable: find.byType(Scrollable).last,
            maxScrolls: 200,
          );
          expect(
            find.text('Official game details').hitTestable(),
            findsOneWidget,
          );
          expect(tester.takeException(), isNull);
          await tester.tap(find.byTooltip('Close game details'));
          await tester.pumpAndSettle();
        }
      }
    },
  );
  testWidgets(
    'unavailable Scratch remains visible through search and detail return',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: IdahoProductSheet(coverageOverride: data)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Mistletoe');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.byType(ListTile),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(find.textContaining('Inventory unavailable'), findsOneWidget);
      await tester.tap(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Remaining prizes unavailable — not zero.'),
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(
        find.text('Remaining prizes unavailable — not zero.'),
        findsOneWidget,
      );
      await tester.tap(find.byTooltip('Close game details'));
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
