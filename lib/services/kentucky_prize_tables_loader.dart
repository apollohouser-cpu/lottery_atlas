import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Loads validated Kentucky tables without changing their source dates.
class KentuckyPrizeTablesLoader {
  KentuckyPrizeTablesLoader({
    this.readCache,
    this.writeCache,
    this.fetchRemote,
    this.readBundle,
  });
  static const cacheKey = 'kentucky_prize_tables_v1';
  final Future<String?> Function()? readCache;
  final Future<void> Function(String)? writeCache;
  final Future<String> Function()? fetchRemote;
  final Future<String> Function()? readBundle;
  Map<String, dynamic> _decode(String raw) {
    final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final reports = data['reports'] as List;
    if (![2, 4, 10].contains(reports.length) ||
        reports[0]['gameName'] != 'Mega Millions' ||
        reports[1]['gameName'] != 'Powerball Xs & Os' ||
        (reports.length >= 4 &&
            (reports[2]['gameName'] != 'Powerball' ||
                reports[3]['gameName'] != 'Powerball Double Play'))) {
      throw const FormatException('Unreviewed Kentucky games');
    }
    if (reports.length == 10) {
      const names = [
        'Millionaire For Life',
        'Cash Ball 225',
        'Pick 3',
        'Pick 3',
        'Pick 4',
        'Pick 4',
      ];
      const sessions = [null, null, 'MIDDAY', 'EVENING', 'MIDDAY', 'EVENING'];
      for (var i = 0; i < names.length; i++) {
        if (reports[i + 4]['gameName'] != names[i] ||
            reports[i + 4]['drawingSession'] != sessions[i]) {
          throw const FormatException('Unreviewed Kentucky session');
        }
      }
    }
    for (final report in reports) {
      final headers = report['headers'] as List;
      final rows = [...report['tiers'] as List, report['reportedTotals']];
      if (headers.isEmpty ||
          rows.any((row) => (row as List).length != headers.length)) {
        throw const FormatException('Invalid prize columns');
      }
      final uri = Uri.parse(report['sourceUrl'] as String);
      if (uri.scheme != 'https' ||
          uri.host != 'www.kylottery.com' ||
          uri.path != '/apps/draw_games/pastwinning.html') {
        throw const FormatException('Nonofficial source');
      }
    }
    final aggregate = data['aggregateSnapshot'];
    if (aggregate != null) {
      final summaries = aggregate['reports'] as List;
      if (summaries.length != 2 ||
          aggregate['sourceUrl'] != data['sourceUrl'] ||
          DateTime.tryParse(aggregate['updatedAt'] as String) == null) {
        throw const FormatException('Invalid aggregate snapshot');
      }
      for (var i = 0; i < summaries.length; i++) {
        final r = summaries[i];
        if (r['gameNumber'] != [22, 19][i] ||
            r['gameName'] != ['Keno', 'Cash Pop'][i] ||
            r['tiers'] != null ||
            r['drawTime'] != null ||
            r['sourcePublicationDate'] != null ||
            r['drawId'] is! int ||
            r['drawId'] < 0 ||
            DateTime.tryParse(r['drawDate'] as String) == null ||
            r['reportedWinners'] is! int ||
            r['reportedWinners'] < 0 ||
            r['reportedPayout'] is! num ||
            !(r['reportedPayout'] as num).isFinite ||
            r['reportedPayout'] < 0) {
          throw const FormatException('Invalid aggregate report');
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
      final aggregate = data['aggregateSnapshot'];
      if (aggregate != null) {
        final summaries = aggregate['reports'] as List;
        if (summaries.length != 2 ||
            aggregate['sourceUrl'] != data['sourceUrl'] ||
            DateTime.tryParse(aggregate['updatedAt'] as String) == null) {
          throw const FormatException('Invalid aggregate snapshot');
        }
        for (var i = 0; i < summaries.length; i++) {
          final r = summaries[i];
          if (r['gameNumber'] != [22, 19][i] ||
              r['gameName'] != ['Keno', 'Cash Pop'][i] ||
              r['tiers'] != null ||
              r['drawTime'] != null ||
              r['sourcePublicationDate'] != null ||
              r['drawId'] is! int ||
              r['drawId'] < 0 ||
              DateTime.tryParse(r['drawDate'] as String) == null ||
              r['reportedWinners'] is! int ||
              r['reportedWinners'] < 0 ||
              r['reportedPayout'] is! num ||
              !(r['reportedPayout'] as num).isFinite ||
              r['reportedPayout'] < 0) {
            throw const FormatException('Invalid aggregate report');
          }
        }
      }
      return data;
    } catch (_) {}
    return cached ??
        _decode(
          await (readBundle?.call() ??
              rootBundle.loadString('data/kentucky_draw_tiers.generated.json')),
        );
  }

  Future<String> _fetch() async {
    final response = await http.get(
      Uri.parse(
        'https://apollohouser-cpu.github.io/lottery_atlas/kentucky_draw_tiers.json',
      ),
    );
    if (response.statusCode != 200) {
      throw StateError('Prize table HTTP ${response.statusCode}');
    }
    return response.body;
  }
}
