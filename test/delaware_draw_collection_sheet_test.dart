import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/delaware_draw_collection_sheet.dart';

void main() {
  final coverage =
      jsonDecode(
            File('data/delaware_coverage.candidate.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  Future<void> select(WidgetTester tester, String value) async {
    await tester.tap(find.byType(DropdownButtonFormField<String>));
    await tester.pumpAndSettle();
    final item = find.text(value).last;
    if (find.text(value).evaluate().isEmpty) {
      await tester.scrollUntilVisible(
        find.text(value),
        value == 'Keno' ? -150 : 150,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 30,
      );
    }
    await tester.ensureVisible(item);
    await tester.tap(item);
    await tester.pumpAndSettle();
  }

  testWidgets(
    'separate Double Play and Powerball multipliers and source return',
    (tester) async {
      Uri? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: DelawareDrawCollectionSheet(
            coverage: coverage,
            openSource: (uri) async {
              opened = uri;
              return true;
            },
          ),
        ),
      );
      expect(find.textContaining('Double Play · 2026-11-04'), findsOneWidget);
      expect(find.text('Powerball: 15'), findsOneWidget);
      expect(find.textContaining('Power Play:'), findsNothing);
      await tester.tap(find.text('Official result source').first);
      await tester.pumpAndSettle();
      expect(opened!.host, 'www.delottery.com');
      expect(find.text('Powerball: 15'), findsOneWidget);
      await select(tester, 'Powerball');
      expect(find.text('Power Play: 2x'), findsOneWidget);
      expect(find.text('Powerball: 21'), findsOneWidget);
    },
  );
  testWidgets(
    'daily sessions and digits are distinct; Keno time is not inferred',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(home: DelawareDrawCollectionSheet(coverage: coverage)),
      );
      await select(tester, 'Play 3 · day');
      expect(find.text('Drawn digits: 1 4 3'), findsOneWidget);
      await select(tester, 'Play 3 · night');
      expect(find.text('Drawn digits: 5 8 2'), findsOneWidget);
      expect(find.text('Drawn digits: 1 4 3'), findsNothing);
      await select(tester, 'Keno');
      expect(
        find.text('Source display time: 11:58 PM · timezone unspecified'),
        findsOneWidget,
      );
      expect(find.text('Game number: 1464514'), findsOneWidget);
    },
  );
  testWidgets(
    'narrow 2x presentation preserves team identities without overflow',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
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
          home: DelawareDrawCollectionSheet(coverage: coverage),
        ),
      );
      await select(tester, 'Powerball Xs & Os');
      await tester.scrollUntilVisible(
        find.text('ARI · Arizona Cardinals'),
        250,
        maxScrolls: 40,
      );
      expect(find.text('ARI · Arizona Cardinals'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
