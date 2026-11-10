import 'dart:io';
import 'package:flutter/material.dart';
import 'package:lottery_atlas/services/arizona_coverage_loader.dart';
import 'package:lottery_atlas/widgets/map/arizona_coverage_view.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/delaware_coverage_loader.dart';
import 'package:lottery_atlas/widgets/map/delaware_coverage_view.dart';

void main() {
  final raw = File('data/delaware_coverage.candidate.json').readAsStringSync();
  testWidgets('Arizona retry does not return Future from setState', (
    tester,
  ) async {
    var available = false;
    final released = File(
      'data/arizona_coverage.generated.json',
    ).readAsStringSync();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArizonaCoverageView(
            products: true,
            loader: ArizonaCoverageLoader(
              releaseOnly: true,
              readBundle: () async => available ? released : '{}',
              readCache: () async => null,
              fetchRemote: () async => '{}',
              writeCache: (_) async {},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsOneWidget);
    available = true;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Retry'), findsNothing);
    expect(tester.takeException(), isNull);
  });
  testWidgets('failed refresh shows retained draws and notice', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DelawareCoverageView(
            loader: DelawareCoverageLoader(
              readBundle: () async => raw,
              readCache: () async => null,
              fetchRemote: () async => '{}',
              writeCache: (_) async => fail('invalid refresh must not persist'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Delaware Drawings'), findsOneWidget);
    expect(find.textContaining('Refresh unavailable.'), findsOneWidget);
    expect(find.text('Powerball: 15'), findsOneWidget);
  });
  testWidgets('unavailable data offers retry and recovers product view', (
    tester,
  ) async {
    var available = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: DelawareCoverageView(
            products: true,
            loader: DelawareCoverageLoader(
              readBundle: () async => available ? raw : '{}',
              readCache: () async => null,
              fetchRemote: () async => '{}',
              writeCache: (_) async => fail('invalid refresh must not persist'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('No validated saved data'), findsOneWidget);
    available = true;
    await tester.tap(find.text('Retry'));
    await tester.pumpAndSettle();
    expect(find.text('Delaware Instant Games'), findsOneWidget);
    expect(find.textContaining('No validated saved data'), findsNothing);
  });
}
