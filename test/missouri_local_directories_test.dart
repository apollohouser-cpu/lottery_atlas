import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/missouri_local_directories_loader.dart';
import 'package:lottery_atlas/widgets/map/missouri_local_directories_sheet.dart';

void main() {
  final raw = File(
    'data/missouri_local_directories.generated.json',
  ).readAsStringSync();
  test('local query identity and unknown coordinates guarded', () {
    final d = MissouriLocalDirectoriesLoader.decode(raw);
    expect(d['queries'][0]['retailers'].length, 66);
    expect(d['queries'][1]['retailers'].length, 85);
    for (final field in ['city', 'latitude', 'products']) {
      final bad = jsonDecode(raw), r = bad['queries'][0]['retailers'][0];
      r[field] = field == 'city'
          ? 'Other'
          : field == 'latitude'
          ? 38.5
          : ['Unknown'];
      expect(
        () => MissouriLocalDirectoriesLoader.decode(jsonEncode(bad)),
        throwsFormatException,
      );
    }
  });
  for (final size in [const Size(390, 844), const Size(1400, 1000)]) {
    testWidgets('bounded directory filters and city switch at $size', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MissouriLocalDirectoriesSheet(
              dataOverride: MissouriLocalDirectoriesLoader.decode(raw),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.textContaining('66 of 66'), findsOneWidget);
      expect(find.textContaining('Coordinates unavailable'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'xyz no match');
      await tester.pumpAndSettle();
      expect(find.text('No matching local records.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), '');
      await tester.tap(find.byType(DropdownButton<int>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Columbia').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('85 of 85'), findsOneWidget);
      await tester.tap(find.byType(DropdownButton<String>));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Club Keno').last);
      await tester.pumpAndSettle();
      expect(find.textContaining('85 of 85'), findsNothing);
      expect(tester.takeException(), isNull);
    });
  }
}
