import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/new_york_prize_tables_sheet.dart';

void main() {
  final data =
      jsonDecode(
            File(
              'data/new_york_draw_reports.generated.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  for (final size in [const Size(400, 640), const Size(1280, 900)]) {
    testWidgets('all report selections fit $size and retain source scope', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final reports = data['reports'] as List;
      for (var i = 0; i < reports.length; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: NewYorkPrizeTablesSheet(
                key: ValueKey(i),
                reportsOverride: data,
                initialIndex: i,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'report $i');
        expect(find.text(reports[i]['jurisdiction'] as String), findsOneWidget);
        if ([
          'NUMBERS',
          'Win4',
          'Quick Draw / Money Dots',
        ].contains(reports[i]['gameName'])) {
          expect(find.text('Winner count: unavailable'), findsOneWidget);
        }
      }
    });
  }
}
