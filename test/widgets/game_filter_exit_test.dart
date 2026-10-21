import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/map_controls_overlay.dart';

void main() {
  testWidgets('Phone filter has visible cancel and apply without scrolling', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    var applied = 0;
    await tester.pumpWidget(
      MaterialApp(
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(
            context,
          ).copyWith(textScaler: const TextScaler.linear(2)),
          child: child!,
        ),
        home: Scaffold(
          body: MapControlsOverlay(onFilterChanged: (_) => applied++),
        ),
      ),
    );
    Future<void> open() async {
      await tester.tap(find.byTooltip('Map menu'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Game filter'));
      await tester.pumpAndSettle();
    }

    await open();
    expect(find.byTooltip('Close game filter').hitTestable(), findsOneWidget);
    expect(find.text('Apply Game Filter').hitTestable(), findsOneWidget);
    await tester.tap(find.byTooltip('Close game filter'));
    await tester.pumpAndSettle();
    expect(applied, 0);
    expect(find.text('Apply Game Filter'), findsNothing);
    await open();
    await tester.tap(find.text('Apply Game Filter'));
    await tester.pumpAndSettle();
    expect(applied, 1);
    expect(find.text('Apply Game Filter'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
