import 'dart:convert';
import 'louisiana_draw_reports_validator.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class SouthDakotaScratchCatalogLoader {
  SouthDakotaScratchCatalogLoader({
    this.readCache,
    this.writeCache,
    this.fetchRemote,
    this.readBundle,
  });
  static const cacheKey = 'south_dakota_scratch_catalog_v1';
  final Future<String?> Function()? readCache;
  final Future<void> Function(String)? writeCache;
  final Future<String> Function()? fetchRemote;
  final Future<String> Function()? readBundle;

  static void need(bool v) => LouisianaDrawReportsValidator.need(v);
  static bool text(dynamic v) => LouisianaDrawReportsValidator.text(v);
  static bool count(dynamic v) => LouisianaDrawReportsValidator.count(v);
  static DateTime stamp(dynamic v) => LouisianaDrawReportsValidator.stamp(v);

  static Map<String, dynamic> decode(String raw) {
    final root = jsonDecode(raw) as Map<String, dynamic>;
    stamp(root['updatedAt']);
    final catalogs = root['catalogs'] as List;
    final matches = catalogs
        .where((c) => c['state'] == 'South Dakota')
        .toList();
    need(matches.length == 1);
    final c = matches.single as Map;
    need(
      c['source'] == 'https://lottery.sd.gov/scratch-games/' &&
          c['sourceDate'] == null &&
          text(c['coverage']) &&
          text(c['updateCadence']) &&
          count(c['publishedListingCount']),
    );
    need(
      (c['coverage'] as String).contains(
            'completeness/pagination unconfirmed',
          ) &&
          (c['coverage'] as String).contains(
            'not dated claims or retailer activity',
          ),
    );
    final games = c['games'] as List;
    need(games.length >= 20 && games.length <= c['publishedListingCount']);
    final ids = <String>{};
    for (final g in games) {
      final id = g['id'];
      need(
        g['stateName'] == 'South Dakota' &&
            id is String &&
            RegExp(r'^[1-9]\d*$').hasMatch(id) &&
            ids.add(id) &&
            text(g['name']) &&
            count(g['cost']) &&
            g['cost'] > 0 &&
            text(g['inventoryNote']),
      );
      need(
        (g['inventoryNote'] as String).contains('Cumulative counts') &&
            (g['inventoryNote'] as String).contains(
              'store availability unknown',
            ),
      );
      final url = Uri.parse(g['sourceUrl'] as String);
      need(
        url.scheme == 'https' &&
            url.host == 'lottery.sd.gov' &&
            url.userInfo.isEmpty &&
            !url.hasPort &&
            !url.hasQuery &&
            !url.hasFragment &&
            RegExp(r'^/game/[a-z0-9-]+/$').hasMatch(url.path),
      );
      need(
        g['inventorySource'] ==
            'https://lottery.sd.gov/api/igt/games/v1/instant-games/games/$id',
      );
      final tiers = g['prizeTiers'] as List;
      need(tiers.isNotEmpty && tiers.length <= 100);
      final numbers = <int>{};
      Map? top;
      for (final t in tiers) {
        final amount = t['prizeAmount'];
        need(
          count(t['tierNumber']) &&
              t['tierNumber'] > 0 &&
              numbers.add(t['tierNumber']) &&
              amount is num &&
              amount.isFinite &&
              amount > 0 &&
              count(t['winningTickets']) &&
              count(t['paidTickets']) &&
              count(t['remaining']) &&
              t['winningTickets'] - t['paidTickets'] == t['remaining'],
        );
        if (top == null || amount > top['prizeAmount']) top = t;
      }
      need(
        top != null &&
            g['topPrize'] == top['prizeAmount'] &&
            count(g['topPrizesRemaining']) &&
            g['topPrizesRemaining'] == top['remaining'],
      );
    }
    return {
      'source': root['source'],
      'updatedAt': root['updatedAt'],
      'catalogs': [c],
    };
  }

  static void continuity(Map<String, dynamic> old, Map<String, dynamic> next) {
    need(!stamp(next['updatedAt']).isBefore(stamp(old['updatedAt'])));
    final a = old['catalogs'][0], b = next['catalogs'][0];

    final previous = {for (final g in a['games']) g['id']: g};
    need(b['games'].length >= previous.length * .9);
    for (final g in b['games']) {
      final p = previous[g['id']];
      if (p == null) continue;
      need(
        [
          'name',
          'cost',
          'sourceUrl',
          'inventorySource',
        ].every((k) => g[k] == p[k]),
      );
      final oldTiers = {for (final t in p['prizeTiers']) t['tierNumber']: t};
      need(g['prizeTiers'].length == oldTiers.length);
      for (final t in g['prizeTiers']) {
        final prior = oldTiers[t['tierNumber']];
        need(
          prior != null &&
              prior['prizeAmount'] == t['prizeAmount'] &&
              prior['winningTickets'] == t['winningTickets'],
        );
      }
    }
  }

  Map<String, dynamic> _decode(String raw) => decode(raw);
  void _checkContinuity(Map<String, dynamic> old, Map<String, dynamic> next) =>
      continuity(old, next);

  Future<Map<String, dynamic>> load() async {
    late final prefs = SharedPreferencesAsync();
    Map<String, dynamic>? cached;
    try {
      final raw = await (readCache?.call() ?? prefs.getString(cacheKey));
      if (raw != null) cached = _decode(raw);
    } catch (_) {}
    if (cached == null) {
      try {
        cached = _decode(
          await (readBundle?.call() ??
              rootBundle.loadString(
                'data/south_dakota_scratch_catalog.generated.json',
              )),
        );
      } catch (_) {}
    }
    try {
      final raw = await (fetchRemote?.call() ?? _fetch()).timeout(
        const Duration(seconds: 8),
      );
      final data = _decode(raw);
      if (cached != null) _checkContinuity(cached, data);
      // Persistence failure must not discard a valid response.
      try {
        if (writeCache != null) {
          await writeCache!(jsonEncode(data));
        } else {
          await prefs.setString(cacheKey, jsonEncode(data));
        }
      } catch (_) {}
      return data;
    } catch (_) {}
    return cached ??
        _decode(
          await (readBundle?.call() ??
              rootBundle.loadString(
                'data/south_dakota_scratch_catalog.generated.json',
              )),
        );
  }

  Future<String> _fetch() async {
    final response = await http.get(
      Uri.parse(
        'https://apollohouser-cpu.github.io/lottery_atlas/state_scratch_catalogs.json',
      ),
    );
    if (response.statusCode != 200) {
      throw StateError('Reports HTTP ${response.statusCode}');
    }
    return response.body;
  }
}
