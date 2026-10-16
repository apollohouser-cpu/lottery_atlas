import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/kansas_draw_collection_sheet.dart';
import 'package:lottery_atlas/widgets/map/kansas_scratch_catalog_sheet.dart';

void main() {
  for (final scratch in [true, false]) {
    testWidgets(
      'Kansas ${scratch ? 'Scratch' : 'reports'} at double text size',
      (tester) async {
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final data =
            jsonDecode(
                  File(
                    scratch
                        ? 'data/kansas_scratch_catalog.generated.json'
                        : 'data/kansas_draw_collection.generated.json',
                  ).readAsStringSync(),
                )
                as Map<String, dynamic>;
        await tester.pumpWidget(
          MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2)),
              child: child!,
            ),
            home: Scaffold(
              body: scratch
                  ? KansasScratchCatalogSheet(catalogOverride: data)
                  : KansasDrawCollectionSheet(reportsOverride: data),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(ListView)).height, greaterThan(100));
        await tester.scrollUntilVisible(
          find.text(
            scratch ? 'Open official Scratch list' : 'Open official game page',
          ),
          150,
          scrollable: find.byType(Scrollable).last,
          maxScrolls: 200,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      },
    );
  }
}
