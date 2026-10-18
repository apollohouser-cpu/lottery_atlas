import 'dart:convert';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest.dart' as tzdata;
import 'south_dakota_collection_contract.dart';

class SouthDakotaCollectionValidator {
  static bool _zonesReady = false;
  static void need(bool ok) {
    if (!ok) throw const FormatException('Invalid South Dakota collection');
  }

  static void exact(dynamic a, dynamic b) =>
      need(jsonEncode(a) == jsonEncode(b));
  static void shape(dynamic v, dynamic e, [String key = '']) {
    if (key == 'sdWinners' || (key == 'sdOptionWinners' && e != null)) {
      need(v is int && v >= 0 && v <= 9007199254740991);
      return;
    }
    if (key == 'drawId') {
      need(v is String && RegExp(r'^[1-9][0-9]*$').hasMatch(v));
      return;
    }
    if (key == 'drawDate') {
      need(v is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v));
      final d = DateTime.tryParse(v);
      need(d != null && d.toIso8601String().substring(0, 10) == v);
      return;
    }
    if (v is Map && e is Map) {
      need(
        v.keys.toSet().difference(e.keys.toSet()).isEmpty &&
            e.keys.toSet().difference(v.keys.toSet()).isEmpty,
      );
      for (final k in e.keys) {
        shape(v[k], e[k], k as String);
      }
    } else if (v is List && e is List) {
      need(v.length == e.length);
      for (var i = 0; i < e.length; i++) {
        shape(v[i], e[i]);
      }
    } else {
      exact(v, e);
    }
  }

  static const domains = {
    'Powerball': [5, 69, 26],
    'Mega Millions': [5, 70, 24],
    'Dakota Cash': [5, 35, 0],
    'Million 4 Life': [5, 58, 5],
    'Lotto America': [5, 52, 10],
    'Xs and Os': [8, 32, 0],
  };
  static const weekdays = {
    'Powerball': [1, 3, 6],
    'Mega Millions': [2, 5],
    'Dakota Cash': [3, 6],
    'Million 4 Life': [1, 2, 3, 4, 5, 6, 7],
    'Lotto America': [1, 3, 6],
    'Xs and Os': [7],
  };
  static void numbers(dynamic values, int count, int max) {
    need(values is List && values.length == count);
    need(values.toSet().length == count);
    for (final v in values) {
      need(v is String && RegExp(r'^[1-9][0-9]*$').hasMatch(v));
      final n = int.tryParse(v);
      need(n != null && n >= 1 && n <= max);
    }
  }

  static Map<String, dynamic> decode(String raw) {
    if (!_zonesReady) {
      tzdata.initializeTimeZones();
      _zonesReady = true;
    }
    final d = jsonDecode(raw);
    final template = jsonDecode(southDakotaContractJson);
    need(d is Map<String, dynamic>);
    need(
      d.keys.toSet().difference(template.keys.toSet()).isEmpty &&
          template.keys.toSet().difference(d.keys.toSet()).isEmpty,
    );
    exact(d['schemaVersion'], 1);
    exact(d['state'], 'South Dakota');
    exact(d['schedules'], template['schedules']);
    exact(d['limitations'], template['limitations']);
    need(
      d['retrievedAt'] is String &&
          RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(d['retrievedAt']),
    );
    final retrieved = DateTime.tryParse(d['retrievedAt']);
    need(retrieved != null);
    need(!retrieved!.isAfter(DateTime.now().add(const Duration(minutes: 5))));
    need(d['results'] is List && d['results'].length == 14);
    need(d['reports'] is List && d['reports'].length == 14);
    final groups = <String, List<String>>{};
    final keys = <String>{};
    for (var i = 0; i < 14; i++) {
      final r = d['results'][i];
      final e = template['results'][i];
      need(r is Map);
      final fixed = Map<String, dynamic>.from(r);
      final expected = Map<String, dynamic>.from(e);
      for (final k in ['primary', 'secondary', 'multiplier', 'rawDrawTime']) {
        fixed.remove(k);
        expected.remove(k);
      }
      shape(fixed, expected);
      need(
        r.keys.toSet().difference(e.keys.toSet()).isEmpty &&
            e.keys.toSet().difference(r.keys.toSet()).isEmpty,
      );
      final domain = domains[r['game']]!;
      numbers(r['primary'], domain[0], domain[1]);
      numbers(r['secondary'], domain[2] > 0 ? 1 : 0, domain[2]);
      final allowed = r['variant'] == 'Double Play'
          ? <int>[]
          : r['game'] == 'Powerball'
          ? [2, 3, 4, 5, 10]
          : r['game'] == 'Lotto America'
          ? [2, 3, 4, 5]
          : <int>[];
      need(
        allowed.isEmpty
            ? r['multiplier'] == null
            : r['multiplier'] is int && allowed.contains(r['multiplier']),
      );
      final stamp = r['rawDrawTime'];
      need(stamp is int && stamp >= 1577836800000 && stamp <= 4102444800000);
      final dt = DateTime.fromMillisecondsSinceEpoch(stamp, isUtc: true);
      need(!dt.isAfter(retrieved));
      final local = tz.TZDateTime.from(dt, tz.getLocation('America/Chicago'));
      need(
        local.toIso8601String().substring(0, 10) == r['drawDate'] &&
            weekdays[r['game']]!.contains(local.weekday),
      );
      final group = '${r['game']}/${r['variant']}';
      groups.putIfAbsent(group, () => []).add(r['drawDate']);
      need(keys.add('$group/${r['drawId']}'));
      final report = d['reports'][i];
      shape(report, template['reports'][i]);
      for (final k in ['game', 'variant', 'drawId', 'drawDate']) {
        exact(report[k], r[k]);
      }
    }
    need(
      groups.length == 7 &&
          groups.values.every(
            (dates) => dates.length == 2 && dates[0].compareTo(dates[1]) > 0,
          ),
    );
    return d;
  }

  static void continuity(Map<String, dynamic> old, Map<String, dynamic> next) {
    need(
      !DateTime.parse(
        next['retrievedAt'],
      ).isBefore(DateTime.parse(old['retrievedAt'])),
    );
    for (var i = 0; i < 14; i += 2) {
      need(
        (next['results'][i]['drawDate'] as String).compareTo(
              old['results'][i]['drawDate'],
            ) >=
            0,
      );
    }
    for (var i = 0; i < 14; i++) {
      final r = next['results'][i];
      for (var j = 0; j < 14; j++) {
        final p = old['results'][j];
        if (r['game'] == p['game'] &&
            r['variant'] == p['variant'] &&
            r['drawId'] == p['drawId']) {
          exact(r, p);
          exact(next['reports'][i], old['reports'][j]);
        }
      }
    }
  }
}
