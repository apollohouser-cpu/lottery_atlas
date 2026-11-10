import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/delaware_coverage_limits.dart';

void main() {
  final coverage =
      jsonDecode(
            File('data/delaware_coverage.candidate.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  testWidgets(
    'closeouts preserve sales dates and source provenance without claim dates',
    (tester) async {
      Uri? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: DelawareCoverageLimits(
            coverage: coverage,
            openSource: (uri) async {
              opened = uri;
              return true;
            },
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Official closeout schedule'),
        200,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Official closeout schedule'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Official closeout schedule'));
      expect(opened.toString(), coverage['productEvidence']['closeout']['url']);
      for (final row in coverage['closeouts'] as List) {
        await tester.scrollUntilVisible(
          find.text('Game #${row['gameId']}'),
          150,
          maxScrolls: 50,
        );
        expect(find.text('Launch date: ${row['dateLaunched']}'), findsWidgets);
        expect(
          find.text('Announced end of sales: ${row['announcedEndOfSales']}'),
          findsWidgets,
        );
      }
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('limitations stay readable at narrow explicit 2x size', (
    tester,
  ) async {
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
        home: DelawareCoverageLimits(coverage: coverage),
      ),
    );
    await tester.scrollUntilVisible(
      find.textContaining('No verified within-state'),
      250,
      maxScrolls: 40,
    );
    expect(
      find.textContaining('Draw numbers do not create map heat points.'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
