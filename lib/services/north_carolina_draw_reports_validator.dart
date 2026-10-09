import 'dart:convert';

// Validate literal source units; never derive payouts or combine variant wins.
class NorthCarolinaDrawReportsValidator {
  static void need(bool ok) {
    if (!ok) throw const FormatException('Invalid NC draw reports');
  }

  static bool text(dynamic v) => v is String && v.trim().isNotEmpty;
  static bool count(dynamic v) => v is int && v >= 0 && v <= 9007199254740991;
  static void strings(dynamic v, {bool empty = false}) {
    need(v is List && (empty || v.isNotEmpty) && v.every(text));
  }

  static bool day(dynamic v) =>
      v is String &&
      RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v) &&
      DateTime.tryParse(v)?.toIso8601String().substring(0, 10) == v;
  static const sessions = {
    'Powerball': ['Drawing'],
    'Mega Millions': ['Drawing'],
    'Cash 5': ['Daily'],
    'Millionaire for Life': ['Daily'],
    'Powerball Xs and Os': ['Weekly'],
    'Pick 3': ['Daytime', 'Evening'],
    'Pick 4': ['Daytime', 'Evening'],
    'Cash Pop': [
      'Morning Buzz',
      'Lunch Rush',
      'Clock Out Cash',
      'Primetime Pop',
      'Midnight Money',
    ],
  };
  static const routes = {
    'Powerball': 'powerball',
    'Mega Millions': 'mega-millions',
    'Cash 5': 'cash5',
    'Millionaire for Life': 'millionaire-for-life',
    'Powerball Xs and Os': 'Powerball-Xs-and-Os',
    'Pick 3': 'Pick3-Draw',
    'Pick 4': 'Pick4-Draw',
    'Cash Pop': 'cash-pop',
  };
  static const pb = [
    '5+PB',
    '5',
    '4+PB',
    '4',
    '3+PB',
    '3',
    '2+PB',
    '1+PB',
    'PB',
  ];
  static const mb = [
    '5+MB',
    '5',
    '4+MB',
    '4',
    '3+MB',
    '3',
    '2+MB',
    '1+MB',
    'MB',
  ];
  static void numbers(dynamic v, int max) {
    need(
      v is List &&
          v.length == 5 &&
          v.toSet().length == 5 &&
          v.every((n) => n is int && n >= 1 && n <= max),
    );
  }

  static void tiers(
    dynamic list,
    List<String> labels, {
    bool sourceLabels = false,
    String? exception,
  }) {
    need(list is List && list.length == labels.length);
    for (var i = 0; i < labels.length; i++) {
      final t = list[i];
      need(
        t['matchLabel'] == labels[i] &&
            text(t['prizeLabel']) &&
            count(t['reportedWins']),
      );
      if (sourceLabels) {
        need(
          t['sourceMatchLabel'] == labels[i] ||
              (exception == 'PB' && i == 3 && t['sourceMatchLabel'] == '4+PB'),
        );
      }
    }
  }

  static void payout(dynamic r) {
    need(count(r['reportedWinners']) && count(r['reportedPayoutCents']));
    final label = r['reportedPayoutLabel'];
    need(
      label is String &&
          RegExp(r'^\$(?:\d+|\d{1,3}(?:,\d{3})+)(?:\.\d{2})?$').hasMatch(label),
    );
    final parts = (label as String).substring(1).replaceAll(',', '').split('.');
    need(
      int.parse(parts[0]) * 100 +
              (parts.length == 2 ? int.parse(parts[1]) : 0) ==
          r['reportedPayoutCents'],
    );
  }

  static Map<String, dynamic> decode(String raw) {
    final d = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    need(
      d['schemaVersion'] == 1 && d['stateCode'] == 'NC' && text(d['coverage']),
    );
    final at = DateTime.tryParse(d['updatedAt'] as String);
    need(
      at != null &&
          !at.isAfter(DateTime.now().toUtc().add(const Duration(minutes: 5))),
    );
    final reports = d['reports'] as List;
    need(reports.length == 28);
    final ids = <String>{}, dates = <String>{};
    final groups = <String, int>{};
    for (final r in reports) {
      final game = r['game'] as String, session = r['session'] as String;
      need(
        sessions[game]?.contains(session) == true &&
            text(r['id']) &&
            ids.add(r['id']) &&
            day(r['drawDate']) &&
            text(r['coverage']),
      );
      need(
        (r['drawDate'] as String).compareTo(
              at!.toUtc().toIso8601String().substring(0, 10),
            ) <=
            0,
      );
      final group = '$game/$session';
      groups[group] = (groups[group] ?? 0) + 1;
      need(dates.add('$group/${r['drawDate']}'));
      final u = Uri.parse(r['sourceUrl'] as String);
      need(
        u.scheme == 'https' &&
            u.host == 'nclottery.com' &&
            u.userInfo.isEmpty &&
            !u.hasPort &&
            u.path == '/${routes[game]}',
      );
      if (game == 'Cash Pop') {
        need(
          !u.hasQuery &&
              u.fragment == 'CashPopPast' &&
              r['reportType'] == 'session-summary' &&
              r['pop'] is int &&
              r['pop'] >= 1 &&
              r['pop'] <= 15 &&
              text(r['sessionTimeLabel']),
        );
        payout(r);
      } else if (game.startsWith('Pick ')) {
        need(
          !u.hasFragment &&
              u.queryParameters.length == 1 &&
              RegExp(r'^\d+$').hasMatch(u.queryParameters['dn'] ?? '') &&
              r['reportType'] == 'combined-summary',
        );
        final digits = r['winningDigits'] as List;
        need(
          digits.length == (game == 'Pick 3' ? 3 : 4) &&
              digits.every((v) => v is String && RegExp(r'^\d$').hasMatch(v)) &&
              r['fireball'] is String &&
              RegExp(r'^\d$').hasMatch(r['fireball']),
        );
        payout(r);
        need(text(r['sourceSummaryLabel']));
        final schedules = r['payoutSchedules'] as List;
        need(schedules.length == 2);
        for (var i = 0; i < 2; i++) {
          final s = schedules[i];
          need(
            s['title'] == (i == 0 ? '$game Prizes' : 'Fireball Prizes') &&
                s['payoutHeading'] == (i == 0 ? 'Payout' : 'Payout / Win') &&
                text(s['coverage']),
          );
          need(
            jsonEncode(s['wagerLabels']) ==
                jsonEncode(['50¢ Base Play', r'$1 Base Play']),
          );
          strings(s['notes'], empty: i == 0);
          final rows = s['rows'] as List;
          need(rows.isNotEmpty && rows.length <= 30);
          final keys = <String>{};
          for (final row in rows) {
            need(
              [
                    'EXACT',
                    'ANY',
                    '50/50',
                    'COMBO',
                    'PAIR',
                  ].contains(row['playType']) &&
                  row['matchLabel'] is String &&
                  keys.add('${row['playType']}/${row['matchLabel']}'),
            );
            strings(row['payoutLabels']);
            need(row['payoutLabels'].length == 2);
          }
          need(rows.any((row) => row['playType'] == 'EXACT'));
        }
      } else {
        final dt = DateTime.parse(r['drawDate']);
        need(
          !u.hasFragment &&
              u.queryParameters.length == 1 &&
              u.queryParameters['dd'] ==
                  '${dt.month.toString().padLeft(2, '0')}/${dt.day.toString().padLeft(2, '0')}/${dt.year}' &&
              r['reportType'] == 'tier-report',
        );
        if (game == 'Powerball' || game == 'Cash 5') {
          final vs = r['variants'] as List;
          final power = game == 'Powerball';
          need(vs.length == (power ? 3 : 2));
          for (var i = 0; i < vs.length; i++) {
            final v = vs[i];
            need(
              v['name'] ==
                  (i == 0
                      ? game
                      : power && i == 1
                      ? 'Power Play'
                      : 'Double Play'),
            );
            strings(v['notes'], empty: !power);
            if (power && i == 1) {
              need(
                RegExp(
                  r'^POWER PLAY (2|3|4|5|10)x$',
                ).hasMatch(v['multiplierLabel'] as String),
              );
            } else {
              numbers(v['winningNumbers'], power ? 69 : 43);
              if (power) {
                need(
                  v['powerball'] is int &&
                      v['powerball'] >= 1 &&
                      v['powerball'] <= 26,
                );
              }
            }
            tiers(
              v['tiers'],
              power
                  ? (i == 1 ? pb.sublist(1) : pb)
                  : ['5 of 5', '4 of 5', '3 of 5', '2 of 5'],
              sourceLabels: power,
              exception: power && i == 2 ? 'PB' : null,
            );
          }
          if (power &&
              vs[2]['tiers'].any(
                (t) => t['matchLabel'] != t['sourceMatchLabel'],
              )) {
            strings(r['sourceWarnings']);
          }
        } else {
          strings(r['notes']);
          if (game == 'Powerball Xs and Os') {
            strings(r['teamLabels']);
            need(
              r['teamLabels'].length == 8 &&
                  r['teamLabels'].toSet().length == 8,
            );
            tiers(r['tiers'], [
              'Match 8',
              'Match 7',
              'Match 6',
              'Match 5',
              'Match 4',
            ]);
          } else {
            final mega = game == 'Mega Millions';
            numbers(r['winningNumbers'], mega ? 70 : 58);
            final bonus = r[mega ? 'megaBall' : 'millionaireBall'];
            need(bonus is int && bonus >= 1 && bonus <= (mega ? 24 : 5));
            if (!mega) {
              tiers(r['tiers'], [
                '5+MB',
                '5',
                '4+MB',
                '4',
                '3+MB',
                '3',
                '2+MB',
                '2',
                '1+MB',
              ]);
            } else {
              need(r['multiplierHeading'] == 'Megaplier');
              final ts = r['tiers'] as List;
              need(ts.length == 41);
              for (var i = 0; i < 41; i++) {
                final t = ts[i], label = mb[i == 0 ? 0 : 1 + (i - 1) ~/ 5];
                need(
                  t['matchLabel'] == label &&
                      text(t['prizeLabel']) &&
                      count(t['reportedWins']) &&
                      t['multiplierLabel'] ==
                          (i == 0
                              ? null
                              : ['X10', 'X5', 'X4', 'X3', 'X2'][(i - 1) % 5]),
                );
                need(
                  t['sourceMatchLabel'] == label ||
                      (label == '1+MB' && t['sourceMatchLabel'] == '2'),
                );
              }
              if (ts.any((t) => t['sourceMatchLabel'] != t['matchLabel'])) {
                strings(r['sourceWarnings']);
              }
            }
          }
        }
      }
      if (r.containsKey('sourceWarnings')) strings(r['sourceWarnings']);
    }
    need(groups.length == 14 && groups.values.every((n) => n == 2));
    return d;
  }

  static void continuity(Map<String, dynamic> old, Map<String, dynamic> next) {
    need(
      !DateTime.parse(
        next['updatedAt'],
      ).isBefore(DateTime.parse(old['updatedAt'])),
    );
    for (final game in sessions.keys) {
      for (final session in sessions[game]!) {
        List<String> dates(Map<String, dynamic> d) =>
            (d['reports'] as List)
                .where((r) => r['game'] == game && r['session'] == session)
                .map<String>((r) => r['drawDate'] as String)
                .toList()
              ..sort();
        final a = dates(old), b = dates(next);
        for (var i = 0; i < 2; i++) {
          need(b[i].compareTo(a[i]) >= 0);
        }
      }
    }
  }
}
