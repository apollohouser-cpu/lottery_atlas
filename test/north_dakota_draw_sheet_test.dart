import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/north_dakota_draw_collection_sheet.dart';

void main() {
  final data =
      jsonDecode(
            File(
              'data/north_dakota_coverage.generated.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  testWidgets('all dated selections render enlarged portrait and landscape', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      tester.view.physicalSize = size;
      for (var i = 0; i < (data['results'] as List).length; i++) {
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(2),
              ),
              child: Scaffold(
                body: NorthDakotaDrawCollectionSheet(
                  key: ValueKey('$size-$i'),
                  coverageOverride: data,
                  initialIndex: i,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byTooltip('Official game source'), findsOneWidget);
        expect(tester.takeException(), isNull, reason: '$size selection $i');
      }
    }
  });
  testWidgets('fixed paging reaches every family rules and limits', (
    tester,
  ) async {
    tester.view.devicePixelRatio = 1;
    tester.view.physicalSize = const Size(390, 844);
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final size in [const Size(390, 844), const Size(844, 390)]) {
      tester.view.physicalSize = size;
      final seen = <String>{};
      final rows = data['results'] as List;
      for (var i = 0; i < rows.length; i++) {
        final key = '${rows[i]['game']}';
        if (!seen.add(key)) continue;
        await tester.pumpWidget(
          MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(
                size: size,
                textScaler: const TextScaler.linear(2),
              ),
              child: Scaffold(
                body: NorthDakotaDrawCollectionSheet(
                  key: ValueKey('$size-$key'),
                  coverageOverride: data,
                  initialIndex: i,
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        for (var page = 0; page < 600; page++) {
          await tester.tap(find.byTooltip('Next page'));
          await tester.pumpAndSettle();
          if (find.text('Official dated results').evaluate().isNotEmpty) {
            break;
          }
        }
        expect(find.text('Coverage limits'), findsOneWidget, reason: key);
        expect(find.textContaining('null'), findsNothing, reason: key);
        expect(tester.takeException(), isNull, reason: key);
      }
      expect(seen.length, 5);
    }
  });
  testWidgets('2by2 merged prizes remain attached to every matching pattern', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: NorthDakotaDrawCollectionSheet(
            coverageOverride: data,
            initialIndex: 8,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    final observed = <String>{};
    for (var page = 0; page < 100; page++) {
      for (final widget in tester.widgetList<Text>(find.byType(Text))) {
        if (widget.data != null) observed.add(widget.data!);
      }
      await tester.tap(find.byTooltip('Next page'));
      await tester.pumpAndSettle();
    }
    for (final expected in [
      'Match 2 Red Numbers + 1 White Number',
      'Match 1 Red Number + 2 White Numbers',
      'Match 2 Red Numbers',
      'Match 2 White Numbers',
      'Match 1 Red Number + 1 White Number',
      'Match 1 Red Number',
      'Match 1 White Number',
      'Prize: Free Ticket',
      'Qualifying Tuesday double prize: 2 Free Tickets',
    ]) {
      expect(observed, contains(expected));
    }
    expect(tester.takeException(), isNull);
  });
}
