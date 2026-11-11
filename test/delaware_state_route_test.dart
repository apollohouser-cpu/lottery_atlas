import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/screens/state/state_lottery_source_screen.dart';
import 'package:lottery_atlas/services/state_lottery_source_registry.dart';

void main() {
  testWidgets(
    'ordinary Delaware routes use released fallback and retain source screen',
    (tester) async {
      await tester.runAsync(
        () => rootBundle.loadString('data/delaware_coverage.generated.json'),
      );
      await tester.pumpWidget(
        MaterialApp(
          home: StateLotterySourceScreen(
            source: StateLotterySourceRegistry.forState('Delaware')!,
          ),
        ),
      );
      for (final products in [false, true]) {
        await tester.runAsync(() async {
          await tester.tap(
            find.text(
              products
                  ? 'Delaware instant games and notices'
                  : 'Delaware results and schedules',
            ),
          );
          await tester.pump();
          await Future<void>.delayed(const Duration(milliseconds: 200));
        });
        await tester.pumpAndSettle();
        expect(
          find.text(products ? 'Delaware Instant Games' : 'Delaware Drawings'),
          findsOneWidget,
        );
        expect(find.textContaining('Refresh unavailable.'), findsOneWidget);
        await tester.pageBack();
        await tester.pumpAndSettle();
        expect(find.text('Delaware results and schedules'), findsOneWidget);
      }
      expect(tester.takeException(), isNull);
    },
  );
}
