import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/new_mexico_coverage_validator.dart';
import 'package:lottery_atlas/services/new_mexico_scratch_validator.dart';

void main() {
  Map<String, dynamic> fixture() => jsonDecode(
    File('data/new_mexico_coverage.generated.json').readAsStringSync(),
  );
  void setTime(Map d, String literal, String date) {
    final s = d['scratch'];
    final old = s['sourceTimestamp'];
    s['sourceTimestamp'] = literal;
    s['sourceDate'] = date;
    for (final g in s['games']) {
      g['inventoryNote'] = (g['inventoryNote'] as String).replaceAll(
        old,
        literal,
      );
    }
  }

  test(
    'new literal inventory timestamp accepted with unknown timezone intact',
    () {
      final d = fixture();
      setTime(d, 'October 26, 2026 01:00 AM', '2026-10-26');
      d['scratch']['games'][0]['topPrizesRemaining'] -= 1;
      final result = NewMexicoCoverageValidator.decode(jsonEncode(d));
      expect(result['scratch']['sourceTimestamp'], 'October 26, 2026 01:00 AM');
      expect(result['scratch']['sourceTimezone'], isNull);
    },
  );
  test(
    'wall time regression calendar mismatch future day and note changes reject',
    () {
      for (final triple in [
        ['October 25, 2026 01:00 AM', '2026-10-25'],
        ['October 26, 2026 01:00 AM', '2026-10-25'],
        ['October 27, 2026 01:00 AM', '2026-10-27'],
        ['October 26, 2026 13:00 AM', '2026-10-26'],
        ['February 30, 2026 01:00 AM', '2026-02-30'],
      ]) {
        final d = fixture();
        setTime(d, triple[0], triple[1]);
        expect(
          () => NewMexicoCoverageValidator.decode(jsonEncode(d)),
          throwsFormatException,
        );
      }
      final d = fixture();
      d['scratch']['games'][0]['inventoryNote'] = 'Exact retailer stock';
      expect(
        () => NewMexicoCoverageValidator.decode(jsonEncode(d)),
        throwsFormatException,
      );
    },
  );
  test('expiry requires prior deadline and fresh excluded identity', () {
    final prior = fixture()['scratch'] as Map;
    prior['games'][0]['lastDayToRedeem'] = '2026-10-25';
    final candidate = jsonDecode(jsonEncode(prior)) as Map;
    final removed = (candidate['games'] as List).removeAt(0);
    expect(
      () => NewMexicoScratchValidator.normalize(candidate, prior, '2026-10-26'),
      throwsFormatException,
    );
    final valid = jsonDecode(jsonEncode(prior)) as Map;
    (valid['games'] as List).removeAt(0);
    valid['excludedExpiredGameIds'].add(removed['id']);
    NewMexicoScratchValidator.normalize(valid, prior, '2026-10-26');
    expect(valid, prior);
  });
  test('unexpired missing duplicate or new catalog identities rejected', () {
    for (final mode in ['missing', 'duplicate', 'new']) {
      final d = fixture();
      final games = d['scratch']['games'] as List;
      if (mode == 'missing') {
        games.removeAt(0);
      }
      if (mode == 'duplicate') {
        games.add(games.first);
      }
      if (mode == 'new') {
        games.first['id'] = 'invented';
      }
      expect(
        () => NewMexicoCoverageValidator.decode(jsonEncode(d)),
        throwsFormatException,
      );
    }
  });
  test('cache timestamp continuity uses retained snapshot', () {
    final prior = fixture();
    setTime(prior, 'October 26, 2026 02:00 AM', '2026-10-26');
    final next = fixture();
    setTime(next, 'October 26, 2026 01:00 AM', '2026-10-26');
    NewMexicoCoverageValidator.decode(jsonEncode(next));
    expect(
      () => NewMexicoCoverageValidator.continuity(prior, next),
      throwsFormatException,
    );
  });
}
