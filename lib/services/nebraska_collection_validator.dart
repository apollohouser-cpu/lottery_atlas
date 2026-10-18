import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'nebraska_collection_contract.dart';

class NebraskaCollectionValidator {
  static bool _zonesReady = false;
  static void need(bool ok) {
    if (!ok) throw const FormatException('Invalid Nebraska collection');
  }

  static DateTime day(dynamic v) {
    need(v is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v));
    final d = DateTime.tryParse(v);
    need(d != null && d.toIso8601String().substring(0, 10) == v);
    return d!;
  }

  static void exact(dynamic a, dynamic b) =>
      need(jsonEncode(a) == jsonEncode(b));
  static void shape(
    dynamic value,
    dynamic expected, {
    String key = '',
    int factor = 0,
    bool? applicable,
  }) {
    if (key == 'drawDate') {
      day(value);
      return;
    }
    if (key == 'sourceWinners') {
      need(value is int && value >= 0 && value <= 9007199254740991);
      return;
    }
    if (key == 'multiplier' && factor != 0) {
      need(value == factor);
      return;
    }
    if (key == 'applicable') {
      need(value == applicable);
      return;
    }
    if (key == 'countUnit' && applicable != null) {
      need(value == (applicable ? 'Winners (source label)' : null));
      return;
    }
    if (key == 'prizeLabel' &&
        factor != 0 &&
        expected is String &&
        expected.contains(' X ')) {
      need(value == expected.replaceAll(RegExp(r' X [2-5]'), ' X $factor'));
      return;
    }
    if (expected is Map) {
      need(value is Map);
      final keys = expected.keys.toSet();
      if (applicable == true &&
          expected.containsKey('match') &&
          !expected.containsKey('oddsLabel')) {
        keys.add('sourceWinners');
      }
      need(
        value.keys.toSet().difference(keys).isEmpty &&
            keys.difference(value.keys.toSet()).isEmpty,
      );
      for (final k in keys) {
        shape(
          value[k],
          expected[k],
          key: k,
          factor: factor,
          applicable: applicable,
        );
      }
    } else if (expected is List) {
      need(value is List && value.length == expected.length);
      for (var i = 0; i < expected.length; i++) {
        shape(value[i], expected[i], factor: factor, applicable: applicable);
      }
    } else {
      exact(value, expected);
    }
  }

  static Map<String, dynamic> decode(String raw) {
    if (!_zonesReady) {
      tzdata.initializeTimeZones();
      _zonesReady = true;
    }
    final d = jsonDecode(raw);
    need(d is Map<String, dynamic>);
    need(
      d.keys.toSet().difference({
        'state',
        'results',
        'familyReports',
        'limitation',
        'retrievedAt',
        'schemaVersion',
      }).isEmpty,
    );
    need(d['state'] == 'NE' && d['schemaVersion'] == 1);
    exact(d['limitation'], nebraskaContract['limitation']);
    final stamp = d['retrievedAt'];
    need(stamp is String && RegExp(r'(Z|[+-]\d{2}:\d{2})$').hasMatch(stamp));
    final time = DateTime.tryParse(stamp);
    need(
      time != null &&
          !time.isAfter(DateTime.now().add(const Duration(minutes: 5))),
    );
    final local = tz.TZDateTime.from(time!, tz.getLocation('America/Chicago'));
    final today = DateTime(local.year, local.month, local.day);
    final results = d['results'];
    need(results is List && results.length == 22);
    var cursor = 0;
    final latest = <String, String>{};
    for (final family in (nebraskaDomains as Map).keys) {
      for (final spec in nebraskaDomains[family]) {
        DateTime? previous;
        for (var i = 0; i < 2; i++) {
          final r = results[cursor], ref = nebraskaContract['results'][cursor];
          cursor++;
          need(r is Map);
          exact(r.keys.toList()..sort(), ref.keys.toList()..sort());
          for (final k in ['family', 'group', 'dateZone', 'sourceUrl']) {
            exact(r[k], ref[k]);
          }
          final date = day(r['drawDate']);
          need(
            !date.isAfter(today) &&
                (previous == null || date.isBefore(previous)),
          );
          final weekdays = {
            'Powerball': [1, 3, 6],
            'Mega Millions': [2, 5],
            'Lotto America': [1, 3, 6],
            'Powerball Xs and Os': [7],
          };
          need(
            !weekdays.containsKey(family) ||
                weekdays[family]!.contains(date.weekday),
          );
          previous = date;
          if (i == 0) latest[spec[0]] = r['drawDate'];
          final fields = r['fields'];
          need(fields is List && fields.length == spec[1].length);
          for (var j = 0; j < fields.length; j++) {
            final f = fields[j];
            need(f is Map && f['label'] == spec[1][j]);
            final values = f['values'];
            need(values is List);
            if (spec[2] == null) {
              need(
                f.length == 2 &&
                    values.length == 8 &&
                    values.toSet().length == 8 &&
                    values.every(nebraskaTeams.contains),
              );
            } else {
              final domain = spec[2][j];
              need(
                f.length == 3 &&
                    values.length == domain[0] &&
                    values.every(
                      (x) => x is int && x >= domain[1] && x <= domain[2],
                    ),
              );
              need(domain[3] != true || values.toSet().length == values.length);
              need(
                f['sourceText'] is String &&
                    RegExp(
                      r'^\d{1,2}(?:,\s*\d{1,2})*$',
                    ).hasMatch(f['sourceText']),
              );
              exact(
                (f['sourceText'] as String)
                    .split(',')
                    .map((x) => int.parse(x.trim()))
                    .toList(),
                values,
              );
              if (f['label'] == 'Powerplay') {
                need([2, 3, 4, 5, 10].contains(values[0]));
              }
            }
          }
          if (family == 'MyDaY') {
            final y = 2000 + fields[2]['values'][0] as int,
                m = fields[0]['values'][0] as int,
                dd = fields[1]['values'][0] as int;
            final calendar = DateTime(y, m, dd);
            need(
              calendar.year == y && calendar.month == m && calendar.day == dd,
            );
          }
        }
      }
    }
    final reports = d['familyReports'];
    need(reports is List && reports.length == 10);
    for (var i = 0; i < reports.length; i++) {
      final f = reports[i], ref = nebraskaContract['familyReports'][i];
      final family = ref['family'];
      final group = nebraskaDomains[family][0][0];
      var factor = 0;
      if (family == 'Powerball' || family == 'Lotto America') {
        factor =
            (results
                    .firstWhere((r) => r['group'] == group)['fields']
                    .last['values'][0])
                as int;
      }
      if (family == '2by2') {
        final copy = Map<String, dynamic>.from(f);
        copy.remove('reports');
        final expected = Map<String, dynamic>.from(ref);
        expected.remove('reports');
        shape(copy, expected);
        need(f['reports'] is List && f['reports'].length == 2);
        for (var j = 0; j < 2; j++) {
          final r = f['reports'][j];
          need(r['drawDate'] == latest[group]);
          shape(
            r,
            ref['reports'][j],
            applicable: j == 0 || day(r['drawDate']).weekday == 2,
          );
        }
      } else {
        shape(f, ref, factor: factor);
        for (final r in f['reports'] ?? [f]) {
          need(
            r['drawDate'] ==
                latest[r['variant'] == 'double-play' ? 'double-play' : group],
          );
        }
      }
    }
    return d;
  }

  static void continuity(Map<String, dynamic> old, Map<String, dynamic> next) {
    need(
      !DateTime.parse(
        next['retrievedAt'],
      ).isBefore(DateTime.parse(old['retrievedAt'])),
    );
    for (var i = 0; i < 22; i++) {
      need(
        !day(
          next['results'][i]['drawDate'],
        ).isBefore(day(old['results'][i]['drawDate'])),
      );
    }
  }
}
