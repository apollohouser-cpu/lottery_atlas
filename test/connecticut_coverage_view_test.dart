import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/connecticut_coverage_loader.dart';
import 'package:lottery_atlas/widgets/map/connecticut_coverage_view.dart';

void main() {
  final raw = jsonEncode({
    'stateCode': 'CT',
    'schemaVersion': 1,
    'productionReady': true,
    'recordType': 'supported-coverage',
    'draws': [],
    'scratchCatalog': {
      'coverage': 'Synthetic catalog fixture',
      'games': [
        {'id': '1725', 'name': 'Excluded fixture'},
        {
          'id': '100',
          'name': 'Synthetic game',
          'sourceDate': '2026-11-21',
          'status': 'ended',
          'cost': 1,
          'startDate': '2025-01-01',
          'topPrize': 10,
          'inventoryNote': 'Synthetic inventory',
          'prizeTiers': [],
          'sourceUrl': 'https://ctlottery.com/games/scratch-games/100',
        },
      ],
    },
  });
  ConnecticutCoverageLoader loader({bool valid = true}) =>
      ConnecticutCoverageLoader(
        reviewedSha256: sha256.convert(utf8.encode(raw)).toString(),
        readBundle: () async => valid ? raw : '{}',
        readCache: () async => null,
        writeCache: (_) async => fail('Offline load cannot overwrite cache'),
        fetchRemote: () async => throw StateError('offline'),
      );
  testWidgets(
    'offline catalog reaches detail and returns without excluded game',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConnecticutCoverageView(loader: loader(), scratch: true),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('Refresh unavailable.'), findsOneWidget);
      expect(find.text('Excluded fixture'), findsNothing);
      await tester.tap(find.text('Synthetic game · 100'));
      await tester.pumpAndSettle();
      expect(find.text('Source inventory date: 2026-11-21'), findsOneWidget);
      expect(find.text('Sales ended'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.text('Synthetic game · 100'), findsOneWidget);
    },
  );
  testWidgets(
    'no valid data exposes retry rather than empty successful coverage',
    (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ConnecticutCoverageView(loader: loader(valid: false)),
        ),
      );
      await tester.pumpAndSettle();
      expect(
        find.textContaining('No reviewed saved data was found.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsOneWidget);
      expect(find.text('Close'), findsOneWidget);
    },
  );
}
