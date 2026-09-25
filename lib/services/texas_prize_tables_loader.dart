import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Loads validated Texas tables without changing their source dates.
class TexasPrizeTablesLoader {
  TexasPrizeTablesLoader({
    this.readCache,
    this.writeCache,
    this.fetchRemote,
    this.readBundle,
  });
  static const cacheKey = 'texas_prize_tables_v1';
  final Future<String?> Function()? readCache;
  final Future<void> Function(String)? writeCache;
  final Future<String> Function()? fetchRemote;
  final Future<String> Function()? readBundle;
  Map<String, dynamic> _decode(String raw) {
    final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final reports = data['reports'] as List;
    if (reports.isEmpty) throw const FormatException('No prize reports');
    for (final report in reports) {
      final headers = report['headers'] as List;
      final rows = [...report['tiers'] as List, report['reportedTotals']];
      if (headers.isEmpty ||
          rows.any((row) => (row as List).length != headers.length)) {
        throw const FormatException('Invalid prize columns');
      }
      final uri = Uri.parse(report['sourceUrl'] as String);
      if (uri.scheme != 'https' || uri.host != 'www.texaslottery.com') {
        throw const FormatException('Nonofficial source');
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
              rootBundle.loadString('data/texas_draw_tiers.generated.json')),
        );
  }

  Future<String> _fetch() async {
    final response = await http.get(
      Uri.parse(
        'https://apollohouser-cpu.github.io/lottery_atlas/texas_draw_tiers.json',
      ),
    );
    if (response.statusCode != 200) {
      throw StateError('Prize table HTTP ${response.statusCode}');
    }
    return response.body;
  }
}
