import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Loads validated Virginia tables without changing their source dates.
class VirginiaPrizeTablesLoader {
  VirginiaPrizeTablesLoader({
    this.readCache,
    this.writeCache,
    this.fetchRemote,
    this.readBundle,
  });
  static const cacheKey = 'virginia_draw_reports_v1';
  final Future<String?> Function()? readCache;
  final Future<void> Function(String)? writeCache;
  final Future<String> Function()? fetchRemote;
  final Future<String> Function()? readBundle;
  Map<String, dynamic> _decode(String raw) {
    final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    if (data['state'] != 'Virginia' ||
        data['schemaVersion'] != 1 ||
        DateTime.tryParse(data['retrievedAt'] as String) == null) {
      throw const FormatException('Wrong state or schema');
    }
    final reports = data['reports'] as List;
    const expected = {
      'powerball',
      'mega-millions',
      'millionaire-for-life',
      'bank-a-million',
      'cash-5',
      'pick-3',
      'pick-4',
      'pick-5',
      'cash-pop',
      'keno',
    };
    final games = reports.map((r) => r['game']).toSet();
    if (games.length != expected.length || !games.containsAll(expected)) {
      throw const FormatException('Incomplete game coverage');
    }
    final identities = <String>{};
    for (final r in reports) {
      final uri = Uri.parse(r['sourceUrl'] as String);
      if (uri.scheme != 'https' ||
          uri.host != 'www.valottery.com' ||
          DateTime.tryParse(r['drawDate'] as String) == null ||
          r['limitations'] is! String ||
          r['jurisdiction'] is! String ||
          r['gameName'] is! String ||
          r['tiers'] is! List) {
        throw const FormatException('Invalid provenance');
      }
      if (!identities.add(
        '${r['game']}/${r['drawDate']}/${r['session']}/${r['drawTime']}',
      )) {
        throw const FormatException('Duplicate report');
      }
      for (final key in ['totalWinners', 'totalShares', 'totalPayout']) {
        final value = r[key];
        if (value != null && (value is! int || value < 0)) {
          throw const FormatException('Invalid total');
        }
      }
      final game = r['game'];
      if ((game == 'powerball' || game == 'mega-millions') &&
          (r['jurisdiction'] == 'Virginia' || r['totalPayout'] != null)) {
        throw const FormatException('Unsupported national allocation');
      }
      if ((game == 'keno' ||
              game == 'cash-pop' ||
              game.toString().startsWith('pick-')) &&
          r['totalWinners'] != null) {
        throw const FormatException('Unsupported winner count');
      }
      if (game == 'keno' &&
          (r['countUnit'] != 'prize-winning shares' ||
              r['totalShares'] is! int)) {
        throw const FormatException('Invalid Keno units');
      }
      for (final tier in r['tiers'] as List) {
        if (tier['match'] is! String || tier['prizeDescription'] is! String) {
          throw const FormatException('Invalid tier');
        }
        final count = tier[game == 'keno' ? 'shareCount' : 'winnerCount'];
        if (count is! int || count < 0) {
          throw const FormatException('Invalid tier count');
        }
      }
      for (final component in (r['components'] as List? ?? [])) {
        if (component['name'] is! String ||
            component['payout'] is! int ||
            component['payout'] < 0) {
          throw const FormatException('Invalid payout component');
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
                'data/virginia_draw_reports.generated.json',
              )),
        );
  }

  Future<String> _fetch() async {
    final response = await http.get(
      Uri.parse(
        'https://apollohouser-cpu.github.io/lottery_atlas/virginia_draw_reports.json',
      ),
    );
    if (response.statusCode != 200) {
      throw StateError('Prize table HTTP ${response.statusCode}');
    }
    return response.body;
  }
}
