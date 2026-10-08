import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class NorthCarolinaScratchCatalogLoader {
  NorthCarolinaScratchCatalogLoader({
    this.readCache,
    this.writeCache,
    this.fetchRemote,
    this.readBundle,
  });
  static const cacheKey = 'north_carolina_scratch_catalog_v1';
  final Future<String?> Function()? readCache;
  final Future<void> Function(String)? writeCache;
  final Future<String> Function()? fetchRemote;
  final Future<String> Function()? readBundle;

  static void require(bool value) {
    if (!value) throw const FormatException('Invalid NorthCarolina inventory');
  }

  static bool text(dynamic v) => v is String && v.trim().isNotEmpty;
  static bool count(dynamic v) => v is int && v >= 0 && v <= 9007199254740991;
  static bool day(dynamic v) =>
      v is String &&
      RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(v) &&
      DateTime.tryParse(v)?.toIso8601String().substring(0, 10) == v;
  Map<String, dynamic> _decode(String raw) {
    final d = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    require(
      d['stateCode'] == 'NC' &&
          day(d['sourceDate']) &&
          d['sourceUrl'] ==
              'https://nclottery.com/scratch-off-prizes-remaining' &&
          d['updatedAt'] is String &&
          DateTime.tryParse(d['updatedAt']) != null &&
          text(d['coverage']) &&
          text(d['sourceDefinition']),
    );
    final retrieved = DateTime.parse(d['updatedAt']);
    require(
      !retrieved.isAfter(
            DateTime.now().toUtc().add(const Duration(minutes: 5)),
          ) &&
          (d['sourceDate'] as String).compareTo(
                retrieved.toUtc().toIso8601String().substring(0, 10),
              ) <=
              0,
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
            (g['statusLabel'] == null || text(g['statusLabel'])) &&
            g['notes'] is String,
      );
      final u = Uri.parse(g['sourceUrl'] as String);
      require(
        u.scheme == 'https' &&
            u.host == 'nclottery.com' &&
            RegExp(
              '^/scratch-off/$id/'
              r'[a-z0-9-]+$',
            ).hasMatch(u.path) &&
            u.userInfo.isEmpty &&
            !u.hasFragment &&
            !u.hasPort &&
            !u.hasQuery,
      );
      final tiers = g['tiers'] as List;
      require(tiers.isNotEmpty && tiers.length <= 100);
      final labels = <String>{};
      for (final t in tiers) {
        require(
          text(t['prizeLabel']) &&
              labels.add(t['prizeLabel']) &&
              t['oddsLabel'] is String &&
              RegExp(
                r'^(?:[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)(?:\.\d+)?$',
              ).hasMatch(t['oddsLabel']) &&
              count(t['totalPrizes']) &&
              count(t['remainingPrizes']) &&
              t['remainingPrizes'] <= t['totalPrizes'],
        );
      }
    }
    return d;
  }

  void _checkContinuity(Map<String, dynamic> old, Map<String, dynamic> next) {
    require(
      !DateTime.parse(
        next['updatedAt'],
      ).isBefore(DateTime.parse(old['updatedAt'])),
    );
    require((next['sourceDate'] as String).compareTo(old['sourceDate']) >= 0);
    final games = next['games'] as List, previous = old['games'] as List;
    require(games.length >= previous.length * .9);
    final byId = {for (final g in previous) g['id']: g};
    for (final g in games) {
      final p = byId[g['id']];
      if (p != null) {
        require(
          ['name', 'ticketPrice', 'sourceUrl'].every((k) => p[k] == g[k]),
        );
        final oldLabels = {for (final t in p['tiers']) t['prizeLabel']};
        final newLabels = {for (final t in g['tiers']) t['prizeLabel']};
        require(
          oldLabels.length == newLabels.length &&
              oldLabels.containsAll(newLabels),
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
    if (cached == null) {
      try {
        cached = _decode(
          await (readBundle?.call() ??
              rootBundle.loadString(
                'data/north_carolina_scratch_catalog.generated.json',
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
                'data/north_carolina_scratch_catalog.generated.json',
              )),
        );
  }

  Future<String> _fetch() async {
    final response = await http.get(
      Uri.parse(
        'https://apollohouser-cpu.github.io/lottery_atlas/north_carolina_scratch_catalog.json',
      ),
    );
    if (response.statusCode != 200) {
      throw StateError('Catalog HTTP ${response.statusCode}');
    }
    return response.body;
  }
}
