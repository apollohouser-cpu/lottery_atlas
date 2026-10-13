import 'dart:convert';
import 'louisiana_draw_reports_validator.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class LouisianaScratchCatalogLoader {
  LouisianaScratchCatalogLoader({
    this.readCache,
    this.writeCache,
    this.fetchRemote,
    this.readBundle,
  });
  static const cacheKey = 'louisiana_scratch_catalog_v1';
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
    final matches = catalogs.where((c) => c['state'] == 'Louisiana').toList();
    need(matches.length == 1);
    final c = matches.single as Map;
    need(
      c['source'] == 'https://louisianalottery.com/top-prizes-remaining/' &&
          text(c['coverage']) &&
          text(c['updateCadence']),
    );
    LouisianaDrawReportsValidator.day(c['sourceDate']);
    stamp(c['reportTimestamp']);
    need((c['reportTimestamp'] as String).substring(0, 10) == c['sourceDate']);
    final games = c['games'] as List;
    // Scale anomaly guard, not a claim of statewide catalog completeness.
    need(games.length >= 20 && games.length <= 500);
    final ids = <String>{};
    for (final g in games) {
      final id = g['id'];
      need(
        g['stateName'] == 'Louisiana' &&
            id is String &&
            RegExp(r'^[1-9]\d*$').hasMatch(id) &&
            ids.add(id) &&
            text(g['name']) &&
            count(g['cost']) &&
            g['cost'] > 0 &&
            text(g['inventoryNote']),
      );
      final start = LouisianaDrawReportsValidator.day(g['startDate']);
      final source = stamp(g['sourceTimestamp']);
      need(!start.isAfter(source));
      final url = Uri.parse(g['sourceUrl'] as String);
      need(
        url.scheme == 'https' &&
            url.host == 'louisianalottery.com' &&
            url.userInfo.isEmpty &&
            !url.hasPort &&
            !url.hasQuery &&
            !url.hasFragment &&
            RegExp('^/game/$id-[a-z0-9-]+/\$').hasMatch(url.path),
      );
      final tiers = g['prizeTiers'] as List;
      need(tiers.isNotEmpty && tiers.length <= 100);
      final labels = <String>{};
      Map? top;
      for (final t in tiers) {
        need(
          text(t['prizeLabel']) &&
              labels.add(t['prizeLabel']) &&
              count(t['total']) &&
              count(t['claimed']) &&
              count(t['remaining']) &&
              t['claimed'] + t['remaining'] == t['total'],
        );
        final odds = t['publishedOdds'];
        need(
          odds is String &&
              RegExp(r'^1 in [0-9,]+(?:\.[0-9]+)?$').hasMatch(odds) &&
              double.parse(odds.substring(5).replaceAll(',', '')) >= 1,
        );
        if (t['prizeLabel'] == 'TICKET') {
          need(!t.containsKey('prizeAmount'));
        } else {
          final cents = LouisianaDrawReportsValidator.money(t['prizeLabel']);
          need(
            count(t['prizeAmount']) &&
                t['prizeAmount'] > 0 &&
                t['prizeAmount'] * 100 == cents,
          );
          if (top == null || t['prizeAmount'] > top['prizeAmount']) top = t;
        }
      }
      need(
        top != null &&
            count(g['topPrize']) &&
            count(g['topPrizesRemaining']) &&
            top['prizeAmount'] == g['topPrize'] &&
            top['remaining'] == g['topPrizesRemaining'],
      );
    }
    // Cache only Louisiana, preserving every literal tier and source field.
    return {
      'source': root['source'],
      'updatedAt': root['updatedAt'],
      'catalogs': [c],
    };
  }

  static void continuity(Map<String, dynamic> old, Map<String, dynamic> next) {
    need(!stamp(next['updatedAt']).isBefore(stamp(old['updatedAt'])));
    final a = old['catalogs'][0], b = next['catalogs'][0];
    need(!stamp(b['reportTimestamp']).isBefore(stamp(a['reportTimestamp'])));
    final previous = {for (final g in a['games']) g['id']: g};
    need(b['games'].length >= previous.length * .9);
    for (final g in b['games']) {
      final p = previous[g['id']];
      if (p == null) continue;
      need(
        ['name', 'cost', 'startDate', 'sourceUrl'].every((k) => g[k] == p[k]) &&
            !stamp(g['sourceTimestamp']).isBefore(stamp(p['sourceTimestamp'])),
      );
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
                'data/louisiana_scratch_catalog.generated.json',
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
                'data/louisiana_scratch_catalog.generated.json',
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
