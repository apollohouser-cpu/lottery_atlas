import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/map_controls_overlay.dart';
import 'package:lottery_atlas/widgets/map/map_filter_state.dart';

void main() {
  testWidgets('short landscape opens a scrollable working timeline', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(780, 360);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    await tester.binding.setSurfaceSize(const Size(780, 360));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(body: MapControlsOverlay(showHeaderControls: false)),
      ),
    );
    await tester.pump();
    expect(find.text('HEAT INDEX'), findsNothing);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    final year = find.widgetWithText(ChoiceChip, 'Year');
    await tester.ensureVisible(year);
    await tester.tap(year);
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(year).selected, isTrue);
    await tester.ensureVisible(find.byTooltip('Close timeline'));
    await tester.tap(find.byTooltip('Close timeline'));
    await tester.pumpAndSettle();
    expect(find.text('HEAT INDEX'), findsNothing);
    await tester.tap(find.byType(FilledButton));
    await tester.pumpAndSettle();
    expect(tester.widget<ChoiceChip>(year).selected, isTrue);
    expect(tester.takeException(), isNull);
  });

  for (final width in [320.0, 390.0, 900.0]) {
    testWidgets('timeline controls fit width $width and remain usable', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(Size(width, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: MapControlsOverlay(showHeaderControls: false)),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull);
      for (final label in ['Year', 'Month', 'Week', 'Day']) {
        final chip = find.widgetWithText(ChoiceChip, label);
        final rect = tester.getRect(chip);
        expect(rect.left, greaterThanOrEqualTo(0));
        expect(rect.right, lessThanOrEqualTo(width));
        await tester.tap(chip);
        await tester.pump();
        expect(tester.widget<ChoiceChip>(chip).selected, isTrue);
        expect(tester.takeException(), isNull);
      }
      final modeRects = ['Day', 'Week', 'Month', 'Year']
          .map(
            (label) => tester.getRect(find.widgetWithText(ChoiceChip, label)),
          )
          .toList();
      for (final rect in modeRects) {
        expect(rect.top, modeRects.first.top);
        expect(rect.width, closeTo(modeRects.first.width, 0.01));
      }
      expect(find.text('HEAT INDEX'), findsOneWidget);
      expect(find.text('Low'), findsOneWidget);
      expect(find.text('High'), findsOneWidget);
    });
  }
  testWidgets('timeline exposes calendar-correct scales', (tester) async {
    MapFilterState? selectedFilter;
    final now = DateTime.now();
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapControlsOverlay(
            filterState: MapFilterState(
              dateRange: DateTimeRange(
                start: DateTime(now.year, now.month, now.day),
                end: now,
              ),
            ),
            onFilterChanged: (filter) => selectedFilter = filter,
          ),
        ),
      ),
    );

    await tester.tap(find.text('Year'));
    await tester.pump();
    expect(find.text('Week 1'), findsOneWidget);
    expect(find.text('Week 52'), findsOneWidget);
    expect(find.textContaining('Now showing: Week '), findsOneWidget);
    expect(
      selectedFilter!.dateRange.end.difference(selectedFilter!.dateRange.start),
      lessThanOrEqualTo(const Duration(days: 7)),
    );

    await tester.tap(find.text('Month'));
    await tester.pump();
    expect(
      find.text('${DateTime(now.year, now.month + 1, 0).day}'),
      findsWidgets,
    );

    await tester.tap(find.text('Week'));
    await tester.pump();
    for (final weekday in const <String>[
      'Mon',
      'Tue',
      'Wed',
      'Thu',
      'Fri',
      'Sat',
      'Sun',
    ]) {
      expect(find.text(weekday), findsOneWidget);
    }

    await tester.tap(find.text('Day'));
    await tester.pump();
    expect(find.text('12 AM'), findsOneWidget);
    expect(find.text('12 PM'), findsOneWidget);
    expect(find.text('11 PM'), findsOneWidget);
  });
  testWidgets('date-only source switches hourly selection to whole day', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    MapFilterState? emitted;
    final filter = MapFilterState(
      dateRange: DateTimeRange(
        start: DateTime(2026, 8, 14, 6),
        end: DateTime(2026, 8, 14, 6, 59, 59),
      ),
    );
    Widget screen(bool dayOnly) => MaterialApp(
      home: Scaffold(
        body: MapControlsOverlay(
          dayOnlyActivity: dayOnly,
          filterState: filter,
          onFilterChanged: (value) => emitted = value,
        ),
      ),
    );
    await tester.pumpWidget(screen(false));
    expect(find.text('Day'), findsOneWidget);
    await tester.pumpWidget(screen(true));
    await tester.pump();
    expect(find.text('Day'), findsNothing);
    expect(
      find.textContaining('Claim dates only; times unavailable'),
      findsOneWidget,
    );
    expect(emitted!.dateRange.start, DateTime(2026, 8, 14));
    expect(emitted!.dateRange.end.day, 14);
    expect(emitted!.dateRange.end.hour, 23);
    expect(emitted!.dateRange.end.minute, 59);
    await tester.pumpWidget(screen(false));
    await tester.pump();
    expect(find.text('Day'), findsOneWidget);
  });

  testWidgets('published-date initial timeline emits a whole-day range', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(900, 1000));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    MapFilterState? emitted;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: MapControlsOverlay(
            dayOnlyActivity: true,
            dayOnlyDateLabel: 'Published dates',
            filterState: MapFilterState(
              dateRange: DateTimeRange(
                start: DateTime(2026, 8, 14, 18),
                end: DateTime(2026, 8, 14, 18, 59),
              ),
            ),
            onFilterChanged: (value) => emitted = value,
          ),
        ),
      ),
    );
    await tester.pump();
    expect(emitted!.dateRange.start, DateTime(2026, 8, 14));
    expect(emitted!.dateRange.end.hour, 23);
    expect(
      find.textContaining('Published dates only; times unavailable'),
      findsOneWidget,
    );
    expect(find.text('Day'), findsNothing);
  });
  testWidgets(
    'Kentucky published notice remains in whole-day selection at compact size',
    (tester) async {
      final data = jsonDecode(
        File(
          'data/kentucky_current_winner_activity.generated.json',
        ).readAsStringSync(),
      );
      final record = (data['activities'] as List).first;
      final date = DateTime.parse(record['drawDate'] as String).toLocal();
      final day = DateTime(date.year, date.month, date.day);
      await tester.binding.setSurfaceSize(const Size(800, 632));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      MapFilterState? emitted;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MapControlsOverlay(
              dayOnlyActivity: true,
              dayOnlyDateLabel: 'Published dates',
              filterState: MapFilterState(
                dateRange: DateTimeRange(
                  start: day.add(const Duration(hours: 18)),
                  end: day.add(const Duration(hours: 19)),
                ),
              ),
              onFilterChanged: (value) => emitted = value,
            ),
          ),
        ),
      );
      await tester.pump();
      expect(emitted, isNotNull);
      expect(date.isBefore(emitted!.dateRange.start), isFalse);
      expect(date.isAfter(emitted!.dateRange.end), isFalse);
      expect(find.text('Day'), findsNothing);
      expect(
        find.textContaining('Published dates only; times unavailable'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Month'));
      await tester.pump();
      expect(tester.takeException(), isNull);
      await tester.tap(find.text('Week'));
      await tester.pump();
      expect(
        find.textContaining('Published dates only; times unavailable'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );
}
