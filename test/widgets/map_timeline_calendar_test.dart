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
}
