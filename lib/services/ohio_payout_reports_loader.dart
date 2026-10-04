import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Loads validated Ohio payout reports without changing their source dates.
class OhioPayoutReportsLoader {
  OhioPayoutReportsLoader({
    this.readCache,
    this.writeCache,
    this.fetchRemote,
    this.readBundle,
  });
  static const cacheKey = 'ohio_draw_reports_v1';
  final Future<String?> Function()? readCache;
  final Future<void> Function(String)? writeCache;
  final Future<String> Function()? fetchRemote;
  final Future<String> Function()? readBundle;
  Map<String, dynamic> _decode(String raw) {
    final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    void require(bool valid) {
      if (!valid) throw const FormatException('Invalid Ohio payout report');
    }

    require(
      data['state'] == 'Ohio' &&
          data['schemaVersion'] == 1 &&
          DateTime.tryParse(data['retrievedAt'] as String) != null &&
          data['cadence'] is String &&
          data['coverage'] is String,
    );
    const games = {
      'Pick 3',
      'Pick 4',
      'Pick 5',
      'Classic Lotto',
      'Rolling Cash 5',
    };
    final reports = data['reports'] as List;
    final counts = <String, int>{};
    final sessions = <String, Set<String?>>{};
    final ids = <String>{};
    final slots = <String>{};
    for (final row in reports) {
      final game = row['game'] as String;
      final date = row['drawDate'] as String;
      final session = row['drawingSession'] as String?;
      final amount = row['publishedPayoutDollars'];
      final source = Uri.tryParse(row['sourceUrl'] as String);
      require(games.contains(game) && ids.add(row['id'] as String));
      require(
        RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(date) &&
            DateTime.tryParse(date)?.toIso8601String().substring(0, 10) == date,
      );
      require(
        game.startsWith('Pick')
            ? {'Midday', 'Evening'}.contains(session)
            : session == null,
      );
      require(slots.add('$game/$date/$session'));
      require(
        amount is num &&
            amount.isFinite &&
            amount >= 0 &&
            row.containsKey('winningTickets') &&
            row['winningTickets'] == null,
      );
      require(
        row['drawNumber'] is String &&
            (int.tryParse(row['drawNumber']) ?? 0) > 0 &&
            row['limitations'] is String,
      );
      require(
        source?.scheme == 'https' && source?.host == 'www.ohiolottery.com',
      );
      counts[game] = (counts[game] ?? 0) + 1;
      (sessions[game] ??= {}).add(session);
    }
    require(games.every((g) => (counts[g] ?? 0) >= 2));
    require(
      ['Pick 3', 'Pick 4', 'Pick 5'].every((g) => sessions[g]!.length == 2),
    );
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
        (r) =>
            (r['drawDate'] as String).compareTo(old['drawDate']) >= 0 &&
            int.parse(r['drawNumber']) >= int.parse(old['drawNumber']),
      )) {
        throw const FormatException('Ohio payout date/draw regression');
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
              rootBundle.loadString('data/ohio_draw_reports.generated.json')),
        );
  }

  Future<String> _fetch() async {
    final response = await http.get(
      Uri.parse(
        'https://apollohouser-cpu.github.io/lottery_atlas/ohio_draw_reports.json',
      ),
    );
    if (response.statusCode != 200) {
      throw StateError('Prize table HTTP ${response.statusCode}');
    }
    return response.body;
  }
}
