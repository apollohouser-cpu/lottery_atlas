import 'dart:convert';
import 'louisiana_draw_reports_validator.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NebraskaScratchCatalogLoader {
  NebraskaScratchCatalogLoader({
    this.readCache,
    this.writeCache,
    this.fetchRemote,
    this.readBundle,
  });
  static const cacheKey = 'nebraska_scratch_catalog_v1';
  final Future<String?> Function()? readCache;
  final Future<void> Function(String)? writeCache;
  final Future<String> Function()? fetchRemote;
  final Future<String> Function()? readBundle;

  static void need(bool v) => LouisianaDrawReportsValidator.need(v);
  static bool text(dynamic v) => LouisianaDrawReportsValidator.text(v);
  static bool count(dynamic v) => LouisianaDrawReportsValidator.count(v);
  static DateTime stamp(dynamic v) => LouisianaDrawReportsValidator.stamp(v);

  static final dynamic reviewed = jsonDecode(
    r'''{"source": "https://nelottery.com/images/media/Scratch_Prizes_Remaining.pdf", "sourceDate": "2026-09-13", "reviewedAt": "2026-09-20", "sourceSha256": "32172e927eea6d68af98ee482af070b1104da4d0d9c491153b661e705fbc0f11", "method": "Top-prize row for each game transcribed from the rendered official one-page report and visually reviewed. Lower report tiers are not included. This dated snapshot requires a new source review before counts or sourceDate change.", "games": [{"id": "1357", "topPrize": 50000, "topPrizesRemaining": 4}, {"id": "1308", "topPrize": 300000, "topPrizesRemaining": 1}, {"id": "1395", "topPrize": 50000, "topPrizesRemaining": 3}, {"id": "1378", "topPrize": 500, "topPrizesRemaining": 248}, {"id": "1370", "topPrize": 200000, "topPrizesRemaining": 2}, {"id": "1350", "topPrize": 200000, "topPrizesRemaining": 1}, {"id": "1398", "topPrize": 100000, "topPrizesRemaining": 2}, {"id": "1380", "topPrize": 100000, "topPrizesRemaining": 2}, {"id": "1377", "topPrize": 250, "topPrizesRemaining": 449}, {"id": "1368", "topPrize": 75000, "topPrizesRemaining": 3}, {"id": "1356", "topPrize": 100000, "topPrizesRemaining": 1}, {"id": "1354", "topPrize": 100000, "topPrizesRemaining": 1}, {"id": "1402", "topPrize": 50000, "topPrizesRemaining": 2}, {"id": "1396", "topPrize": 50000, "topPrizesRemaining": 2}, {"id": "1394", "topPrize": 500, "topPrizesRemaining": 751}, {"id": "1386", "topPrize": 30000, "topPrizesRemaining": 2}, {"id": "1385", "topPrize": 50000, "topPrizesRemaining": 3}, {"id": "1383", "topPrize": 50000, "topPrizesRemaining": 2}, {"id": "1367", "topPrize": 50000, "topPrizesRemaining": 2}, {"id": "1373", "topPrize": 35000, "topPrizesRemaining": 3}, {"id": "1334", "topPrize": 35000, "topPrizesRemaining": 1}, {"id": "1311", "topPrize": 35000, "topPrizesRemaining": 1}, {"id": "1351", "topPrize": 17777, "topPrizesRemaining": 2}, {"id": "1381", "topPrize": 7000, "topPrizesRemaining": 8}, {"id": "1335", "topPrize": 500, "topPrizesRemaining": 10}]}''',
  );
  static final dynamic exclusions = jsonDecode(
    r'''[{"name": "Black Diamond Blowout", "sourceUrl": "https://nelottery.com/scratch-detail?gameid=1099", "reason": "Heading game 1417 conflicts with ticket-art filename 1416; identity unverified."}]''',
  );
  static Map<String, dynamic> decode(String raw) {
    final root = jsonDecode(raw) as Map<String, dynamic>;
    stamp(root['updatedAt']);
    final matches = (root['catalogs'] as List)
        .where((c) => c['state'] == 'Nebraska')
        .toList();
    need(matches.length == 1);
    final c = matches.single;
    need(
      c['source'] == 'https://nelottery.com/scratch' &&
          c['inventorySource'] == reviewed['source'] &&
          c['sourceDate'] == reviewed['sourceDate'],
    );
    need(c['coverage'] == coverage && c['updateCadence'] == cadence);
    need(jsonEncode(c['excludedGames']) == jsonEncode(exclusions));
    final games = c['games'] as List;
    need(games.length >= 15 && games.length <= 500);
    final ids = <String>{};
    for (final g in games) {
      need(
        g['stateName'] == 'Nebraska' &&
            g['id'] is String &&
            RegExp(r'^[1-9]\d*$').hasMatch(g['id']) &&
            ids.add(g['id']),
      );
      need(
        text(g['name']) &&
            count(g['cost']) &&
            g['cost'] > 0 &&
            count(g['topPrize']) &&
            g['topPrize'] > 0,
      );
      final u = Uri.parse(g['sourceUrl']);
      need(
        u.scheme == 'https' &&
            u.host == 'nelottery.com' &&
            u.path == '/scratch-detail' &&
            u.userInfo.isEmpty &&
            !u.hasPort &&
            !u.hasFragment &&
            u.queryParameters.length == 1 &&
            RegExp(r'^[1-9]\d*$').hasMatch(u.queryParameters['gameid'] ?? ''),
      );
      need(!exclusions.any((e) => e['sourceUrl'] == g['sourceUrl']));
      final rows = g['prizeStructure'] as List;
      need(rows.isNotEmpty && rows.length <= 300);
      for (final t in rows) {
        need(
          text(t['prizeLabel']) &&
              t['publishedOdds'] is String &&
              RegExp(r'^[\d,]+\.\d{2}$').hasMatch(t['publishedOdds']) &&
              count(t['publishedStructureWinners']),
        );
        need(!t.containsKey('remaining') && !t.containsKey('claimed'));
        if (freeLabels.contains(t['prizeLabel'])) {
          need(!t.containsKey('prizeAmount'));
        } else {
          need(
            count(t['prizeAmount']) &&
                t['prizeAmount'] * 100 ==
                    LouisianaDrawReportsValidator.money(
                      (t['prizeLabel'] as String).startsWith(r'$')
                          ? t['prizeLabel']
                          : '\$${t['prizeLabel']}',
                    ),
          );
        }
      }
      final cash = rows
          .where((t) => t.containsKey('prizeAmount'))
          .map((t) => t['prizeAmount'] as int)
          .toList();
      need(
        cash.isNotEmpty &&
            cash.reduce((a, b) => a > b ? a : b) == g['topPrize'],
      );
      final matched = (reviewed['games'] as List)
          .where((r) => r['id'] == g['id'])
          .toList();
      if (matched.isEmpty) {
        need(!g.containsKey('topPrizesRemaining'));
      } else {
        need(
          g['topPrize'] == matched.single['topPrize'] &&
              g['topPrizesRemaining'] == matched.single['topPrizesRemaining'],
        );
      }
      need(
        text(g['inventoryNote']) &&
            g['inventoryNote'].contains(reviewed['sourceDate']) &&
            g['inventoryNote'].contains(
              'Prize-structure winners are not dated claims. Store availability unverified.',
            ),
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
    final previous = {for (final g in old['catalogs'][0]['games']) g['id']: g};
    final games = next['catalogs'][0]['games'];
    need(games.length >= previous.length * .9);
    for (final g in games) {
      final p = previous[g['id']];
      if (p != null) {
        need(
          ['name', 'cost', 'sourceUrl', 'topPrize'].every((k) => g[k] == p[k]),
        );
      }
    }
  }

  static final dynamic freeLabels = jsonDecode(
    r'''["$1 Free Ticket", "$10 Free Ticket", "$3 Free Ticket", "$5 Free Ticket", "$5 Free Ticket + $5", "Free $10 Ticket", "Free $2 Ticket", "Free $20 Ticket", "Free $20 Ticket + $20", "Free $20 Ticket + $30", "Free $30 Ticket", "Free $5 Ticket"]''',
  );
  static const coverage =
      r'''Current catalog joined by printed game number to a manually reviewed dated top-prize report. Unknown unmatched counts remain missing. Prize-structure rows are not claims or remaining inventory. Excludes report-only games absent from current catalog; no retailer joins. Excluded unverified identities: Black Diamond Blowout (conflicting published game numbers).''';
  static const cadence =
      r'''Official remaining-prize report is weekly; this reviewed snapshot is not automatically refreshed. Catalog details checked every six hours.''';
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
                'data/nebraska_scratch_catalog.generated.json',
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
                'data/nebraska_scratch_catalog.generated.json',
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
