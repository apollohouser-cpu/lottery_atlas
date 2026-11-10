import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/delaware_product_sheet.dart';

void main() {
  final coverage =
      jsonDecode(
            File('data/delaware_coverage.candidate.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  Map detail(String id) => (coverage['instantProductDetails'] as List)
      .cast<Map>()
      .firstWhere((row) => row['gameId'] == id);

  testWidgets(
    'search preserves shared identity and source return keeps detail',
    (tester) async {
      Uri? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: DelawareProductSheet(
            coverage: coverage,
            openSource: (uri) async {
              opened = uri;
              return true;
            },
          ),
        ),
      );
      await tester.enterText(find.byType(TextField), '528');
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('delaware-product-528')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Official illustrated rules'));
      await tester.pumpAndSettle();
      expect(opened.toString(), detail('528')['instructions']['sourceUrl']);
      expect(find.byType(DelawareProductDetail), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(ListTile), findsOneWidget);
      expect(
        find.byKey(const ValueKey('delaware-product-528')),
        findsOneWidget,
      );
    },
  );

  testWidgets('excluded annuity retains face value and exposes qualification', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(home: DelawareProductDetail(detail: detail('443'))),
    );
    expect(
      find.textContaining('Advertised top prize: \$1000000'),
      findsOneWidget,
    );
    await tester.scrollUntilVisible(
      find.text('Prize structure unavailable'),
      250,
    );
    expect(find.text('Prize structure unavailable'), findsOneWidget);
    expect(
      find.text(detail('443')['prizeStructureExclusion']['reason']),
      findsOneWidget,
    );
    expect(find.text('Printed prize structure'), findsNothing);
  });

  testWidgets('reviewed columns remain literal at narrow explicit 2x text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: DelawareProductDetail(detail: detail('504')),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Printed prize structure'),
      350,
      maxScrolls: 50,
    );
    await tester.scrollUntilVisible(
      find.text('Game1: \$10'),
      200,
      maxScrolls: 50,
    );
    expect(find.text('Game1: \$10'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('source failure is visible and does not lose detail', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DelawareProductDetail(
          detail: detail('451'),
          openSource: (_) async => false,
        ),
      ),
    );
    await tester.tap(find.text('Official inventory source'));
    await tester.pump();
    expect(find.text('Could not open the official source.'), findsOneWidget);
    expect(find.byType(DelawareProductDetail), findsOneWidget);
  });
}
