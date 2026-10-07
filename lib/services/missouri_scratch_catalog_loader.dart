import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class MissouriScratchCatalogLoader {
  MissouriScratchCatalogLoader({
    this.readCache,
    this.writeCache,
    this.fetchRemote,
    this.readBundle,
  });
  static const cacheKey = 'missouri_scratch_catalog_v1';
  final Future<String?> Function()? readCache;
  final Future<void> Function(String)? writeCache;
  final Future<String> Function()? fetchRemote;
  final Future<String> Function()? readBundle;

  static void require(bool value) {
    if (!value) throw const FormatException('Invalid Missouri inventory');
  }

  static bool text(dynamic v) => v is String && v.trim().isNotEmpty;
  static bool count(dynamic v) => v is int && v >= 0 && v <= 9007199254740991;
  static bool day(dynamic v) =>
      v is String &&
      RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v) &&
      DateTime.tryParse(v)?.toIso8601String().substring(0, 10) == v;
  static int amount(dynamic v) {
    require(
      v is String &&
          RegExp(r'^\$(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)$').hasMatch(v),
    );
    return int.parse((v as String).substring(1).replaceAll(',', ''));
  }

  Map<String, dynamic> _decode(String raw) {
    final d = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    require(
      d['stateCode'] == 'MO' &&
          d['sourceDate'] == null &&
          d['sourceUrl'] == 'https://www.molottery.com/scratchers-list.do' &&
          d['updatedAt'] is String &&
          DateTime.tryParse(d['updatedAt']) != null &&
          text(d['coverage']) &&
          text(d['updateCadence']),
    );
    final games = d['games'] as List;
    // Observed-scale anomaly guard, not statewide completeness certification.
    require(games.length >= 50 && games.length <= 1000);
    final ids = <String>{};
    for (final g in games) {
      final id = g['id'] as String;
      require(
        RegExp(r'^[1-9]\d*$').hasMatch(id) &&
            ids.add(id) &&
            text(g['name']) &&
            count(g['ticketPrice']) &&
            g['ticketPrice'] > 0 &&
            day(g['startDate']) &&
            (g['endDate'] == null ||
                (day(g['endDate']) &&
                    (g['endDate'] as String).compareTo(g['startDate']) >= 0)) &&
            g['sourceDate'] == null &&
            text(g['coverage']),
      );
      final u = Uri.parse(g['sourceUrl'] as String);
      require(
        u.scheme == 'https' &&
            u.host == 'www.molottery.com' &&
            u.path == '/scratchers.do' &&
            u.userInfo.isEmpty &&
            !u.hasFragment &&
            !u.hasPort &&
            u.queryParameters.length == 2 &&
            u.queryParameters['method'] == 'd' &&
            u.queryParameters['game'] == id &&
            u.queryParametersAll.values.every((v) => v.length == 1),
      );
      final tiers = g['prizeTiers'] as List;
      require(tiers.isNotEmpty && tiers.length <= 100);
      final amounts = <int>{};
      for (final t in tiers) {
        final a = amount(t['prizeLabel']);
        require(
          a > 0 &&
              amounts.add(a) &&
              count(t['advertisedAmount']) &&
              a == t['advertisedAmount'] &&
              count(t['totalPrizes']) &&
              count(t['unclaimedPrizes']) &&
              t['unclaimedPrizes'] <= t['totalPrizes'],
        );
      }
      require(
        amount(g['advertisedTopPrize']) ==
            amounts.reduce((a, b) => a > b ? a : b),
      );
    }
    return d;
  }

  void _checkContinuity(Map<String, dynamic> old, Map<String, dynamic> next) {
    require(
      !DateTime.parse(
        next['updatedAt'],
      ).isBefore(DateTime.parse(old['updatedAt'])),
    );
    final games = next['games'] as List, previous = old['games'] as List;
    require(games.length >= previous.length * .9);
    final byId = {for (final g in previous) g['id']: g};
    for (final g in games) {
      final p = byId[g['id']];
      if (p != null) {
        require(
          ['name', 'ticketPrice', 'startDate'].every((k) => p[k] == g[k]),
        );
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
                'data/missouri_scratch_catalog.generated.json',
              )),
        );
  }

  Future<String> _fetch() async {
    final response = await http.get(
      Uri.parse(
        'https://apollohouser-cpu.github.io/lottery_atlas/missouri_scratch_catalog.json',
      ),
    );
    if (response.statusCode != 200) {
      throw StateError('Catalog HTTP ${response.statusCode}');
    }
    return response.body;
  }
}
