import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/montana_product_sheet.dart';

void main() {
  final data =
      jsonDecode(
            File('data/montana_coverage.generated.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  testWidgets(
    'all four product paths and detail sources work at2x both orientations',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      for (final size in [const Size(390, 844), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        for (final type in [
          'Scratch',
          'Treasure Play',
          'Raffle',
          'Ending notice',
        ]) {
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(2),
                ),
                child: Scaffold(
                  body: MontanaProductSheet(
                    key: ValueKey('$size$type'),
                    coverageOverride: data,
                    initialType: type,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (type == 'Scratch' || type == 'Treasure Play') {
            for (
              var p = 0;
              p < 30 && find.byType(ListTile).evaluate().isEmpty;
              p++
            ) {
              await tester.tap(find.byTooltip('Next product page'));
              await tester.pumpAndSettle();
            }
            await tester.ensureVisible(find.byType(ListTile).first);
            await tester.pumpAndSettle();
            await tester.tapAt(
              tester.getTopLeft(find.byType(ListTile).first) +
                  const Offset(24, 24),
            );
            await tester.pumpAndSettle();
            expect(find.byTooltip('Close product details'), findsOneWidget);
          }
          final target = type == 'Raffle'
              ? 'Official raffle offer'
              : type == 'Ending notice'
              ? 'Official ending notice'
              : 'Official product catalog';
          for (var p = 0; p < 600; p++) {
            if (find.text(target).hitTestable().evaluate().isNotEmpty) break;
            await tester.tap(find.byTooltip('Next product page').last);
            await tester.pumpAndSettle();
          }
          expect(
            find.text(target).hitTestable(),
            findsOneWidget,
            reason: '$size $type',
          );
          expect(tester.takeException(), isNull, reason: '$size $type');
          if (type == 'Scratch' || type == 'Treasure Play') {
            await tester.tap(find.byTooltip('Close product details'));
            await tester.pumpAndSettle();
          }
        }
      }
    },
  );
  testWidgets(
    'missing title search and detail return preserve unavailable status',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MontanaProductSheet(coverageOverride: data)),
        ),
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), '2863');
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byType(ListTile).first);
      await tester.pumpAndSettle();
      expect(find.text('Title unavailable'), findsOneWidget);
      await tester.tapAt(
        tester.getTopLeft(find.byType(ListTile).first) + const Offset(24, 24),
      );
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close product details'), findsOneWidget);
      await tester.tap(find.byTooltip('Close product details'));
      await tester.pumpAndSettle();
      expect(find.text('Title unavailable'), findsOneWidget);
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'no such product xyz');
      await tester.pumpAndSettle();
      expect(find.text('No matching catalog entries.'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
