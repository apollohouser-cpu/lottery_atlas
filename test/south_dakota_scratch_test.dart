import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import '../lib/services/south_dakota_scratch_catalog_loader.dart';
import '../lib/widgets/map/south_dakota_scratch_catalog_sheet.dart';

void main() {
  final raw = File(
    'data/south_dakota_scratch_catalog.generated.json',
  ).readAsStringSync();
  Map<String, dynamic> fresh() => jsonDecode(raw);
  test('full subset validates; arithmetic, identity and units fail closed', () {
    final d = SouthDakotaScratchCatalogLoader.decode(raw);
    expect(d['catalogs'][0]['games'].length, 35);
    for (final mutation in <void Function(Map<String, dynamic>)>[
      (d) => d['catalogs'][0]['games'][0]['prizeTiers'][0]['paidTickets'] = -1,
      (d) => d['catalogs'][0]['games'][0]['prizeTiers'][0]['remaining'] = 1,
      (d) =>
          d['catalogs'][0]['games'][0]['prizeTiers'][0]['winningTickets'] = 1.5,
      (d) => d['catalogs'][0]['games'][0]['sourceUrl'] =
          'https://example.com/game/test/',
      (d) => d['catalogs'][0]['sourceDate'] = '2026-10-18',
    ]) {
      final bad = fresh();
      mutation(bad);
      expect(
        () => SouthDakotaScratchCatalogLoader.decode(jsonEncode(bad)),
        throwsA(anything),
      );
    }
  });
  test(
    'changed original inventory rejected; request failure retains exact cache',
    () async {
      final old = SouthDakotaScratchCatalogLoader.decode(raw);
      final next = fresh();
      next['catalogs'][0]['games'][0]['prizeTiers'][0]['winningTickets'] += 1;
      expect(
        () => SouthDakotaScratchCatalogLoader.continuity(old, next),
        throwsA(anything),
      );
      var writes = 0;
      final result = await SouthDakotaScratchCatalogLoader(
        readCache: () async => raw,
        fetchRemote: () async => throw const SocketException('injected'),
        writeCache: (_) async {
          writes++;
        },
      ).load();
      expect(result, old);
      expect(writes, 0);
    },
  );
  testWidgets(
    'enlarged text search, empty result and reset preserve inventory',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: MediaQuery(
            data: const MediaQueryData(
              size: Size(430, 932),
              textScaler: TextScaler.linear(2),
            ),
            child: Scaffold(
              body: SouthDakotaScratchCatalogSheet(catalogOverride: fresh()),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('35 of 35 listed games'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'doesnotexist');
      await tester.pumpAndSettle();
      expect(find.text('No matching games.'), findsOneWidget);
      await tester.tap(find.text('Reset filters'));
      await tester.pumpAndSettle();
      expect(find.text('35 of 35 listed games'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
