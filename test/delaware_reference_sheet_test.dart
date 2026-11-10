import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/delaware_reference_sheet.dart';

void main() {
  final coverage =
      jsonDecode(
            File('data/delaware_coverage.candidate.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  testWidgets(
    'all ten rule and eight report contracts render with original provenance',
    (tester) async {
      for (final reports in [false, true]) {
        final entries =
            (reports
                    ? coverage['publishedReports']['reports']
                    : coverage['rules']['rules'])
                as List;
        for (final entry in entries) {
          await tester.pumpWidget(
            MaterialApp(
              home: DelawareReferenceDetail(
                key: UniqueKey(),
                entry: entry,
                reports: reports,
              ),
            ),
          );
          expect(find.textContaining('Source observed:'), findsWidgets);
          expect(tester.takeException(), isNull, reason: entry['family']);
        }
      }
    },
  );
  testWidgets('Play 3 retains literal zero counts and does not infer payouts', (
    tester,
  ) async {
    final entry = (coverage['publishedReports']['reports'] as List).firstWhere(
      (x) => x['family'] == 'Play-3',
    );
    await tester.pumpWidget(
      MaterialApp(home: DelawareReferenceDetail(entry: entry, reports: true)),
    );
    await tester.scrollUntilVisible(
      find.text('Published category count: 0').first,
      250,
    );
    expect(find.text('Published category count: 0'), findsWidgets);
    expect(find.text('Source 50-cent bet prize: \$80'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Total Won: \$20,170'), 250);
    expect(find.text('Source totals (not recomputed)'), findsOneWidget);
  });
  testWidgets(
    'Mega Millions effective date and original average-prize column stay distinct at 2x',
    (tester) async {
      tester.view.physicalSize = const Size(320, 700);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final entry = (coverage['rules']['rules'] as List).firstWhere(
        (x) => x['family'] == 'Mega-Millions',
      );
      Uri? opened;
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: DelawareReferenceDetail(
            entry: entry,
            reports: false,
            openSource: (uri) async {
              opened = uri;
              return true;
            },
          ),
        ),
      );
      await tester.scrollUntilVisible(
        find.text('Official source'),
        200,
        maxScrolls: 40,
      );
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Official source').first);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Official source').first);
      expect(opened!.host, 'www.delottery.com');
      await tester.scrollUntilVisible(
        find.text('Effective Date: 2025-04-05'),
        200,
        maxScrolls: 40,
      );
      await tester.scrollUntilVisible(
        find.text('Source AVERAGE PRIZE column: \$1,000,000'),
        200,
        maxScrolls: 40,
      );
      expect(
        find.text('Prize Range: \$2,000,000 - \$10,000,000'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
