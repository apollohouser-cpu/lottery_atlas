import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'iowa_coverage_contract.dart';

class IowaCoverageValidator {
  static bool _ready = false;
  static void need(bool value) {
    if (!value) throw const FormatException('Invalid Iowa coverage');
  }

  static void exact(dynamic a, dynamic b) =>
      need(jsonEncode(a) == jsonEncode(b));
  static DateTime day(dynamic value) {
    need(value is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(value));
    final parsed = DateTime.tryParse(value);
    need(parsed != null && parsed.toIso8601String().substring(0, 10) == value);
    return parsed!;
  }

  static void count(dynamic value) =>
      need(value is int && value >= 0 && value <= 9007199254740991);
  static const domains = {
    'powerball': [5, 69, 26],
    'double_play': [5, 69, 26],
    'mega_millions': [5, 70, 24],
    'lotto_america': [5, 52, 10],
    'millionaire_for_life': [5, 58, 5],
    'pick3_midday': [3, 9, 0],
    'pick3_evening': [3, 9, 0],
    'pick4_midday': [4, 9, 0],
    'pick4_evening': [4, 9, 0],
  };
  static const teams =
      'ARI ATL BAL BUF CAR CHI CIN CLE DAL DEN DET GB HOU IND JAX KC LAC LAR LV MIA MIN NE NO NYG NYJ PHI PIT SEA SF TB TEN WAS';
  static Map<String, dynamic> decode(String raw) {
    if (!_ready) {
      tzdata.initializeTimeZones();
      _ready = true;
    }
    final d = jsonDecode(raw) as Map<String, dynamic>;
    final template = jsonDecode(iowaCoverageContractJson);
    exact(d['schemaVersion'], 1);
    exact(d['state'], 'Iowa');
    final retrieved = DateTime.parse(d['retrievedAt']);
    need(RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(d['retrievedAt']));
    need(
      !retrieved.isAfter(
        DateTime.now().toUtc().add(const Duration(minutes: 5)),
      ),
    );
    final local = tz.TZDateTime.from(
      retrieved,
      tz.getLocation('America/Chicago'),
    );
    final cutoff = DateTime(local.year, local.month, local.day);
    final draws = d['draws'];
    exact(draws['state'], 'Iowa');
    exact(draws['retrievedAt'], d['retrievedAt']);
    exact(draws['charts'], template['draws']['charts']);
    exact(draws['rules'], template['draws']['rules']);
    exact(draws['limitations'], template['draws']['limitations']);
    final rows = draws['results'] as List;
    need(rows.length == 20);
    final groups = <String, List<dynamic>>{};
    for (final row in rows) {
      final group = row['group'] as String;
      need(domains.containsKey(group) || group == 'xsos');
      groups.putIfAbsent(group, () => []).add(row);
      final date = day(row['drawDate']);
      need(!date.isAfter(cutoff) && !date.isBefore(DateTime(2026, 2, 22)));
      final parts = (row['sourceDateText'] as String)
          .split('/')
          .map(int.parse)
          .toList();
      exact(parts, [date.month, date.day, date.year]);
      final sample = (template['draws']['results'] as List).firstWhere(
        (r) => r['group'] == group,
      );
      exact(row['sourceUrl'], sample['sourceUrl']);
      if (group == 'xsos') {
        final codes = row['teamCodes'] as List;
        need(codes.length == 8 && codes.toSet().length == 8);
        need(codes.every((c) => teams.split(' ').contains(c)));
        exact(
          row['teamImageSources'],
          codes
              .map(
                (c) =>
                    'https://www.ialottery.com/images/game-logos/PBXO_Teams/$c.png',
              )
              .toList(),
        );
        exact(row['teamLabel'], sample['teamLabel']);
      } else {
        final spec = domains[group]!;
        final values = row['numbers'] as List;
        final pick = group.startsWith('pick');
        need(values.length == spec[0]);
        need(
          values.every((n) => n is int && n >= (pick ? 0 : 1) && n <= spec[1]),
        );
        if (!pick) {
          need(values.toSet().length == values.length);
          for (var i = 1; i < values.length; i++) {
            need(values[i] > values[i - 1]);
          }
          need(
            row['specialBall'] is int &&
                row['specialBall'] >= 1 &&
                row['specialBall'] <= spec[2],
          );
        }
        if (group == 'powerball' || group == 'lotto_america') {
          need(
            (group == 'powerball' ? [2, 3, 4, 5, 10] : [2, 3, 4, 5]).contains(
              row['multiplier'],
            ),
          );
        } else {
          need(!row.containsKey('multiplier'));
        }
      }
      final report = row['report'];
      if (group.startsWith('pick')) {
        need(report == null);
        exact(row['reportLimitation'], sample['reportLimitation']);
      } else if (report == null) {
        exact(
          row['reportLimitation'],
          'No validated report for this exact date and group',
        );
      } else {
        final expected = sample['report'];
        exact(report['group'], group);
        exact(report['drawDate'], row['drawDate']);
        exact(report['sourceDateText'], row['sourceDateText']);
        exact(report['countLabel'], expected['countLabel']);
        final tiers = report['tiers'] as List;
        need(tiers.length == expected['tiers'].length);
        for (var i = 0; i < tiers.length; i++) {
          exact(
            tiers[i]['sourceTierLabel'],
            expected['tiers'][i]['sourceTierLabel'],
          );
          count(tiers[i]['sourceWinners']);
        }
        exact(
          report.containsKey('multiplier'),
          expected.containsKey('multiplier'),
        );
        exact(
          report.containsKey('sourceJackpotText'),
          expected.containsKey('sourceJackpotText'),
        );
        if (report.containsKey('multiplier')) {
          exact(report['multiplier'], row['multiplier']);
        }
        if (report.containsKey('sourceJackpotText')) {
          final text = report['sourceJackpotText'] as String;
          need(
            RegExp(r'^\$(0|[1-9]\d{0,2}(,\d{3})*|[1-9]\d*)$').hasMatch(text),
          );
          final amount = int.parse(text.substring(1).replaceAll(',', ''));
          exact(
            report['advertisedJackpotDollars'],
            amount == 0 ? null : amount,
          );
          if (amount == 0) {
            exact(
              report['jackpotLimitation'],
              'Source zero placeholder; advertised prize unavailable',
            );
          }
        }
      }
    }
    need(groups.length == 10);
    for (final group in groups.values) {
      need(
        group.length == 2 &&
            day(group[0]['drawDate']).isAfter(day(group[1]['drawDate'])),
      );
    }
    // Initial inventory contract stays reviewed: unknown additions/corrections cannot silently replace it.
    exact(d['instantInventories'], template['instantInventories']);
    exact(d['scratchCatalog'], template['scratchCatalog']);
    return d;
  }

  static void continuity(Map<String, dynamic> old, Map<String, dynamic> next) {
    need(
      !DateTime.parse(
        next['retrievedAt'],
      ).isBefore(DateTime.parse(old['retrievedAt'])),
    );
    final previous = old['draws']['results'] as List;
    for (final row in next['draws']['results']) {
      final same = previous.where((r) => r['group'] == row['group']).toList();
      need(!day(row['drawDate']).isBefore(day(same.last['drawDate'])));
      for (final retained in same) {
        if (retained['drawDate'] == row['drawDate']) exact(row, retained);
      }
    }
  }
}
