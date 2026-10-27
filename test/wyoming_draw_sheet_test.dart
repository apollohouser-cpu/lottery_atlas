import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/wyoming_draw_collection_sheet.dart';

void main() {
  final data =
      jsonDecode(
            File('data/wyoming_coverage.generated.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  testWidgets('all dated selections render enlarged portrait and landscape', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      tester.view.physicalSize = size;
      for (var i = 0; i < (data['results'] as List).length; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(2),
              ),
              child: Scaffold(
                body: WyomingDrawCollectionSheet(
                  key: ValueKey('$size-$i'),
                  coverageOverride: data,
                  initialIndex: i,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byTooltip('Official game source'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$size selection $i');
      }
    }
  });
  testWidgets('fixed paging reaches every family rules and limits', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      tester.view.physicalSize = size;
      final seen = <String>{};
      final rows = data['results'] as List;
      for (var i = 0; i < rows.length; i++) {
        final key = '${rows[i]['game']}';
        if (!seen.add(key)) continue;
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(2),
              ),
              child: Scaffold(
                body: WyomingDrawCollectionSheet(
                  key: ValueKey('$size-$key'),
                  coverageOverride: data,
                  initialIndex: i,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (var page = 0; page < 600; page++) {
          await tester.tap(find.byTooltip('Next page'));
          await tester.pumpAndSettle();
          if (find.text('Official dated results').evaluate().isNotEmpty) {
            break;
          }
        }
        expect(find.text('Coverage limits'), findsOneWidget, reason: key);
        expect(find.textContaining('null'), findsNothing, reason: key);
        expect(tester.takeException(), isNull, reason: key);
      }
      expect(seen.length, 6);
    }
  });
}
