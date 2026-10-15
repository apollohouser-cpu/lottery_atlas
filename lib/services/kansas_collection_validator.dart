import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'kansas_result_validator.dart';
import 'kansas_schedule_validator.dart';

class KansasCollectionValidator {
  static void need(bool ok) => KansasResultValidator.need(ok);
  static final dynamic _coverage = jsonDecode(
    r'''{"resultUnit": "Published drawn numbers, not Kansas winner counts or actual payouts.", "window": "Two recent results per current group; twelve groups across ten families.", "frequentGames": "Keno and Racetrax are bounded snapshots, not a live results service.", "dates": "Local draw date derived in America/Chicago; raw UTC timestamp and source date retained.", "prizes": "Literal schedules are separate from results. Advertised amounts are separately dated source values, not calculated awards.", "excluded": ["Unverified prize-tier share counts and payout amounts", "Historical Lucky for Life and raffle results", "Full historical archives", "Retailer joins or map coordinates"]}''',
  );
  static DateTime retrieval(dynamic v) {
    need(
      v is String &&
          RegExp(
            r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$',
          ).hasMatch(v),
    );
    final time = DateTime.tryParse(v);
    need(
      time != null &&
          !time.isAfter(DateTime.now().toUtc().add(const Duration(minutes: 5))),
    );
    return time!;
  }

  static Map<String, dynamic> decode(String raw) {
    final value = jsonDecode(raw);
    need(
      value is Map<String, dynamic> &&
          value['schemaVersion'] == 1 &&
          value['state'] == 'KS',
    );
    final time = retrieval(value['retrievedAt']);
    KansasResultValidator.validate(value['reports'], time);
    KansasScheduleValidator.validate(value['schedules']);
    KansasResultValidator.same(value['coverage'], _coverage);
    final prizes = value['advertisedPrizes'];
    need(prizes is List && prizes.length == 4);
    final keys = <String>{};
    for (final p in prizes) {
      need(p is Map);
      final key = p['scheduleKey'];
      need(
        [
              'powerball',
              'lotto-america',
              'super-kansas-cash',
              'megamillions',
            ].contains(key) &&
            keys.add(key),
      );
      need(p['sourceUrl'] == 'https://playonkansas.com/games/draw-games/$key');
      final stamp = KansasResultValidator.timestamp(p['sourceDrawTimestamp']);
      final local = tz.TZDateTime.from(
        stamp,
        tz.getLocation('America/Chicago'),
      );
      need(p['sourceDrawingDate'] == stamp.toIso8601String().substring(0, 10));
      need(
        p['drawDate'] == local.toIso8601String().substring(0, 10) &&
            p['drawTimeZone'] == 'America/Chicago',
      );
      need(p['sourceDrawTimeHasPassed'] == !stamp.isAfter(time));
      bool amount(dynamic n) => n is int && n > 0 && n <= 9007199254740991;
      need(amount(p['advertisedCashDollars']));
      need(
        key == 'super-kansas-cash'
            ? p['advertisedAnnuityDollars'] == null
            : amount(p['advertisedAnnuityDollars']),
      );
      need(
        p['coverage'] ==
            'Source-advertised amounts for the identified drawing, not actual paid prizes. Cash value is directly supplied, not converted.',
      );
      KansasResultValidator.same(p['sourceWarnings'], [
        'Source nextDrawingDate uses UTC; local date is derived from its timestamp. A passed source draw time must not be labeled upcoming.',
      ]);
    }
    return value;
  }

  static void continuity(Map<String, dynamic> old, Map<String, dynamic> next) {
    need(
      !retrieval(next['retrievedAt']).isBefore(retrieval(old['retrievedAt'])),
    );
    for (final group in KansasResultValidator.groups.keys) {
      List<String> times(Map<String, dynamic> v) =>
          (v['reports'] as List)
              .where((r) => r['group'] == group)
              .map<String>((r) => r['sourceDrawTimestamp'])
              .toList()
            ..sort();
      final before = times(old), after = times(next);
      need(before.length == 2 && after.length == 2);
      for (var i = 0; i < 2; i++) {
        need(after[i].compareTo(before[i]) >= 0);
      }
    }
    final oldIds = {for (final r in old['reports']) r['id']: r};
    for (final r in next['reports']) {
      final prior = oldIds[r['id']];
      if (prior != null) {
        need(prior['sourceDrawTimestamp'] == r['sourceDrawTimestamp']);
      }
    }
    final oldPrizes = {
      for (final p in old['advertisedPrizes']) p['scheduleKey']: p,
    };
    for (final p in next['advertisedPrizes']) {
      need(
        (p['sourceDrawTimestamp'] as String).compareTo(
              oldPrizes[p['scheduleKey']]['sourceDrawTimestamp'],
            ) >=
            0,
      );
    }
  }
}
