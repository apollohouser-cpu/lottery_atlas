import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/map_controls_overlay.dart';
import 'package:lottery_atlas/widgets/map/map_filter_state.dart';

void main() {
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

  testWidgets('date-only initial timeline emits a whole-day range', (
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
    expect(find.text('Day'), findsNothing);
  });
}
