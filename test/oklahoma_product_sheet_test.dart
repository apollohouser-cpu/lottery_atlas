import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/oklahoma_product_sheet.dart';

void main() {
  final data =
      jsonDecode(
            File('data/oklahoma_coverage.generated.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  testWidgets(
    'two product types and details traverse at 2x portrait and landscape',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final size in [const Size(390, 844), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        for (final type in ['Scratch', 'Fast Play']) {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(2),
                ),
                child: Scaffold(
                  body: OklahomaProductSheet(
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
                'Scratch': 'Cash Flash 858',
                'Fast Play': "Blazin' Bucks Progressive 242",
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
      final unknown = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
      final game = unknown['products']['scratch']['games'][0];
      game['prizeTiers'] = [];
      game['topPrizesRemaining'] = null;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: OklahomaProductSheet(coverageOverride: unknown)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), 'Cash Flash');
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
