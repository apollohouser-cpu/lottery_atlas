import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/screens/state/state_lottery_source_screen.dart';
import 'package:lottery_atlas/services/state_lottery_source_registry.dart';

void main() {
  testWidgets(
    'Arizona development routes honor gate and load reviewed bundle',
    (tester) async {
      await tester.runAsync(
        () => rootBundle.loadString('data/arizona_coverage.candidate.json'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: StateLotterySourceScreen(
            source: StateLotterySourceRegistry.forState('Arizona')!,
          ),
        ),
      );
      const enabled = bool.fromEnvironment('ARIZONA_DEVELOPMENT');
      if (!enabled) {
        expect(find.text('Arizona results and schedules'), findsNothing);
        return;
      }
      await tester.runAsync(() async {
        await tester.tap(find.text('Arizona results and schedules'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      expect(find.text('Arizona draw results'), findsOneWidget);
      expect(find.textContaining('Refresh unavailable.'), findsOneWidget);
      await tester.tap(find.byTooltip('Close Arizona draws'));
      await tester.pumpAndSettle();
      await tester.runAsync(() async {
        await tester.tap(find.text('Arizona instant games and notices'));
        await tester.pump();
        await Future<void>.delayed(const Duration(milliseconds: 200));
      });
      await tester.pumpAndSettle();
      expect(find.text('Arizona instant games'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
}
