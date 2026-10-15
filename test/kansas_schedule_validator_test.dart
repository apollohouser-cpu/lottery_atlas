import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/kansas_schedule_validator.dart';

void main() {
  Map<String, dynamic> schedules() => jsonDecode(
    File('data/kansas_draw_collection.generated.json').readAsStringSync(),
  )['schedules'];
  test('all ten literal schedule families and disclosures validate', () {
    KansasScheduleValidator.validate(schedules());
  });
  test('updated literal prize amount can pass without converting units', () {
    final s = schedules();
    s['powerball']['tables'][0]['rows'][0][1] = r'$$600,000,000';
    KansasScheduleValidator.validate(s);
  });
  test('missing or changed schedule structure and qualifications reject', () {
    final changes = <void Function(Map)>[
      (s) => s.remove('keno'),
      (s) => s['keno']['tables'].removeLast(),
      (s) => s['keno']['tables'][0]['title'] = 'Other spot count',
      (s) => s['keno']['tables'][0]['columns'][2] = 'match',
      (s) => s['keno']['tables'][0]['rows'][0][1] = '',
      (s) => s['keno']['qualifications'] = [],
      (s) => s['keno']['sourceWarnings'] = [],
      (s) => s['racetrax']['tables'][0]['prizeInformationCards'][0]['pdfHref'] =
          'https://example.com',
      (s) => s['racetrax']['tables'][0]['prizeInformationFooter'] = '',
      (s) => s['pick-3']['rules'] = [],
      (s) => s['pick-3']['sourceWarnings'] = [],
      (s) => s['powerball']['tables'][0]['rows'][0][1] = r'$$unknown',
      (s) => s['powerball']['tables'][0]['rows'][0].removeLast(),
      (s) => s['powerball']['coverage'] = 'Actual winners',
    ];
    for (final change in changes) {
      final s = schedules();
      change(s);
      expect(() => KansasScheduleValidator.validate(s), throwsFormatException);
    }
  });
}
