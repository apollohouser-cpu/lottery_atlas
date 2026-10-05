import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Loads validated Colorado draw reports without changing their source dates.
class ColoradoDrawReportsLoader {
  ColoradoDrawReportsLoader({
    this.readCache,
    this.writeCache,
    this.fetchRemote,
    this.readBundle,
  });
  static const cacheKey = 'colorado_draw_reports_v1';
  final Future<String?> Function()? readCache;
  final Future<void> Function(String)? writeCache;
  final Future<String> Function()? fetchRemote;
  final Future<String> Function()? readBundle;
  Map<String, dynamic> _decode(String raw) {
    final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    void require(bool valid) {
      if (!valid) throw const FormatException('Invalid Colorado payout report');
    }

    require(
      data['state'] == 'Colorado' &&
          data['schemaVersion'] == 1 &&
          DateTime.tryParse(data['retrievedAt'] as String) != null &&
          data['cadence'] is String &&
          data['coverage'] is String,
    );
    const games = {
      'Powerball': 26,
      'Mega Millions': 41,
      'Millionaire for Life': 9,
      'Colorado Lotto+': 26,
      'Cash 5': 4,
      'Pick 3': 24,
    };
    final reports = data['reports'] as List;
    final counts = <String, int>{};
    final sessions = <String>{};
    final ids = <String>{};
    final slots = <String>{};
    require(reports.length == 12);
    for (final row in reports) {
      final game = row['game'] as String;
      final date = row['drawDate'] as String;
      final session = row['drawingSession'] as String?;
      require(games.containsKey(game) && ids.add(row['id'] as String));
      require(
        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) &&
            DateTime.tryParse(date)?.toIso8601String().substring(0, 10) == date,
      );
      require(
        game == 'Pick 3'
            ? {'Midday', 'Evening'}.contains(session)
            : session == null,
      );
      if (session != null) sessions.add(session);
      require(slots.add('$game/$date/$session'));
      final source = Uri.parse(row['sourceUrl'] as String);
      const paths = {
        'Powerball': 'powerball',
        'Mega Millions': 'megamillions',
        'Millionaire for Life': 'millionaireforlife',
        'Colorado Lotto+': 'lotto',
        'Cash 5': 'cash5',
        'Pick 3': 'pick3',
      };
      final suffix = game == 'Pick 3'
          ? ':${session == 'Midday' ? 'MD' : 'EV'}'
          : '';
      require(
        source.scheme == 'https' &&
            source.host == 'www.coloradolottery.com' &&
            source.path == '/en/games/${paths[game]}/drawings/$date$suffix/' &&
            !source.hasQuery &&
            !source.hasFragment,
      );
      require(row['limitations'] is String && row['prizeNotes'] is List);
      final tiers = row['tiers'] as List;
      require(tiers.length == games[game]);
      final tierIds = <String>{};
      var unavailable = 0;
      for (final tier in tiers) {
        require(
          tier['match'] is String &&
              tier['variant'] is String &&
              tierIds.add(
                '${tier['variant']}/${tier['match']}/${tier['wagerDollars']}',
              ),
        );
        final count = tier['reportedWinners'];
        if (game == 'Pick 3') {
          require(
            {0.5, 1, 2, 5}.contains(tier['wagerDollars']) &&
                tier['available'] is bool,
          );
        }
        if (tier['available'] == false) {
          unavailable++;
          require(
            game == 'Pick 3' &&
                tier['wagerDollars'] == 0.5 &&
                {
                  'Combined Exact Order',
                  'Combined Any Order',
                }.contains(tier['match']) &&
                count == null &&
                tier['prizeLabel'] == null,
          );
        } else {
          require(
            count is int &&
                count >= 0 &&
                tier['prizeLabel'] is String &&
                (tier['prizeLabel'] as String).isNotEmpty,
          );
        }
      }
      require(unavailable == (game == 'Pick 3' ? 2 : 0));
      if (game == 'Powerball') {
        require({2, 3, 4, 5, 10}.contains(row['powerPlayMultiplier']));
      }
      if (game == 'Millionaire for Life') {
        require(
          tiers[0]['prizeLabel'] == r'$1,000,000 a year for life*' &&
              tiers[1]['prizeLabel'] == r'$100,000 a year for life**',
        );
        require(
          (row['prizeNotes'] as List).contains(
                '*Divided by the number of winners',
              ) &&
              (row['prizeNotes'] as List).contains(
                '**If 21+ total winners, divided by the number of winners',
              ),
        );
      }
      if (game == 'Cash 5') {
        final ez = row['ezMatch'] as Map;
        require(
          ez['date'] == date &&
              ez['reportedPlayers'] is int &&
              ez['reportedPlayers'] >= 0 &&
              ez['publishedPayoutDollars'] is int &&
              ez['publishedPayoutDollars'] >= 0 &&
              ez['periodLabel'] == '4:30 AM–11:59 PM on draw date',
        );
      } else {
        require(row['ezMatch'] == null);
      }
      counts[game] = (counts[game] ?? 0) + 1;
    }
    require(games.keys.every((g) => counts[g] == 2) && sessions.length == 2);
    return data;
  }

  void _checkContinuity(
    Map<String, dynamic> previous,
    Map<String, dynamic> next,
  ) {
    for (final old in previous['reports'] as List) {
      final newer = (next['reports'] as List).where(
        (r) =>
            r['game'] == old['game'] &&
            r['drawingSession'] == old['drawingSession'],
      );
      if (!newer.any(
        (r) => (r['drawDate'] as String).compareTo(old['drawDate']) >= 0,
      )) {
        throw const FormatException('Colorado payout date regression');
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
                'data/colorado_draw_reports.generated.json',
              )),
        );
  }

  Future<String> _fetch() async {
    final response = await http.get(
      Uri.parse(
        'https://apollohouser-cpu.github.io/lottery_atlas/colorado_draw_reports.json',
      ),
    );
    if (response.statusCode != 200) {
      throw StateError('Prize table HTTP ${response.statusCode}');
    }
    return response.body;
  }
}
