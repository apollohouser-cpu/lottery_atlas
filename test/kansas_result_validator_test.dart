import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/kansas_result_validator.dart';

void main() {
  Map<String, dynamic> source() => jsonDecode(
    File('data/kansas_draw_collection.generated.json').readAsStringSync(),
  );
  test('all twelve groups preserve source order and local dates', () {
    final s = source();
    KansasResultValidator.validate(
      s['reports'],
      DateTime.parse(s['retrievedAt']),
    );
  });
  test('malformed result identity, numbers, units and provenance reject', () {
    final changes = <void Function(Map)>[
      (s) => s['reports'].removeLast(),
      (s) => s['reports'][0]['family'] = 'Other',
      (s) => s['reports'][0]['sourceDrawTimestamp'] = '2026-02-30T01:00:00Z',
      (s) => s['reports'][0]['drawDate'] = '2026-10-01',
      (s) => s['reports'][0]['sourceWarnings'] = [],
      (s) => s['reports'][0]['numbers'][0] = '99',
      (s) => s['reports'][0]['sourceNumberOrder'][0]['type'] = 'SPECIAL',
      (s) => s['reports'][0]['shareCount'] = 0,
      (s) => s['reports'][0]['sourceUrl'] = 'https://example.com',
      (s) => s['reports'][0]['scheduleKey'] = 'other',
      (s) => s['reports'][0]['coverage'] = 'All winners',
      (s) => s['reports'][0]['multiplier'] = 10,
      (s) => s['reports'][0]['teams'] = ['FAKE'],
    ];
    for (final change in changes) {
      final s = source();
      change(s);
      expect(
        () => KansasResultValidator.validate(
          s['reports'],
          DateTime.parse(s['retrievedAt']),
        ),
        throwsFormatException,
      );
    }
  });
}
