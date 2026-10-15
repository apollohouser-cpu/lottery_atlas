import 'dart:convert';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

/// Result-only validation. Schedules and advertised metadata require their own
/// checks before a complete collection may be adopted by the app.
class KansasResultValidator {
  static void need(bool value) {
    if (!value) throw const FormatException('Invalid Kansas results');
  }

  static final Map<String, dynamic> groups = jsonDecode(
    r'''{"pick3-midday": [9, "Pick 3", "Midday", "pick-3", 3, 9, null], "pick3-evening": [10, "Pick 3", "Evening", "pick-3", 3, 9, null], "2by2": [5, "2by2", "Drawing", "2-by-2", 2, 26, 26], "xs-os": [15, "Powerball Xs & Os", "Drawing", "powerball-xs-and-os", 8, 32, null], "keno": [19, "Keno", "Frequent", "keno", 20, 80, null], "racetrax": [11, "Racetrax", "Frequent", "racetrax", 4, 12, null], "powerball": [1, "Powerball", "Base", "powerball", 5, 69, 26], "powerball-double-play": [1, "Powerball", "Double Play", "powerball", 5, 69, 26], "mega-millions": [12, "Mega Millions", "Drawing", "megamillions", 5, 70, 24], "lotto-america": [3, "Lotto America", "Drawing", "lotto-america", 5, 52, 10], "millionaire-for-life": [14, "Millionaire for Life", "Drawing", "millionaire-for-life", 5, 58, 5], "super-kansas-cash": [8, "Super Kansas Cash", "Drawing", "super-kansas-cash", 5, 32, 25]}''',
  );
  static final Map<String, dynamic> teams = jsonDecode(
    r'''{"1": "ARI", "2": "ATL", "3": "BAL", "4": "BUF", "5": "CAR", "6": "CHI", "7": "CIN", "8": "CLE", "9": "DAL", "10": "DEN", "11": "DET", "12": "GB", "13": "HOU", "14": "IND", "15": "JAX", "16": "KC", "17": "LV", "18": "LAC", "19": "LAR", "20": "MIA", "21": "MIN", "22": "NE", "23": "NO", "24": "NYG", "25": "NYJ", "26": "PHI", "27": "PIT", "28": "SF", "29": "SEA", "30": "TB", "31": "TEN", "32": "WAS"}''',
  );
  static bool _zonesReady = false;
  static void same(dynamic a, dynamic b) =>
      need(jsonEncode(a) == jsonEncode(b));
  static DateTime timestamp(dynamic value) {
    need(
      value is String &&
          RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}Z$').hasMatch(value),
    );
    final parsed = DateTime.tryParse(value);
    need(
      parsed != null &&
          parsed.toUtc().toIso8601String().replaceFirst('.000Z', 'Z') == value,
    );
    return parsed!;
  }

  static void balls(
    dynamic values,
    int count,
    int min,
    int max, {
    bool unique = true,
  }) {
    need(values is List && values.length == count);
    for (final value in values) {
      need(value is String && RegExp(r'^(0|[1-9]\d*)$').hasMatch(value));
      final number = int.parse(value);
      need(number >= min && number <= max);
    }
    if (unique) need(values.toSet().length == count);
  }

  static void validate(dynamic rows, DateTime retrievedAt) {
    if (!_zonesReady) {
      tzdata.initializeTimeZones();
      _zonesReady = true;
    }
    final central = tz.getLocation('America/Chicago');
    need(rows is List && rows.length == 24);
    final ids = <String>{};
    final grouped = <String, List<Map>>{};
    for (final raw in rows) {
      need(raw is Map);
      final r = raw as Map;
      final group = r['group'];
      need(group is String && groups.containsKey(group));
      final c = groups[group] as List;
      need(
        r['family'] == c[1] && r['session'] == c[2] && r['scheduleKey'] == c[3],
      );
      need(
        r['sourceUrl'] == 'https://playonkansas.com/games/draw-games/${c[3]}',
      );
      need(r['drawTimeZone'] == 'America/Chicago');
      final stamp = timestamp(r['sourceDrawTimestamp']);
      need(!stamp.isAfter(retrievedAt));
      final local = tz.TZDateTime.from(stamp, central);
      need(r['sourceDrawingDate'] == stamp.toIso8601String().substring(0, 10));
      need(r['drawDate'] == local.toIso8601String().substring(0, 10));
      if (c[2] == 'Midday') {
        need(local.hour >= 11 && local.hour <= 15);
      } else if (c[2] != 'Frequent') {
        need(local.hour >= 20 && local.hour <= 23);
      }
      final numeric = [
        'Pick 3',
        'Super Kansas Cash',
        'Keno',
        'Racetrax',
      ].contains(c[1]);
      final external = r['sourceExternalId'];
      need(
        external is String &&
            RegExp(
              numeric
                  ? r'^[1-9]\d*$'
                  : r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
            ).hasMatch(external),
      );
      need(r['id'] == '$group:$external' && ids.add(r['id']));
      need(r['drawNumber'] == (numeric ? external : null));
      final normals = group == 'keno' ? 19 : c[4] as int;
      final specials = group == 'keno'
          ? 1
          : group == '2by2'
          ? 2
          : c[6] != null
          ? 1
          : 0;
      balls(
        r['numbers'],
        normals,
        c[1] == 'Pick 3' ? 0 : 1,
        c[5],
        unique: c[1] != 'Pick 3',
      );
      balls(r['specialNumbers'], specials, 1, c[6] ?? c[5]);
      if (group == 'keno') {
        need(<String>{...r['numbers'], ...r['specialNumbers']}.length == 20);
      }
      final ordered = r['sourceNumberOrder'];
      need(ordered is List && ordered.length == normals + specials);
      final normalValues = [], specialValues = [];
      for (var i = 0; i < ordered.length; i++) {
        final cell = ordered[i];
        need(
          cell is Map &&
              cell.length == 2 &&
              cell.containsKey('value') &&
              cell.containsKey('type'),
        );
        final special = group == 'keno'
            ? cell['type'] == 'SPECIAL'
            : i >= normals;
        final expectedType = group == 'racetrax'
            ? ['FIRST', 'SECOND', 'THIRD', 'FOURTH'][i]
            : special
            ? 'SPECIAL'
            : 'NORMAL';
        need(cell['type'] == expectedType);
        (special ? specialValues : normalValues).add(cell['value']);
      }
      same(normalValues, r['numbers']);
      same(specialValues, r['specialNumbers']);
      final mult = r['multiplier'];
      final allowed = group == 'powerball'
          ? [2, 3, 4, 5, 10]
          : group == 'lotto-america'
          ? [2, 3, 4, 5]
          : group == 'racetrax'
          ? [1, 3, 4, 5, 10]
          : null;
      if (group == '2by2') {
        need(mult == (local.weekday == DateTime.tuesday ? 2 : null));
      } else if (allowed != null) {
        need(mult is int && allowed.contains(mult));
      } else {
        need(mult == null);
      }
      if (group == 'mega-millions') {
        need((r['drawDate'] as String).compareTo('2025-04-08') >= 0);
      }
      same(
        r['teams'],
        group == 'xs-os' ? [for (final n in r['numbers']) teams[n]] : [],
      );
      need(
        r['sourceWarnings'] is List &&
            (r['sourceWarnings'] as List).every(
              (x) => x is String && x.isNotEmpty,
            ),
      );
      if (r['drawDate'] != r['sourceDrawingDate']) {
        need(
          r['sourceWarnings'].contains(
            'Source drawingDate uses the UTC date; local draw date is derived in America/Chicago from the preserved timestamp.',
          ),
        );
      }
      if (group == '2by2') {
        need(
          r['sourceWarnings'].contains(
            'Tuesday doubling applies only to qualifying consecutive-day plays; the result multiplier is not a universal payout.',
          ),
        );
      }
      need(
        r['coverage'] ==
            'Drawn numbers only. Kansas winner counts and actual payouts are not established by this source; prize schedules are separate.',
      );
      for (final forbidden in [
        'winnerCount',
        'shareCount',
        'prizeTiers',
        'latitude',
        'longitude',
      ]) {
        need(!r.containsKey(forbidden));
      }
      grouped.putIfAbsent(group, () => []).add(r);
    }
    need(grouped.length == groups.length);
    for (final entry in grouped.entries) {
      final pair = entry.value;
      need(pair.length == 2);
      need(
        timestamp(
          pair[0]['sourceDrawTimestamp'],
        ).isAfter(timestamp(pair[1]['sourceDrawTimestamp'])),
      );
      if (groups[entry.key][2] != 'Frequent') {
        need(pair[0]['drawDate'] != pair[1]['drawDate']);
      }
    }
  }
}
