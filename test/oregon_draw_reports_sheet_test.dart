import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/oregon_draw_reports_sheet.dart';

void main() {
  final data =
      jsonDecode(
            File('data/oregon_draw_reports.generated.json').readAsStringSync(),
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
              body: OregonDrawReportsSheet(
                key: ValueKey(i),
                reportsOverride: data,
                initialIndex: i,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull, reason: 'report $i');
        expect(
          find.text('Distinct ticket and person counts: unverified'),
          findsOneWidget,
        );
        if (reports[i]['tiers'] == null) {
          expect(
            find.text(
              'Reported Oregon winners: ${reports[i]['reportedWinners']}',
            ),
            findsOneWidget,
          );
        } else {
          expect(find.text('Published prize rows'), findsOneWidget);
        }
        await tester.scrollUntilVisible(
          find.text('Mega Millions — historical'),
          400,
          scrollable: find.descendant(
            of: find.byType(ListView),
            matching: find.byType(Scrollable),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(find.text('Mega Millions — historical'), findsOneWidget);
      }
    });
  }
}
