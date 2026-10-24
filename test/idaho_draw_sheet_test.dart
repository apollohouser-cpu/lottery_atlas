import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/idaho_draw_collection_sheet.dart';

void main() {
  final data =
      jsonDecode(File('test/fixtures/idaho_coverage_20261023.json').readAsStringSync())
          as Map<String, dynamic>;
  testWidgets(
    'retained report displays original date and no reverification claim',
    (tester) async {
      final retained = jsonDecode(jsonEncode(data)) as Map<String, dynamic>;
      final index = (retained['results'] as List).indexWhere(
        (r) => r['group'] == 'millionaire-for-life' && r['report'] != null,
      );
      retained['results'][index]['reportProvenance'] = {
        'collectionStartedAt': '2026-10-23T11:41:13.552741+00:00',
      };
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IdahoDrawCollectionSheet(
              coverageOverride: retained,
              initialIndex: index,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining(
          'Retained exact-date report. Originally collected: 2026-10-23T11:41:13.552741+00:00. Not reverified',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'all twenty-two selections render at enlarged text without errors',
    (tester) async {
      for (var i = 0; i < 22; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: const MediaQueryData(
                size: Size(390, 844),
                textScaler: TextScaler.linear(2),
              ),
              child: Scaffold(
                body: IdahoDrawCollectionSheet(
                  key: ValueKey(i),
                  coverageOverride: data,
                  initialIndex: i,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('Idaho results and schedules'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: 'selection $i');
      }
    },
  );
  testWidgets(
    'Double Play retains distinct chart and explicit shared-page warning',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: IdahoDrawCollectionSheet(
              coverageOverride: data,
              initialIndex: 1,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Shared Powerball and Double Play schedule'),
        500,
        scrollable: find.byType(Scrollable).last,
        maxScrolls: 35,
      );
      expect(
        find.textContaining(
          'Power Play multipliers and regular jackpot terms do not apply to Double Play.',
        ),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'long schedules reach final source at 2x in portrait and landscape',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final size in [const Size(390, 844), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        for (final index in [0, 1, 4, 6, 8, 10, 14, 18, 20]) {
          await tester.pumpWidget(
            MaterialApp(
              home: MediaQuery(
                data: MediaQueryData(
                  size: size,
                  textScaler: const TextScaler.linear(2),
                ),
                child: Scaffold(
                  body: IdahoDrawCollectionSheet(
                    key: ValueKey('$size-$index'),
                    coverageOverride: data,
                    initialIndex: index,
                  ),
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          expect(
            tester.takeException(),
            isNull,
            reason: 'initial $size selection $index',
          );
          await tester.scrollUntilVisible(
            find.text('Official dated result source'),
            250,
            scrollable: find.byType(Scrollable).last,
            maxScrolls: 250,
          );
          await tester.pumpAndSettle();
          expect(
            find.text('Official dated result source').hitTestable(),
            findsOneWidget,
          );
          expect(
            tester.takeException(),
            isNull,
            reason: 'end $size selection $index',
          );
        }
      }
    },
  );
}
