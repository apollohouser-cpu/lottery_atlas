import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:lottery_atlas/widgets/map/arizona_rule_schedule.dart';

void main() {
  final rules =
      jsonDecode(
            File(
              'test/fixtures/arizona_coverage_candidate.json',
            ).readAsStringSync(),
          )['rules']
          as Map;
  test('matching symbols retain ordinary and special ball distinctions', () {
    for (final game in ['powerball', 'mega-millions']) {
      final lines = ArizonaRuleSchedule.tableLines(
        rules[game]['tables'][0],
        game,
      );
      expect(lines[1], contains('5 matching white numbers + 1'));
      expect(lines[2], contains('5 matching white numbers + 0'));
      expect(lines[1], contains('Jackpot*'));
    }
    expect(
      ArizonaRuleSchedule.tableLines(
        rules['fantasy-5']['tables'][0],
        'fantasy-5',
      )[1],
      startsWith('5 matching numbers'),
    );
    expect(
      () => ArizonaRuleSchedule.cellText('', ['unreviewed'], 'powerball'),
      throwsFormatException,
    );
  });
  test('all sixteen rule families and nested schedules retain cells', () {
    expect(rules.length, 16);
    for (final entry in rules.entries) {
      for (final table in entry.value['tables']) {
        expect(
          ArizonaRuleSchedule.tableLines(table, entry.key).length,
          table['rows'].length,
        );
        for (final nested in table['nestedTables'] ?? []) {
          expect(
            ArizonaRuleSchedule.tableLines(nested, entry.key).length,
            nested['rows'].length,
          );
        }
      }
    }
    final nested = rules['51045']['tables'][0]['nestedTables'] as List;
    expect(nested.length, greaterThan(1));
  });
  testWidgets('all rule schedules render with enlarged phone text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    for (final entry in rules.entries) {
      await tester.pumpWidget(
        MaterialApp(
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(
              context,
            ).copyWith(textScaler: const TextScaler.linear(2)),
            child: child!,
          ),
          home: Scaffold(
            body: SingleChildScrollView(
              child: ArizonaRuleSchedule(
                key: ValueKey(entry.key),
                rule: entry.value,
              ),
            ),
          ),
        ),
      );
      await tester.pump();
      expect(tester.takeException(), isNull, reason: entry.key);
    }
  });
}
