import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Loads validated NewYork tables without changing their source dates.
class NewYorkPrizeTablesLoader {
  NewYorkPrizeTablesLoader({
    this.readCache,
    this.writeCache,
    this.fetchRemote,
    this.readBundle,
  });
  static const cacheKey = 'new_york_draw_reports_v1';
  final Future<String?> Function()? readCache;
  final Future<void> Function(String)? writeCache;
  final Future<String> Function()? fetchRemote;
  final Future<String> Function()? readBundle;
  Map<String, dynamic> _decode(String raw) {
    final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    if (data['state'] != 'New York' ||
        data['schemaVersion'] != 1 ||
        DateTime.tryParse(data['retrievedAt'] as String) == null) {
      throw const FormatException('Wrong state or schema');
    }
    const shapes = <String, Map<String, int>>{
      'Powerball': {'Base': 9, 'Power Play': 8, 'Double Play': 9},
      'Mega Millions': {
        'Jackpot': 1,
        'Built-in 2X': 8,
        'Built-in 3X': 8,
        'Built-in 4X': 8,
        'Built-in 5X': 8,
        'Built-in 10X': 8,
      },
      'LOTTO': {'Base': 5},
      'Take 5': {'Base': 4},
      'NUMBERS': {'Base': 6},
      'Win4': {'Base': 5},
      'Pick 10': {'Base': 6},
      'Millionaire For Life': {'Base': 9},
      'Quick Draw / Money Dots': {'Quick Draw': 0, 'Money Dots': 0},
    };
    bool nonnegative(dynamic n) => n is int && n >= 0;
    void require(bool valid) {
      if (!valid) throw const FormatException('Invalid NY report');
    }

    bool official(dynamic value) {
      final uri = Uri.tryParse(value.toString());
      return uri?.scheme == 'https' && uri?.host == 'nylottery.ny.gov';
    }

    final reports = data['reports'] as List;
    final games = reports.map((r) => r['gameName']).toSet();
    require(games.length == shapes.length && games.containsAll(shapes.keys));
    require(data['cadence'] is String);
    for (final source in data['additionalSources'] as List) {
      require(official(source['sourceUrl']) && source['limitations'] is String);
    }
    final identities = <String>{};
    for (final r in reports) {
      final game = r['gameName'] as String;
      final shares = game == 'NUMBERS' || game == 'Win4';
      final dollars = game == 'Quick Draw / Money Dots';
      final date = r['drawDate'] as String;
      require(
        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) &&
            DateTime.tryParse(date)?.toIso8601String().substring(0, 10) == date,
      );
      require(
        official(r['sourceUrl']) &&
            r['jurisdiction'] == 'New York' &&
            r['limitation'] is String &&
            r['drawNumber'] is String,
      );
      require(
        r['countUnit'] ==
            (shares
                ? 'NY winning shares based on \$1 and \$0.50 wagers; not distinct tickets'
                : dollars
                ? 'Winner and ticket counts unavailable'
                : 'Source-reported NY winners; distinct tickets not established'),
      );
      require(
        identities.add('$game/$date/${r['drawingSession']}/${r['drawNumber']}'),
      );
      if (shares || game == 'Pick 10') {
        require(nonnegative(r['reportedTotalPrizes']));
      }
      final tables = r['tables'] as List;
      final expected = shapes[game]!;
      require(tables.length == expected.length);
      final variants = <String>{};
      for (final table in tables) {
        final variant = table['variant'] as String;
        require(variants.add(variant) && expected.containsKey(variant));
        final tiers = table['tiers'] as List;
        require(tiers.length == expected[variant]);
        if (dollars) {
          require(
            table['reportedWinners'] == null &&
                nonnegative(table['reportedTotalPrizes']),
          );
        }
        final tierIds = <String>{};
        for (final tier in tiers) {
          require(tier['tier'] is String && tierIds.add(tier['tier']));
          if (shares) {
            require(
              tier['reportedWinners'] == null &&
                  nonnegative(tier['reportedShares']) &&
                  tier['prizeLabel'] == null,
            );
          } else {
            require(nonnegative(tier['reportedWinners']));
            require(
              game == 'Pick 10'
                  ? tier['prizeLabel'] == null
                  : tier['prizeLabel'] is String,
            );
          }
        }
      }
    }
    return data;
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
                'data/new_york_draw_reports.generated.json',
              )),
        );
  }

  Future<String> _fetch() async {
    final response = await http.get(
      Uri.parse(
        'https://apollohouser-cpu.github.io/lottery_atlas/new_york_draw_reports.json',
      ),
    );
    if (response.statusCode != 200) {
      throw StateError('Prize table HTTP ${response.statusCode}');
    }
    return response.body;
  }
}
