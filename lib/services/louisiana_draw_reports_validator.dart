import 'dart:convert';

/// Validates source units without combining variants, multipliers or dollar totals.
class LouisianaDrawReportsValidator {
  static void need(bool ok) {
    if (!ok) throw const FormatException('Invalid Louisiana draw reports');
  }

  static bool text(dynamic v) => v is String && v.trim().isNotEmpty;
  static bool count(dynamic v) => v is int && v >= 0 && v <= 9007199254740991;
  static void strings(dynamic v, {bool empty = false}) =>
      need(v is List && (empty || v.isNotEmpty) && v.every(text));
  static void same(dynamic a, dynamic b) =>
      need(jsonEncode(a) == jsonEncode(b));
  static DateTime day(dynamic v) {
    need(v is String && RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v));
    final d = DateTime.tryParse(v);
    need(d != null && d.toIso8601String().substring(0, 10) == v);
    return d!;
  }

  static DateTime stamp(dynamic v) {
    need(
      v is String &&
          RegExp(
            r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}(?:\.\d+)?(?:Z|[+-]\d{2}:\d{2})$',
          ).hasMatch(v),
    );
    day(v.substring(0, 10));
    need(
      int.parse(v.substring(11, 13)) < 24 &&
          int.parse(v.substring(14, 16)) < 60 &&
          int.parse(v.substring(17, 19)) < 60,
    );
    final d = DateTime.tryParse(v);
    need(
      d != null &&
          !d.isAfter(DateTime.now().toUtc().add(const Duration(minutes: 5))),
    );
    return d!;
  }

  static int money(dynamic v) {
    need(
      v is String &&
          RegExp(
            r'^\$(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)(?:\.\d{2})?$',
          ).hasMatch(v),
    );
    final parts = (v as String).substring(1).replaceAll(',', '').split('.');
    final cents =
        int.parse(parts[0]) * 100 +
        (parts.length == 2 ? int.parse(parts[1]) : 0);
    need(count(cents));
    return cents;
  }

  static const routes = {
    'Lotto': 'lotto',
    'Easy 5': 'easy-5',
    'Powerball': 'powerball',
    'Mega Millions': 'mega-millions',
    'Pick 3': 'pick-3',
    'Pick 4': 'pick-4',
    'Pick 5': 'pick-5',
  };
  static const dateWarning =
      'The printed source update date precedes the draw date. Both dates are retained without correction.';
  static const megaWarnings = [
    'The source match descriptions call the Mega Ball "Megaplier". Literal labels and Mega Ball symbols are retained.',
    'The source repeats the jackpot row across multiplier columns. These entries are not summed into a jackpot winner total.',
  ];

  static void number(dynamic v, int maximum) {
    need(
      v is String &&
          RegExp(r'^\d{2}$').hasMatch(v) &&
          int.parse(v) >= 1 &&
          int.parse(v) <= maximum,
    );
  }

  static void numbers(dynamic v, int size, int maximum) {
    need(v is List && v.length == size && v.toSet().length == size);
    for (final n in v) {
      number(n, maximum);
    }
  }

  static void sourceTime(Map r) {
    final iso = r['sourceUpdatedAt'];
    stamp(iso);
    final m = RegExp(
      r'^Last Updated: (\d{2})/(\d{2})/(\d{4}) (\d{2}):(\d{2}):(\d{2}) ([AP]M) (CDT|CST)$',
    ).firstMatch(r['sourceUpdatedText'] as String);
    need(m != null);
    final hour = int.parse(m![4]!);
    need(hour >= 1 && hour <= 12);
    final h = hour % 12 + (m[7] == 'PM' ? 12 : 0);
    final expected =
        '${m[3]}-${m[1]}-${m[2]}T${h.toString().padLeft(2, '0')}:${m[5]}:${m[6]}${m[8] == 'CDT' ? '-05:00' : '-06:00'}';
    need(iso == expected);
    // Current US Central rules: second Sunday in March to first Sunday in November.
    final local = DateTime.parse(expected.substring(0, 19));
    final march = DateTime(local.year, 3, 1);
    final november = DateTime(local.year, 11, 1);
    final start = DateTime(local.year, 3, 1 + (7 - march.weekday) % 7 + 7, 2);
    final end = DateTime(local.year, 11, 1 + (7 - november.weekday) % 7, 2);
    // The repeated fall-back hour legitimately has either printed offset.
    if (!(local.month == 11 && local.day == end.day && local.hour == 1)) {
      need((m[8] == 'CDT') == (!local.isBefore(start) && local.isBefore(end)));
    }
    if (iso.substring(0, 10).compareTo(r['drawDate']) < 0) {
      need((r['sourceWarnings'] as List).contains(dateWarning));
    }
  }

  static void qualifications(Map r) {
    strings(r['qualifications']);
    final q = (r['qualifications'] as List).join(' ');
    final g = r['game'] as String;
    final terms = g.startsWith('Pick ')
        ? ['Straight/Box', r'$1', 'liability']
        : {
            'Lotto': ['pari-mutuel', 'divided equally', 'fixed amount'],
            'Easy 5': ['cash', 'carried over', 'prize pool'],
            'Powerball': ['annuity', '30 graduated installments', 'cash'],
            'Mega Millions': [
              'annuity',
              '30 graduated installments',
              'does not apply to the jackpot',
              'randomly assigned at the time of purchase',
            ],
          }[g]!;
    need(terms.every(q.contains));
  }

  static void schedule(dynamic tables, int size) {
    need(tables is List && tables.length == 4);
    final ways = {
      3: [3, 6],
      4: [4, 6, 12, 24],
      5: [5, 10, 20, 30, 60, 120],
    }[size]!;
    final labels = [
      ['Straight (Exact Order)'],
      [for (final n in ways) '$n-Way Box'],
      [for (final n in ways) '$n-Way Straight/Box'],
      size < 5
          ? [for (final n in ways) '$n-Way Combo']
          : [
              'Front 4',
              'Back 4',
              'Front 3',
              'Back 3',
              'Front Pair',
              'Back Pair',
            ],
    ];
    for (var i = 0; i < 4; i++) {
      final t = tables[i];
      final columns = [
        'Play Type',
        'Example Wager',
        'Winning Combos',
        if (i == 2 || (i == 3 && size < 5))
          'Payout'
        else ...[
          'Payout (50¢)',
          r'Payout ($1)',
        ],
      ];
      same(t['columns'], columns);
      same(
        t['columnSpans'],
        i == 3 && size < 5 ? [1, 1, 1, 2] : List.filled(columns.length, 1),
      );
      final rows = t['rows'];
      need(rows is List && rows.length == labels[i].length * (i == 2 ? 2 : 1));
      for (var j = 0; j < rows.length; j++) {
        final c = rows[j]['cells'];
        strings(c);
        final continuation = i == 2 && j.isOdd;
        need(c.length == (continuation ? 2 : (i == 2 ? 4 : 5)));
        same(
          rows[j]['rowSpans'],
          i == 2 && !continuation ? [2, 2, 1, 1] : List.filled(c.length, 1),
        );
        if (!continuation) {
          need(
            (c[0] as String).startsWith('${labels[i][i == 2 ? j ~/ 2 : j]} ') &&
                c[0].contains('Odds -'),
          );
        }
        for (final value in c.skip(c.length - (i == 2 ? 1 : 2))) {
          final m = RegExp(
            r'^(\$[\d,]+(?:\.\d{2})?)(?: \((\$[\d,]+\.\d{2}) play\))?$',
          ).firstMatch(value);
          need(m != null && (m[2] != null) == (i == 3 && size < 5));
          money(m![1]);
          if (m[2] != null) money(m[2]);
        }
      }
    }
  }

  static void pick(Map r) {
    final size = int.parse((r['game'] as String).substring(5));
    final digits = r['digits'];
    need(
      digits is List &&
          digits.length == size &&
          digits.every((v) => v is String && RegExp(r'^\d$').hasMatch(v)),
    );
    same(r['summaryColumns'], [
      'Play Type',
      if (size == 5) 'Statewide Winners',
      'Statewide Total',
    ]);
    final labels = size < 5
        ? ['Straight', 'Box', 'Straight/Box', 'Combo']
        : [
            'Straight',
            'Box',
            'Front 4',
            'Back 4',
            'Front 3',
            'Back 3',
            'Front 2',
            'Back 2',
          ];
    final rows = r['playTypes'];
    need(rows is List && rows.length == labels.length);
    for (var i = 0; i < labels.length; i++) {
      final row = rows[i];
      need(
        row['playType'] == labels[i] &&
            count(row['statewideTotalCents']) &&
            money(row['statewideTotalLabel']) == row['statewideTotalCents'],
      );
      if (size == 5) {
        need(count(row['statewideWinners']));
      } else {
        need(!row.containsKey('statewideWinners'));
      }
    }
    schedule(r['payoutSchedule'], size);
  }

  static void draw(Map r) {
    final game = r['game'];
    final local = game == 'Lotto' || game == 'Easy 5';
    final size = game == 'Lotto' ? 6 : 5;
    numbers(
      r['numbers'],
      size,
      {'Lotto': 42, 'Easy 5': 37, 'Powerball': 69, 'Mega Millions': 70}[game]!,
    );
    need(text(r['advertisedJackpot']));
    money(
      (r['advertisedJackpot'] as String).replaceFirst(
        RegExp(r'\s*\(ticket purchased\)$'),
        '',
      ),
    );
    final rows = r['tiers'];
    need(rows is List && rows.length == (local ? 4 : 9));
    if (local) {
      for (var i = 0; i < 4; i++) {
        final n = size - i, t = rows[i];
        need(
          t['match'] == '$n' &&
              t['sourceMatchLabel'] ==
                  '$game numbers: ${n > 2 ? '1 through $n' : '1 and 2'}' &&
              count(t['winners']),
        );
        if (i == 0) {
          need(t['prizeLabel'] == 'Jackpot');
        } else {
          money(t['prizeLabel']);
        }
      }
      return;
    }
    final pb = game == 'Powerball';
    number(r[pb ? 'powerball' : 'megaBall'], pb ? 26 : 24);
    if (pb) need(['2x', '3x', '4x', '5x', '10x'].contains(r['powerPlay']));
    if (!pb) {
      need((r['drawDate'] as String).compareTo('2025-04-08') >= 0);
      need(megaWarnings.every((r['sourceWarnings'] as List).contains));
    }
    final suffix = pb ? 'PB' : 'MB';
    final matches = [
      '5+$suffix',
      '5',
      '4+$suffix',
      '4',
      '3+$suffix',
      '3',
      '2+$suffix',
      '1+$suffix',
      '0+$suffix',
    ];
    final white = [5, 5, 4, 4, 3, 3, 2, 1, 0];
    for (var i = 0; i < 9; i++) {
      final t = rows[i], n = white[i];
      final ball = pb ? 'Powerball' : 'Megaplier';
      final prefix = pb ? 'Power Ball' : 'Mega Millions';
      final numbered = n > 2
          ? '1 through $n'
          : (n == 2 && pb ? '1 and 2' : '$n');
      final label = n == 0
          ? ball
          : '$numbered${matches[i].contains('+') ? ' plus $ball' : ''}';
      need(
        t['match'] == matches[i] &&
            t['sourceMatchLabel'] == '$prefix numbers: $label',
      );
      if (pb) {
        need(count(t['baseWinners']));
        if (i == 0) {
          need(
            t['basePrizeLabel'] == 'JACKPOT' &&
                t['powerPlayWinners'] == null &&
                t['powerPlayWinnersLabel'] == 'N/A' &&
                t['powerPlayPrizeLabel'] == 'N/A',
          );
        } else {
          money(t['basePrizeLabel']);
          money(t['powerPlayPrizeLabel']);
          need(
            count(t['powerPlayWinners']) &&
                t['powerPlayWinnersLabel'] is String &&
                RegExp(
                  r'^(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)$',
                ).hasMatch(t['powerPlayWinnersLabel']) &&
                int.parse(t['powerPlayWinnersLabel'].replaceAll(',', '')) ==
                    t['powerPlayWinners'],
          );
        }
      } else {
        final entries = t['multipliers'];
        need(entries is List && entries.length == 5);
        for (var j = 0; j < 5; j++) {
          final e = entries[j], m = [2, 3, 4, 5, 10][j];
          need(e['multiplier'] == m && count(e['winners']));
          if (i == 0) {
            need(e['prizeLabel'] == 'JACKPOT');
          } else if (i == 1) {
            need(
              e['prizeLabel'] ==
                  '\$$m'
                      'M',
            );
          } else {
            money(e['prizeLabel']);
          }
        }
      }
    }
  }

  static Map<String, dynamic> decode(String raw) {
    final d = jsonDecode(raw);
    need(
      d is Map<String, dynamic> &&
          d['schemaVersion'] == 1 &&
          d['state'] == 'LA' &&
          text(d['coverage']),
    );
    final retrieved = stamp(d['updatedAt']);
    final reports = d['reports'];
    need(reports is List && reports.length == 14);
    final groups = <String, Set<String>>{};
    for (final r in reports) {
      need(
        r is Map &&
            routes.containsKey(r['game']) &&
            text(r['coverage']) &&
            text(r['sourceUpdatedText']),
      );
      final g = r['game'] as String, date = r['drawDate'];
      final drawn = day(date);
      need(!drawn.isAfter(retrieved));
      final isPick = g.startsWith('Pick ');
      need(
        r['session'] == (isPick ? 'Daily' : 'Drawing') &&
            r['sourceUrl'] ==
                'https://louisianalottery.com/draw-games/${routes[g]}/#$date',
      );
      need(groups.putIfAbsent(g, () => <String>{}).add(date));
      strings(r['sourceWarnings'], empty: true);
      sourceTime(r);
      qualifications(r);
      if (isPick) {
        pick(r);
      } else {
        need(
          (g == 'Powerball'
                  ? [1, 3, 6]
                  : g == 'Mega Millions'
                  ? [2, 5]
                  : [3, 6])
              .contains(drawn.weekday),
        );
        draw(r);
      }
    }
    need(groups.length == 7 && groups.values.every((v) => v.length == 2));
    return d;
  }

  static void continuity(Map<String, dynamic> old, Map<String, dynamic> next) {
    need(
      !DateTime.parse(
        next['updatedAt'],
      ).isBefore(DateTime.parse(old['updatedAt'])),
    );
    for (final game in routes.keys) {
      List<String> dates(Map d) => [
        for (final r in d['reports'])
          if (r['game'] == game) r['drawDate'] as String,
      ]..sort();
      final a = dates(old), b = dates(next);
      need(
        a.length == 2 &&
            b.length == 2 &&
            b[0].compareTo(a[0]) >= 0 &&
            b[1].compareTo(a[1]) >= 0,
      );
    }
    final previous = {
      for (final r in old['reports']) '${r['game']}|${r['drawDate']}': r,
    };
    for (final r in next['reports']) {
      final p = previous['${r['game']}|${r['drawDate']}'];
      if (p != null) {
        need(
          !DateTime.parse(
            r['sourceUpdatedAt'],
          ).isBefore(DateTime.parse(p['sourceUpdatedAt'])),
        );
      }
    }
  }
}
