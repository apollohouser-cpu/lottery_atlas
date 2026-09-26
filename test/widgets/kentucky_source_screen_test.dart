import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/screens/state/state_lottery_source_screen.dart';
import 'package:lottery_atlas/services/state_lottery_source_registry.dart';

void main() {
  for (final size in [const Size(800, 632), const Size(1280, 900)]) {
    testWidgets(
      'Kentucky source disclosures and links remain reachable at $size',
      (tester) async {
        await tester.binding.setSurfaceSize(size);
        addTearDown(() => tester.binding.setSurfaceSize(null));
        await tester.pumpWidget(
          MaterialApp(
            home: StateLotterySourceScreen(
              source: StateLotterySourceRegistry.forState('Kentucky')!,
            ),
          ),
        );
        await tester.pumpAndSettle();
        final limits = find.textContaining(
          'Missing data does not mean zero wins',
        );
        await tester.ensureVisible(limits);
        expect(limits.hitTestable(), findsOneWidget);
        final cadence = find.textContaining(
          'Agency publication cadence is unconfirmed',
        );
        await tester.ensureVisible(cadence);
        expect(cadence.hitTestable(), findsOneWidget);
        for (final label in [
          'Latest winning numbers',
          'Available Scratch-Off games',
          'Scratch-Off prizes remaining',
          'Lottery Atlas data refresh status',
        ]) {
          final link = find.text(label);
          await tester.scrollUntilVisible(
            link,
            150,
            scrollable: find.byType(Scrollable),
          );
          await tester.pumpAndSettle();
          expect(link.hitTestable(), findsOneWidget, reason: label);
          expect(tester.takeException(), isNull);
        }
      },
    );
  }
}
