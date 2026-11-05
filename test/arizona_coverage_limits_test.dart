import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/arizona_draw_collection_sheet.dart';
import 'package:lottery_atlas/widgets/map/arizona_product_sheet.dart';

void main() {
  final data =
      jsonDecode(
            File(
              'test/fixtures/arizona_coverage_candidate.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  for (final products in [false, true]) {
    testWidgets('Coverage gaps accessible in ${products ? 'products' : 'draws'}', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: products
                ? ArizonaProductSheet(coverage: data)
                : ArizonaDrawCollectionSheet(coverage: data),
          ),
        ),
      );
      await tester.tap(find.text('Coverage and unavailable information'));
      await tester.pumpAndSettle();
      final gap = find.text(
        'Instant Tabs per-game coverage and complete promotion/retired history are unavailable.',
      );
      await tester.scrollUntilVisible(
        gap,
        200,
        scrollable: find.byType(Scrollable).last,
      );
      expect(gap, findsOneWidget);
      expect(
        find.text(
          'Actual payout reports, winner counts and retailer joins are unavailable.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  }
}
