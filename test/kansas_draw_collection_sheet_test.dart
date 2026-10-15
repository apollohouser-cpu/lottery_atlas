import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/kansas_draw_collection_sheet.dart';

void main() {
  final data =
      jsonDecode(
            File(
              'data/kansas_draw_collection.generated.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  for (final size in [const Size(390, 844), const Size(1400, 1000)]) {
    testWidgets('all 24 result selections render at $size', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (var i = 0; i < 24; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: KansasDrawCollectionSheet(
                key: ValueKey(i),
                reportsOverride: data,
                initialIndex: i,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Kansas results and schedules'), findsOneWidget);
        expect(find.text(data['reports'][i]['coverage']), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'selection $i');
      }
    });
  }
  testWidgets('Keno schedule warning and source footer reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final index = (data['reports'] as List).indexWhere(
      (r) => r['group'] == 'keno',
    );
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: KansasDrawCollectionSheet(
            reportsOverride: data,
            initialIndex: index,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Literal prize schedules — not actual winners'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('not zero'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Retrieved: ${data['retrievedAt']}'),
      250,
      scrollable: find.byType(Scrollable).last,
      maxScrolls: 300,
    );
    expect(find.text('Retrieved: ${data['retrievedAt']}'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Open official game page'),
      300,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.text('Open official game page'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
