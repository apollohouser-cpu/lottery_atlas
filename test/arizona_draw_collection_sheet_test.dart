import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/arizona_draw_collection_sheet.dart';

void main() {
  final data =
      jsonDecode(
            File(
              'test/fixtures/arizona_coverage_candidate.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  test('all nineteen result types preserve source fields and digit order', () {
    expect(
      (data['drawGroups'] as Map).keys.toSet(),
      ArizonaDrawCollectionSheet.labels.keys.toSet(),
    );
    for (final rows in (data['drawGroups'] as Map).values) {
      for (final row in rows) {
        expect(ArizonaDrawCollectionSheet.resultText(row), isNotEmpty);
      }
    }
    expect(
      ArizonaDrawCollectionSheet.resultText({'digits': '0012'}),
      'Ordered digits: 0012',
    );
    expect(
      ArizonaDrawCollectionSheet.resultText({
        'diceLabels': ['ONE', 'ONE', 'SIX', 'TWO', 'ONE'],
      }),
      'Dice in source order: ONE · ONE · SIX · TWO · ONE',
    );
  });
  testWidgets('date-only display and source opening', (tester) async {
    Uri? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArizonaDrawCollectionSheet(
            coverage: data,
            openSource: (uri) async {
              opened = uri;
              return true;
            },
          ),
        ),
      ),
    );
    expect(find.textContaining('2026-11-04 · date only'), findsOneWidget);
    await tester.tap(find.text('Official result source').first);
    await tester.pumpAndSettle();
    expect(
      opened.toString(),
      'https://www.arizonalottery.com/draw-games/powerball/',
    );
    expect(tester.takeException(), isNull);
  });
  testWidgets('hourly selection shows draw identity and Arizona time at 2x', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
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
        home: Scaffold(body: ArizonaDrawCollectionSheet(coverage: data)),
      ),
    );
    await tester.tap(find.text('Powerball').last);
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('One To Win'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    await tester.drag(find.byType(Scrollable).last, const Offset(0, -200));
    await tester.pumpAndSettle();
    await tester.tap(find.text('One To Win').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('4:45 AM Arizona time'), findsOneWidget);
    expect(find.text('Draw ID: 36326'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
