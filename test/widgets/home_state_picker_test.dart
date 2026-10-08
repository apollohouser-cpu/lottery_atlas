import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/home_state_picker.dart';

void main() {
  testWidgets(
    'Home setup searches, handles no matches, and returns selected state',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      String? selected;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () async {
                  selected = await showHomeStatePicker(context);
                },
                child: const Text('Home'),
              ),
            ),
          ),
        ),
      );
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      expect(find.text('Choose your home state'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'zzzz');
      await tester.pump();
      expect(find.text('No states match that search.'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'missouri');
      await tester.pump();
      await tester.tap(find.text('Missouri'));
      await tester.pumpAndSettle();
      expect(selected, 'Missouri');
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();
      await tester.tap(find.byTooltip('Close'));
      await tester.pumpAndSettle();
      expect(selected, isNull);
      expect(tester.takeException(), isNull);
    },
  );
}
