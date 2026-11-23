import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/widgets/map/connecticut_draw_collection_sheet.dart';

void main() {
  Map<String, dynamic> row(String game, {String? session}) => {
    'game': game,
    if (session != null) 'session': session,
    'drawDate': '2026-11-22',
    'numbers': [0, 0, 7],
    'sourceUrl': 'https://ctlottery.com/games/draw-games/play3',
  };
  Future<void> show(
    WidgetTester tester,
    List<Map> rows, {
    Future<bool> Function(Uri)? open,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ConnecticutDrawCollectionSheet(
          coverage: {'draws': rows},
          openSource: open,
        ),
      ),
    );
  }

  testWidgets(
    'digit sessions remain distinct with leading zero and Wild Ball',
    (tester) async {
      await show(tester, [
        {
          ...row('play3', session: 'Day'),
          'special': {'label': 'Wild Ball', 'number': 4},
        },
        {
          ...row('play3', session: 'Night'),
          'numbers': [9, 8, 7],
        },
      ]);
      expect(find.text('Numbers: 0 · 0 · 7'), findsOneWidget);
      expect(find.text('Wild Ball: 4'), findsOneWidget);
      await tester.tap(find.text('Play3 · Night'));
      await tester.pump();
      expect(find.text('Numbers: 9 · 8 · 7'), findsOneWidget);
      expect(find.text('Wild Ball: 4'), findsNothing);
    },
  );
  testWidgets('Double Play does not inherit Power Play', (tester) async {
    await show(tester, [
      {...row('powerball'), 'powerPlay': 2},
      row('doubleplay'),
    ]);
    expect(find.text('Power Play: 2X'), findsOneWidget);
    await tester.tap(find.text('Double Play'));
    await tester.pump();
    expect(find.text('Power Play: 2X'), findsNothing);
  });
  testWidgets('failed source launch leaves dated content visible', (
    tester,
  ) async {
    Uri? opened;
    await show(
      tester,
      [row('play3')],
      open: (uri) async {
        opened = uri;
        return false;
      },
    );
    await tester.tap(find.text('Official result source'));
    await tester.pump();
    expect(opened?.host, 'ctlottery.com');
    expect(find.text('Could not open the official source.'), findsOneWidget);
    expect(find.text('Draw date: 2026-11-22'), findsOneWidget);
  });
  testWidgets('Xs and Os shows reviewed team names instead of numeric IDs', (
    tester,
  ) async {
    await show(tester, [
      {
        ...row('xsandos'),
        'teams': ['Reviewed team label'],
      },
    ]);
    expect(find.text('Reviewed team label'), findsOneWidget);
    expect(find.text('Numbers: 0 · 0 · 7'), findsNothing);
  });
  testWidgets('Keno supplies game number and no invented draw time', (
    tester,
  ) async {
    await show(tester, [
      {...row('keno'), 'gameNumber': '123', 'bonus': '2X'},
    ]);
    expect(find.text('Game number: 123'), findsOneWidget);
    expect(find.text('Bonus: 2X'), findsOneWidget);
    expect(find.textContaining('not a verified draw time'), findsOneWidget);
  });
}
