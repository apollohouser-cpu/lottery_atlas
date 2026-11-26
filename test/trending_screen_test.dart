import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/map_ranking_service.dart';
import 'package:lottery_atlas/screens/trending/trending_screen.dart';
import 'package:lottery_atlas/widgets/navigation/bottom_nav.dart';
import 'services/trending_service_test.dart' as fixtures;

void main() {
  testWidgets(
    'Trending route uses map scope, switches categories and updates',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      MapRankingService.snapshot.value = fixtures.snapshot([
        fixtures.record('SC', 1, 2),
        fixtures.record('SC', 2, 2),
      ], end: 2);
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(bottomNavigationBar: BottomNav())),
      );
      expect(find.text('Stats'), findsNothing);
      await tester.tap(find.text('Trending'));
      await tester.pumpAndSettle();
      expect(find.byType(TrendingScreen), findsOneWidget);
      expect(find.text('Top 5 in 2 of 2 windows'), findsOneWidget);
      for (final category in [
        'Counties',
        'Cities',
        'Games',
        'Retailers',
        'States',
      ]) {
        await tester.tap(find.text(category));
        await tester.pumpAndSettle();
        expect(find.text('Top 5 in 2 of 2 windows'), findsOneWidget);
        expect(tester.takeException(), isNull);
      }
      MapRankingService.snapshot.value = fixtures.snapshot([], end: 2);
      await tester.pumpAndSettle();
      expect(find.textContaining('Not enough repeated'), findsOneWidget);
      await tester.pageBack();
      await tester.pumpAndSettle();
      expect(find.byType(TrendingScreen), findsNothing);
    },
  );
  testWidgets('large text and landscape remain scrollable', (tester) async {
    tester.view.physicalSize = const Size(844, 390);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    MapRankingService.snapshot.value = fixtures.snapshot([
      fixtures.record('SC', 1, 2),
      fixtures.record('SC', 2, 2),
    ], end: 2);
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: const TrendingScreen(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.drag(find.byType(ListView), const Offset(0, -1500));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Based on available published'), findsOneWidget);
  });
}
