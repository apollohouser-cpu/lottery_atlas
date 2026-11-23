import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/connecticut_draw_collection_sheet.dart';
import 'package:lottery_atlas/widgets/map/connecticut_report_sheet.dart';
import 'package:lottery_atlas/widgets/map/connecticut_scratch_detail.dart';

// Explicit local audit only. No private source payload is committed or bundled.
const candidatePath = String.fromEnvironment('CT_CANDIDATE_PATH');

void main() {
  testWidgets(
    'reviewed private candidate renders every result, report and Scratch detail',
    (tester) async {
      final candidate =
          jsonDecode(File(candidatePath).readAsStringSync())
              as Map<String, dynamic>;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetDevicePixelRatio);
      addTearDown(tester.view.resetPhysicalSize);
      Future<void> inspect(Widget widget) async {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: tester.view.physicalSize,
                textScaler: TextScaler.linear(2),
              ),
              child: widget,
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final scroll = find.byType(Scrollable).first;
        await tester.drag(scroll, const Offset(0, -800));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        await tester.pumpWidget(const SizedBox.shrink());
      }

      for (final size in [const Size(390, 844), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        for (final row in candidate['draws'] as List) {
          // Select each group by constructing its exact single-group view;
          // source rows, linked reports and rules stay unchanged.
          await inspect(
            ConnecticutDrawCollectionSheet(
              coverage: {
                ...candidate,
                'draws': [row],
              },
            ),
          );
        }
        for (final report in candidate['reports'] as List) {
          await inspect(
            ConnecticutReportSheet(report: Map<String, dynamic>.from(report)),
          );
        }
        for (final game in candidate['scratchCatalog']['games'] as List) {
          await inspect(
            ConnecticutScratchDetail(game: Map<String, dynamic>.from(game)),
          );
        }
      }
    },
    skip: candidatePath.isEmpty,
  );
}
