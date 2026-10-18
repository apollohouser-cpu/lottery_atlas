import 'package:lottery_atlas/services/nebraska_scratch_catalog_loader.dart';
import 'package:lottery_atlas/widgets/map/nebraska_scratch_catalog_sheet.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/nebraska_collection_validator.dart';
import 'package:lottery_atlas/services/nebraska_collection_loader.dart';
import 'package:lottery_atlas/widgets/map/nebraska_draw_collection_sheet.dart';

void main() {
  final scratchRaw = File(
    'data/nebraska_scratch_catalog.generated.json',
  ).readAsStringSync();
  test('Scratch reviewed counts and physical tiers validate', () {
    final d = NebraskaScratchCatalogLoader.decode(scratchRaw);
    expect(d['catalogs'][0]['games'].length, 24);
    final changed = jsonDecode(scratchRaw);
    changed['catalogs'][0]['sourceDate'] = '2026-10-18';
    expect(
      () => NebraskaScratchCatalogLoader.decode(jsonEncode(changed)),
      throwsFormatException,
    );
  });
  testWidgets('Scratch filters at enlarged text and detail rows', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            textScaler: TextScaler.linear(2),
          ),
          child: Scaffold(
            body: NebraskaScratchCatalogSheet(
              catalogOverride: jsonDecode(scratchRaw),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.enterText(find.byType(TextField), 'Electric');
    await tester.pumpAndSettle();
    expect(find.text('1 of 24 listed games'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Published structure Winners: 14'),
      200,
      scrollable: find.byType(Scrollable).last,
    );
    expect(tester.takeException(), isNull);
  });
  final raw = File(
    'data/nebraska_draw_collection.generated.json',
  ).readAsStringSync();
  Map<String, dynamic> data() => jsonDecode(raw);
  test(
    'reviewed complete collection decodes',
    () => NebraskaCollectionValidator.decode(raw),
  );
  test(
    'reject changed rules, count units, domains, dates and incomplete groups',
    () {
      final mutations = <void Function(Map)>[
        (d) => d['results'].removeLast(),
        (d) => d['results'][0]['fields'][0]['values'][0] = 100,
        (d) => d['results'][0]['drawDate'] = '2026-02-30',
        (d) =>
            d['familyReports'][0]['reports'][0]['tiers'][0]['sourceWinners'] =
                -1,
        (d) => d['familyReports'][0]['geographicUnit'] = 'US',
        (d) => d['familyReports'][0]['ruleBlocks'].removeLast(),
        (d) => d['familyReports'][0]['reports'][0]['drawDate'] = '2026-10-01',
      ];
      for (final mutate in mutations) {
        final d = data();
        mutate(d);
        expect(
          () => NebraskaCollectionValidator.decode(jsonEncode(d)),
          throwsFormatException,
        );
      }
    },
  );
  test('request failure preserves baseline and does not write', () async {
    var writes = 0;
    final d = await NebraskaCollectionLoader(
      readCache: () async => raw,
      fetchRemote: () async => throw Exception('offline'),
      writeCache: (_) async {
        writes++;
      },
    ).load();
    expect(d, data());
    expect(writes, 0);
  });
  test('new valid retrieval adopted despite persistence failure', () async {
    final d = data();
    d['retrievedAt'] = DateTime.parse(
      d['retrievedAt'],
    ).add(const Duration(minutes: 1)).toIso8601String();
    final result = await NebraskaCollectionLoader(
      readCache: () async => raw,
      fetchRemote: () async => jsonEncode(d),
      writeCache: (_) async => throw Exception('storage'),
    ).load();
    expect(result, d);
  });
  for (var i = 0; i < 22; i++) {
    testWidgets('selection $i renders with enlarged text', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(390, 844),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: NebraskaDrawCollectionSheet(
                reportsOverride: data(),
                initialIndex: i,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('Nebraska results and schedules'), findsOneWidget);
      expect(tester.takeException(), isNull);
      if (i.isOdd) {
        await tester.scrollUntilVisible(
          find.textContaining('No dated prize report retained'),
          200,
          scrollable: find.byType(Scrollable).last,
        );
        expect(
          find.textContaining('No dated prize report retained'),
          findsOneWidget,
        );
      }
    });
  }
}
