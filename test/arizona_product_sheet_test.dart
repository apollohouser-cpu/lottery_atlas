import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/arizona_product_sheet.dart';

void main() {
  final data =
      jsonDecode(
            File(
              'test/fixtures/arizona_coverage_candidate.json',
            ).readAsStringSync(),
          )
          as Map<String, dynamic>;
  testWidgets('search no-match/reset and symbol source link', (tester) async {
    Uri? opened;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ArizonaProductSheet(
            coverage: data,
            openSource: (uri) async {
              opened = uri;
              return true;
            },
          ),
        ),
      ),
    );
    await tester.enterText(find.byType(TextField), 'no-such-game');
    await tester.pumpAndSettle();
    expect(find.textContaining('No matching games'), findsOneWidget);
    await tester.tap(find.byTooltip('Clear product search'));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), '1401');
    await tester.pumpAndSettle();
    await tester.tap(find.text('SET FOR LIFE #1401'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Official product source'));
    await tester.pumpAndSettle();
    expect(
      opened.toString(),
      'https://www.arizonalottery.com/scratchers/1401-set-for-life/',
    );
    final explanation = find.textContaining('Bracketed symbol descriptions');
    await tester.scrollUntilVisible(
      explanation,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(explanation.hitTestable(), findsOneWidget);
    final source = find.text('Official game and illustrated instructions');
    await tester.scrollUntilVisible(
      source,
      300,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
    );
    expect(find.textContaining('[symbol: LIFE]'), findsOneWidget);
    await tester.tap(source);
    await tester.pumpAndSettle();
    expect(
      opened.toString(),
      'https://www.arizonalottery.com/scratchers/1401-set-for-life/',
    );
    await tester.tap(find.byTooltip('Close product details'));
    await tester.pumpAndSettle();
    expect(find.text('Arizona instant games'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'Fast Play ended product remains readable at enlarged phone text',
    (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(body: ArizonaProductSheet(coverage: data)),
        ),
      );
      await tester.tap(find.text('Scratchers').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fast Play').last);
      await tester.pumpAndSettle();
      await tester.enterText(find.byType(TextField), '203');
      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('HAUNTED CASH #203'),
        200,
        scrollable: find
            .descendant(
              of: find.byType(ListView).last,
              matching: find.byType(Scrollable),
            )
            .first,
      );
      expect(find.text('Ended game'), findsOneWidget);
      await tester.tap(find.text('HAUNTED CASH #203'));
      await tester.pumpAndSettle();
      expect(find.byTooltip('Close product details'), findsOneWidget);
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets('switching catalog returns to top and resets ending expansion', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: ArizonaProductSheet(coverage: data)),
      ),
    );
    await tester.scrollUntilVisible(
      find.text('Ending notices'),
      600,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 60,
    );
    await tester.tap(find.text('Ending notices'));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.text('Scratchers'),
      -600,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 60,
    );
    await tester.tap(find.text('Scratchers').last);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Fast Play').last);
    await tester.pumpAndSettle();
    final first = (data['products']['fast-play'][0]['header'] as String)
        .split('\n')
        .first;
    expect(find.text(first).hitTestable(), findsOneWidget);
    await tester.scrollUntilVisible(
      find.text('Ending notices'),
      600,
      scrollable: find
          .descendant(
            of: find.byType(ListView).last,
            matching: find.byType(Scrollable),
          )
          .first,
      maxScrolls: 40,
    );
    expect(find.textContaining('No adjusted claim deadline'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
