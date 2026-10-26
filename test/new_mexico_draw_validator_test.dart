import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/new_mexico_draw_validator.dart';

void main() {
  Map<String, dynamic> fixture() => jsonDecode(
    File('data/new_mexico_coverage.generated.json').readAsStringSync(),
  );
  void check(Map d) => NewMexicoDrawValidator.validate(
    d['results'],
    d['queryWindow'],
    DateTime.parse(d['updatedAt']),
  );
  test('all nine groups and exact query identities validate', () {
    final d = fixture();
    check(d);
    expect(
      NewMexicoDrawValidator.validate(
        d['results'],
        d['queryWindow'],
        DateTime.parse(d['updatedAt']),
      ),
      hasLength(9),
    );
  });
  test('leading zeroes and repeated Pick digits preserved', () {
    final d = fixture();
    final r = (d['results'] as List).firstWhere(
      (r) => r['game'] == 'pick3plus',
    );
    r['numbers'] = ['0', '0', '1'];
    check(d);
    expect(r['numbers'], ['0', '0', '1']);
  });
  test('session variant range duplicate and multiplier mutations rejected', () {
    final changes = <void Function(Map)>[
      (d) => d['results'][0]['session'] = 'DAY',
      (d) => d['results'][0]['variant'] = 'invented',
      (d) => d['results'][0]['numbers'] = ['1', '1', '2', '3', '4'],
      (d) => d['results'][0]['specialBall'] = 99,
      (d) => d['results'][0]['multiplier'] = 7,
      (d) => (d['results'] as List).firstWhere(
        (r) => r['game'] == 'megamillions',
      )['multiplier'] = 2,
      (d) => (d['results'] as List).firstWhere(
        (r) => r['game'] == 'pick3plus',
      )['numbers'] = ['00', '1', '2'],
      (d) => d['results'][0]['sourceUrl'] = 'https://example.com',
      (d) => d['results'][0]['date'] = '2026-02-30',
      (d) => d['results'][0]['date'] = '2026-10-27',
      (d) => d['results'].removeLast(),
      (d) => d['results'].add(d['results'][0]),
      (d) => d['queryWindow']['timezone'] = 'UTC',
      (d) => d['queryWindow']['start'] = '2026-10-11',
    ];
    for (final change in changes) {
      final d = fixture();
      change(d);
      expect(() => check(d), throwsFormatException);
    }
  });
  test('Denver local day rejects future query even across UTC midnight', () {
    final d = fixture();
    expect(
      () => NewMexicoDrawValidator.validate(
        d['results'],
        d['queryWindow'],
        DateTime.parse('2026-10-26T01:00:00Z'),
      ),
      throwsFormatException,
    );
  });
  test('new completed Pick date advances without correcting overlap', () {
    final old = fixture(), next = fixture();
    final rows =
        (next['results'] as List)
            .where((r) => r['game'] == 'pick3plus' && r['session'] == 'DAY')
            .toList()
          ..sort((a, b) => (a['date'] as String).compareTo(b['date']));
    rows.first['date'] = '2026-10-26';
    rows.first['numbers'] = ['0', '1', '2'];
    NewMexicoDrawValidator.continuity(
      old['results'],
      old['queryWindow'],
      next['results'],
      next['queryWindow'],
      DateTime.parse(next['updatedAt']),
    );
    rows.last['numbers'] = ['9', '9', '9'];
    expect(
      () => NewMexicoDrawValidator.continuity(
        old['results'],
        old['queryWindow'],
        next['results'],
        next['queryWindow'],
        DateTime.parse(next['updatedAt']),
      ),
      throwsFormatException,
    );
  });
  test('window regressions and DP date mismatch rejected', () {
    final old = fixture(), next = fixture();
    final row = (next['results'] as List).firstWhere(
      (r) => r['variant'] == 'double_play',
    );
    row['date'] = '2026-10-22';
    expect(() => check(next), throwsFormatException);
    final reg = fixture();
    final pick =
        (reg['results'] as List)
            .where((r) => r['game'] == 'pick3plus' && r['session'] == 'DAY')
            .toList()
          ..sort((a, b) => (a['date'] as String).compareTo(b['date']));
    pick.first['date'] = '2026-10-23';
    expect(
      () => NewMexicoDrawValidator.continuity(
        old['results'],
        old['queryWindow'],
        reg['results'],
        reg['queryWindow'],
        DateTime.parse(reg['updatedAt']),
      ),
      throwsFormatException,
    );
  });
}
