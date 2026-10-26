import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/new_mexico_product_sheet.dart';

void main() {
  final data =
      jsonDecode(
            File('data/new_mexico_coverage.generated.json').readAsStringSync(),
          )
          as Map<String, dynamic>;
  testWidgets(
    'Scratch details and status gaps readable at global 2x in both orientations',
    (tester) async {
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      for (final size in [const Size(390, 844), const Size(844, 390)]) {
        tester.view.physicalSize = size;
        for (final type in ['Scratch', 'Game status']) {
          await tester.pumpWidget(
            MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(
                  context,
                ).copyWith(textScaler: const TextScaler.linear(2)),
                child: child!,
              ),
              home: Scaffold(
                body: NewMexicoProductSheet(
                  key: ValueKey('$size-$type'),
                  coverageOverride: data,
                  initialType: type,
                ),
              ),
            ),
          );
          await tester.pumpAndSettle();
          if (type == 'Game status') {
            await tester.scrollUntilVisible(
              find.text('Official games and promotions'),
              200,
              scrollable: find.byType(Scrollable).last,
              maxScrolls: 80,
            );
            await Scrollable.ensureVisible(
              tester.element(find.text('Official games and promotions')),
              alignment: 0.3,
            );
            await tester.pumpAndSettle();
            expect(
              find.text('Official games and promotions').hitTestable(),
              findsOneWidget,
            );
            expect(find.byType(ListTile), findsNothing);
          } else {
            final game = data['scratch']['games'][0];
            await tester.scrollUntilVisible(
              find.byType(TextField),
              150,
              scrollable: find.byType(Scrollable).last,
            );
            await tester.enterText(find.byType(TextField), game['id']);
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.byType(ListTile),
              200,
              scrollable: find.byType(Scrollable).first,
              maxScrolls: 80,
            );
            await Scrollable.ensureVisible(
              tester.element(find.byType(ListTile).first),
              alignment: 0.3,
            );
            await tester.pumpAndSettle();
            await tester.tap(find.byType(ListTile).first);
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.text('Official ending and claim notices'),
              200,
              scrollable: find.byType(Scrollable).last,
              maxScrolls: 100,
            );
            await Scrollable.ensureVisible(
              tester.element(find.text('Official ending and claim notices')),
              alignment: 0.3,
            );
            await tester.pumpAndSettle();
            expect(
              find.text('Official ending and claim notices').hitTestable(),
              findsOneWidget,
            );
            expect(find.textContaining('null'), findsNothing);
            await tester.tap(find.byTooltip('Close game details'));
            await tester.pumpAndSettle();
            await tester.scrollUntilVisible(
              find.byType(TextField),
              -200,
              scrollable: find.byType(Scrollable).first,
              maxScrolls: 80,
            );
            expect(find.byType(TextField), findsOneWidget);
          }
          expect(tester.takeException(), isNull, reason: '$size $type');
        }
      }
    },
  );
  testWidgets('search empty result and reset preserve estimated catalog', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: NewMexicoProductSheet(coverageOverride: data)),
      ),
    );
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'no such game');
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.textContaining('0 of'),
      100,
      scrollable: find.byType(Scrollable).last,
    );
    expect(find.textContaining('0 of'), findsOneWidget);
    await tester.ensureVisible(find.text('Reset'));
    await tester.tap(find.text('Reset'));
    await tester.pumpAndSettle();
    expect(
      (tester.widget(find.byType(TextField)) as TextField).controller!.text,
      isEmpty,
    );
    expect(
      find.textContaining('${data['scratch']['games'].length} of'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
