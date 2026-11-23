import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/connecticut_coverage_limits.dart';

void main() {
  testWidgets(
    'limited Fast Play and excluded inventory stay explicit; source errors retain page',
    (tester) async {
      Uri? opened;
      await tester.pumpWidget(
        MaterialApp(
          home: ConnecticutCoverageLimits(
            openSource: (uri) async {
              opened = uri;
              return false;
            },
          ),
        ),
      );
      expect(
        find.textContaining('Missing records do not mean zero winners.'),
        findsOneWidget,
      );
      expect(
        find.textContaining('Scratch game 1725 is excluded'),
        findsOneWidget,
      );
      await tester.scrollUntilVisible(
        find.text('Official rules index — including Fast Play'),
        250,
      );
      await tester.tap(find.text('Official rules index — including Fast Play'));
      await tester.pump();
      expect(opened.toString(), 'https://ctlottery.com/lottery-rules');
      expect(find.text('Could not open the official source.'), findsOneWidget);
      expect(
        find.textContaining('current Fast Play game inventory or results'),
        findsOneWidget,
      );
    },
  );
}
