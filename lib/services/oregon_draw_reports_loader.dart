import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Loads validated Oregon draw reports without changing their source dates.
class OregonDrawReportsLoader {
  OregonDrawReportsLoader({
    this.readCache,
    this.writeCache,
    this.fetchRemote,
    this.readBundle,
  });
  static const cacheKey = 'oregon_draw_reports_v1';
  final Future<String?> Function()? readCache;
  final Future<void> Function(String)? writeCache;
  final Future<String> Function()? fetchRemote;
  final Future<String> Function()? readBundle;
  static const games = {
    'pb': ['Powerball', 'powerball'],
    'mm': ['Mega Millions', 'mega-millions'],
    'mb': ['Megabucks', 'megabucks'],
    'wf': ['Win for Life', 'win-for-life'],
    'p4': ['Pick 4', 'pick-4'],
    'cp': ['Cash Pop', 'cash-pop'],
  };
  static List<String?> sessions(String code) => code == 'p4'
      ? ['13:00', '16:00', '19:00', '22:00']
      : code == 'cp'
      ? List.generate(16, (i) => '${(i + 7).toString().padLeft(2, '0')}:00')
      : [null];
  static void require(bool valid) {
    if (!valid) throw const FormatException('Invalid Oregon draw report');
  }

  static bool count(dynamic v) => v is int && v >= 0 && v <= 9007199254740991;
  static bool money(dynamic v) =>
      v is num &&
      v.isFinite &&
      v >= 0 &&
      v * 100 <= 9007199254740991 &&
      (v * 100 - (v * 100).round()).abs() < .00001;
  static bool wallTime(dynamic v) =>
      v is String &&
      RegExp(r'^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$').hasMatch(v) &&
      DateTime.tryParse('${v}Z')?.toIso8601String().substring(0, 19) == v;
  Map<String, dynamic> _decode(String raw) {
    final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    require(
      data['state'] == 'Oregon' &&
          data['schemaVersion'] == 1 &&
          DateTime.tryParse(data['retrievedAt'] as String) != null &&
          data['cadence'] is String &&
          data['coverage'] is String,
    );
    final reports = data['reports'] as List;
    require(reports.length == 48);
    final ids = <String>{}, slots = <String>{};
    final groups = <String, int>{};
    for (final r in reports) {
      final code = r['gameCode'] as String;
      final time = r['drawingTime'] as String?;
      require(games.containsKey(code) && r['game'] == games[code]![0]);
      require(
        sessions(code).contains(time) &&
            count(r['drawNumber']) &&
            r['drawNumber'] > 0,
      );
      require(r['id'] == "or-$code-${r['drawNumber']}" && ids.add(r['id']));
      require(
        wallTime(r['sourceDrawDateTime']) &&
            wallTime(r['sourceRoundedDrawDateTime']),
      );
      final displayed =
          r[code == 'cp' ? 'sourceRoundedDrawDateTime' : 'sourceDrawDateTime']
              as String;
      require(r['drawDate'] == displayed.substring(0, 10));
      if (time != null) require(time == displayed.substring(11, 16));
      if (code == 'cp') {
        final delta = DateTime.parse(
          '${r['sourceRoundedDrawDateTime']}Z',
        ).difference(DateTime.parse('${r['sourceDrawDateTime']}Z')).inSeconds;
        require(
          [0, 60].contains(delta) &&
              displayed.endsWith(':00:00') &&
              (r['sourceDrawDateTime'] as String).substring(0, 10) ==
                  r['drawDate'],
        );
      }
      if (code == 'mm') {
        require((r['drawDate'] as String).compareTo('2025-04-08') >= 0);
      }
      require(slots.add("$code/${r['drawDate']}/$time"));
      groups['$code/$time'] = (groups['$code/$time'] ?? 0) + 1;
      require(
        r.containsKey('winningTickets') &&
            r['winningTickets'] == null &&
            r['countUnit'] is String &&
            r['dateBasis'] is String &&
            r['limitations'] is String,
      );
      require(
        r['sourceUrl'] ==
            'https://www.oregonlottery.org/${games[code]![1]}/winning-numbers/',
      );
      if (['mm', 'cp'].contains(code)) {
        require(
          count(r['reportedWinners']) &&
              money(r['publishedPayoutDollars']) &&
              !r.containsKey('tiers'),
        );
      } else {
        require(
          !r.containsKey('reportedWinners') &&
              !r.containsKey('publishedPayoutDollars'),
        );
        final tiers = r['tiers'] as List;
        final maximum = code == 'pb'
            ? 9
            : code == 'p4'
            ? 17
            : 7;
        require(tiers.isNotEmpty && tiers.length <= maximum);
        final sourceRows = <int>{};
        final prizes = <num>{};
        for (final tier in tiers) {
          require(
            count(tier['reportedWinners']) &&
                tier['prizeText'] is String &&
                (tier['match'] == null || tier['match'] is String),
          );
          final origins = tier['sourceRows'] as List;
          require(origins.isNotEmpty && (code == 'p4' || origins.length == 1));
          for (final n in origins) {
            require(n is int && n >= 1 && n <= maximum && sourceRows.add(n));
          }
          final weekly = code == 'wf' && origins.contains(1);
          require(
            weekly
                ? tier['prizeDollars'] == null &&
                      tier['prizeText'] == r'$1,000 a week for life'
                : money(tier['prizeDollars']) && tier['prizeDollars'] > 0,
          );
          if (code == 'p4') require(prizes.add(tier['prizeDollars'] as num));
        }
        if (code == 'wf') require(sourceRows.contains(1));
        require(
          code == 'pb'
              ? [2, 3, 4, 5, 10].contains(r['multiplier'])
              : r['multiplier'] == null,
        );
      }
    }
    for (final code in games.keys) {
      for (final time in sessions(code)) {
        require(groups['$code/$time'] == 2);
      }
      final ordered = reports.where((r) => r['gameCode'] == code).toList()
        ..sort(
          (a, b) => (a['sourceDrawDateTime'] as String).compareTo(
            b['sourceDrawDateTime'],
          ),
        );
      for (var i = 1; i < ordered.length; i++) {
        require(ordered[i]['drawNumber'] > ordered[i - 1]['drawNumber']);
      }
    }
    return data;
  }

  void _checkContinuity(
    Map<String, dynamic> previous,
    Map<String, dynamic> next,
  ) {
    for (final old in previous['reports'] as List) {
      final candidates = (next['reports'] as List).where(
        (r) =>
            r['gameCode'] == old['gameCode'] &&
            r['drawingTime'] == old['drawingTime'],
      );
      require(
        candidates.any(
          (r) =>
              (r['drawDate'] as String).compareTo(old['drawDate']) >= 0 &&
              r['drawNumber'] >= old['drawNumber'],
        ),
      );
      for (final r in next['reports'] as List) {
        if (r['id'] == old['id']) {
          require(
            r['sourceDrawDateTime'] == old['sourceDrawDateTime'] &&
                r['sourceRoundedDrawDateTime'] ==
                    old['sourceRoundedDrawDateTime'],
          );
        }
      }
      for (final r in candidates) {
        if (r['drawDate'] == old['drawDate']) require(r['id'] == old['id']);
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
              rootBundle.loadString('data/oregon_draw_reports.generated.json')),
        );
  }

  Future<String> _fetch() async {
    final response = await http.get(
      Uri.parse(
        'https://apollohouser-cpu.github.io/lottery_atlas/oregon_draw_reports.json',
      ),
    );
    if (response.statusCode != 200) {
      throw StateError('Prize table HTTP ${response.statusCode}');
    }
    return response.body;
  }
}
