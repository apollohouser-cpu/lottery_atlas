import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MissouriDrawReportsLoader {
  MissouriDrawReportsLoader({
    this.readCache,
    this.writeCache,
    this.fetchRemote,
    this.readBundle,
  });
  static const cacheKey = 'missouri_draw_reports_v1';
  final Future<String?> Function()? readCache;
  final Future<void> Function(String)? writeCache;
  final Future<String> Function()? fetchRemote;
  final Future<String> Function()? readBundle;
  static const games = {
    'powerball': 'Powerball',
    'powerballxo': 'Powerball Xs & Os',
    'mega-millions': 'Mega Millions',
    'mo-millions': 'MO Millions',
    'show-me-cash': 'Show Me Cash',
    'pick3': 'Pick 3',
    'pick4': 'Pick 4',
    'cash-pop': 'Cash Pop',
  };
  static List<String> sessions(String f) => f.startsWith('pick')
      ? ['Midday', 'Evening']
      : f == 'cash-pop'
      ? ['1', '2', '3', '4', '5']
      : ['draw'];
  static void require(bool v) {
    if (!v) throw const FormatException('Invalid Missouri report');
  }

  static bool count(dynamic v) => v is int && v >= 0 && v <= 9007199254740991;
  static int cents(String label) {
    require(
      RegExp(
        r'^\$(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)(?:\.\d{1,2})?$',
      ).hasMatch(label),
    );
    final parts = label.substring(1).replaceAll(',', '').split('.');
    return int.parse(parts[0]) * 100 +
        (parts.length == 2 ? int.parse(parts[1].padRight(2, '0')) : 0);
  }

  Map<String, dynamic> _decode(String raw) {
    final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    require(
      data['stateCode'] == 'MO' &&
          DateTime.tryParse(data['updatedAt'] as String) != null &&
          data['coverage'] is String,
    );
    final reports = data['reports'] as List;
    require(reports.length == 28);
    final groups = <String, List<String>>{};
    for (final r in reports) {
      final f = r['family'] as String,
          s = r['sessionKey'] as String,
          day = r['drawDate'] as String;
      require(games[f] == r['game'] && sessions(f).contains(s));
      require(
        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day) &&
            DateTime.tryParse(day)?.toIso8601String().substring(0, 10) == day,
      );
      require(
        r['distinctTicketCount'] == null &&
            r['finalityVerified'] == false &&
            r['coverage'] is String,
      );
      final dates = groups.putIfAbsent('$f/$s', () => []);
      require(!dates.contains(day));
      dates.add(day);
      final u = Uri.parse(r['sourceUrl'] as String);
      require(
        u.scheme == 'https' &&
            u.host == 'www.molottery.com' &&
            u.path == '/$f/prizes-paid.do' &&
            u.queryParameters['date'] == day &&
            u.userInfo.isEmpty &&
            !u.hasFragment,
      );
      final key = f.startsWith('pick')
          ? 'time'
          : f == 'cash-pop'
          ? 'type'
          : null;
      require(
        u.queryParameters.length == (key == null ? 1 : 2) &&
            (key == null || u.queryParameters[key] == s),
      );
      require(u.queryParametersAll.values.every((v) => v.length == 1));
      if (f.startsWith('pick')) {
        require(r['sessionLabel'] == s && r['playBasisCents'] == 50);
      }
      if (f == 'cash-pop') {
        require(
          r['sessionId'].toString() == s &&
              r['sessionLabel'] ==
                  [
                    'Early Bird',
                    'Late Morning',
                    'Matinee',
                    'Prime Time',
                    'Night Owl',
                  ][int.parse(s) - 1],
        );
      }
      final variants = r['variants'] as List?;
      final expected = f == 'powerball'
          ? ['Base without Power Play', 'With Power Play', 'Double Play']
          : f == 'mo-millions'
          ? ['Main', 'Double Play']
          : f.startsWith('pick')
          ? [r['game'], '${r['game']} + Wild ball']
          : null;
      require(
        expected == null
            ? variants == null
            : variants != null && variants.length == expected.length,
      );
      if (expected != null) {
        for (var i = 0; i < expected.length; i++) {
          require(variants![i]['variant'] == expected[i]);
        }
      }
      var allCount = 0, allCents = 0;
      final tables = variants ?? [r];
      for (var index = 0; index < tables.length; index++) {
        final v = tables[index];
        final tiers = v['tiers'] as List;
        final n = f == 'powerball' || f == 'mega-millions'
            ? 9
            : f == 'mo-millions'
            ? 8
            : f == 'powerballxo' || f == 'pick3'
            ? 5
            : f == 'show-me-cash'
            ? 4
            : f == 'pick4'
            ? 10
            : 22;
        require(tiers.length == n);
        var total = 0, payout = 0;
        final labels = <String>{};
        for (var i = 0; i < tiers.length; i++) {
          final t = tiers[i];
          require(t['cashPrize'] == null && t['prizeLabel'] is String);
          require(
            f == 'cash-pop'
                ? t['matchLabel'] == null
                : t['matchLabel'] is String && labels.add(t['matchLabel']),
          );
          final unavailable = f == 'powerball' && index == 1 && i == 0;
          if (unavailable) {
            require(
              t['sourcePrizeCount'] == null &&
                  t['sourceAmount'] == null &&
                  t['prizeLabel'] == '-',
            );
            continue;
          }
          require(count(t['sourcePrizeCount']));
          final c = t['sourcePrizeCount'] as int;
          total += c;
          final jackpot =
              (f == 'powerball' && index == 0 && i == 0) ||
              (f == 'mega-millions' && i == 0);
          if (jackpot) {
            require(t['prizeLabel'] == 'Jackpot');
            continue;
          }
          if (f == 'mega-millions') {
            final bounds = (t['prizeLabel'] as String).split('-');
            require(
              bounds.length == 2 &&
                  cents(bounds[0]) > 0 &&
                  cents(bounds[1]) > cents(bounds[0]),
            );
            continue;
          }
          final amount = cents(t['prizeLabel']);
          require(
            f.startsWith('pick')
                ? t['sourceAmountCents'] == amount
                : count(t['sourceAmount']) && t['sourceAmount'] * 100 == amount,
          );
          require(amount > 0 || i == 0 && c == 0);
          payout += amount * c;
        }
        if (!f.startsWith('pick')) {
          require(
            count(v['sourceWinnerCount']) &&
                v['sourceWinnerCount'] == total &&
                count(v['sourcePayoutDollars']),
          );
          if (f != 'mega-millions') {
            require(
              f == 'powerball' && index == 0 && tiers[0]['sourcePrizeCount'] > 0
                  ? v['sourcePayoutDollars'] * 100 >= payout
                  : v['sourcePayoutDollars'] * 100 == payout,
            );
          }
        }
        allCount += total;
        allCents += payout;
      }
      if (f.startsWith('pick')) {
        require(
          r['sourceWinnerCount'] == allCount &&
              r['sourcePayoutCents'] == allCents &&
              cents(r['sourcePayoutLabel']) == allCents,
        );
      }
      if (f == 'mega-millions') {
        final tiers = r['tiers'] as List;
        if (tiers[0]['sourcePrizeCount'] == 0) {
          var low = 0, high = 0;
          for (final t in tiers.skip(1)) {
            final bounds = (t['prizeLabel'] as String).split('-');
            low += cents(bounds[0]) * (t['sourcePrizeCount'] as int);
            high += cents(bounds[1]) * (t['sourcePrizeCount'] as int);
          }
          require(
            r['sourcePayoutDollars'] * 100 >= low &&
                r['sourcePayoutDollars'] * 100 <= high,
          );
        }
      }
      if (f == 'powerball') {
        require([2, 3, 4, 5, 10].contains(r['powerPlayMultiplier']));
        require(
          r['mainSourceWinnerCount'] ==
                  variants![0]['sourceWinnerCount'] +
                      variants[1]['sourceWinnerCount'] &&
              r['mainSourcePayoutDollars'] ==
                  variants[0]['sourcePayoutDollars'] +
                      variants[1]['sourcePayoutDollars'],
        );
      }
    }
    for (final f in games.keys) {
      for (final s in sessions(f)) {
        require(groups['$f/$s']?.length == 2);
      }
    }
    return data;
  }

  void _checkContinuity(Map<String, dynamic> old, Map<String, dynamic> next) {
    require(
      !DateTime.parse(
        next['updatedAt'],
      ).isBefore(DateTime.parse(old['updatedAt'])),
    );
    for (final f in games.keys) {
      for (final s in sessions(f)) {
        List<String> dates(Map<String, dynamic> d) =>
            (d['reports'] as List)
                .where((r) => r['family'] == f && r['sessionKey'] == s)
                .map((r) => r['drawDate'] as String)
                .toList()
              ..sort();
        final a = dates(old), b = dates(next);
        for (var i = 0; i < 2; i++) {
          require(b[i].compareTo(a[i]) >= 0);
        }
      }
    }
  }

  Future<Map<String, dynamic>> load() async {
    late final prefs = SharedPreferencesAsync();
    Map<String, dynamic>? cached;
    try {
      final raw = await (readCache?.call() ?? prefs.getString(cacheKey));
      if (raw != null) cached = _decode(raw);
    } catch (_) {}
    try {
      final raw = await (fetchRemote?.call() ?? _fetch()).timeout(
        const Duration(seconds: 8),
      );
      final data = _decode(raw);
      if (cached != null) _checkContinuity(cached, data);
      // Persistence failure must not discard a valid response.
      try {
        if (writeCache != null) {
          await writeCache!(raw);
        } else {
          await prefs.setString(cacheKey, raw);
        }
      } catch (_) {}
      return data;
    } catch (_) {}
    return cached ??
        _decode(
          await (readBundle?.call() ??
              rootBundle.loadString(
                'data/missouri_draw_reports.generated.json',
              )),
        );
  }

  Future<String> _fetch() async {
    final response = await http.get(
      Uri.parse(
        'https://apollohouser-cpu.github.io/lottery_atlas/missouri_draw_reports.json',
      ),
    );
    if (response.statusCode != 200) {
      throw StateError('Prize table HTTP ${response.statusCode}');
    }
    return response.body;
  }
}
