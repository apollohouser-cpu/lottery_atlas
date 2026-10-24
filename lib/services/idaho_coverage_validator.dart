import 'dart:convert';
import 'idaho_draw_validator.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:flutter/foundation.dart';
import 'idaho_coverage_contract.dart';

/// Reviewed contract with numeric Scratch continuity. Strict draw/report and product continuity.
class IdahoCoverageValidator {
  static final Map<String, dynamic> _contract = jsonDecode(
    idahoCoverageContractJson,
  );

  static bool _zonesReady = false;

  static bool _equal(dynamic a, dynamic b) {
    if (a is Map && b is Map) {
      return a.length == b.length &&
          a.keys.every((k) => b.containsKey(k) && _equal(a[k], b[k]));
    }
    if (a is List && b is List) {
      return a.length == b.length &&
          List.generate(a.length, (i) => i).every((i) => _equal(a[i], b[i]));
    }
    return a == b;
  }

  static Map<String, dynamic> decode(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final content = Map<String, dynamic>.from(data);
    final stamp = content.remove('collectionStartedAt');
    final evidence = content.remove('sourceEvidence');
    if (stamp is! String || !RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(stamp)) {
      throw const FormatException('Missing collection timezone');
    }
    final time = DateTime.parse(stamp);
    if (time.isAfter(DateTime.now().toUtc().add(const Duration(minutes: 5)))) {
      throw const FormatException('Future collection date');
    }
    if (evidence is! List || evidence.length != 85) {
      throw const FormatException('Incomplete source evidence');
    }
    final urls = <String>{};
    for (final item in evidence) {
      if (item is! Map || !setEquals(item.keys.toSet(), {'url', 'sha256'})) {
        throw const FormatException('Malformed source evidence');
      }
      final uri = Uri.parse(item['url'] as String);
      if (uri.scheme != 'https' ||
          uri.host != 'www.idaholottery.com' ||
          uri.userInfo.isNotEmpty ||
          uri.hasQuery ||
          uri.hasFragment ||
          !urls.add(uri.toString()) ||
          item['sha256'] is! String ||
          !RegExp(r'^[0-9a-f]{64}$').hasMatch(item['sha256'])) {
        throw const FormatException('Invalid source evidence');
      }
    }
    final normalized = jsonDecode(jsonEncode(content)) as Map<String, dynamic>;
    IdahoDrawValidator.validate(
      normalized['results'],
      _contract['results'],
      time,
    );
    normalized['results'] = _contract['results'];
    _scratch(_contract['scratch'], normalized['scratch']);
    normalized['scratch'] = _contract['scratch'];
    _raffle(_contract['raffle'], normalized['raffle'], time);
    normalized['raffle'] = _contract['raffle'];
    if (!_equal(normalized, _contract)) {
      throw const FormatException('Idaho content outside audited baseline');
    }
    return data;
  }

  // Keep reviewed identities, metadata, original quantities and unknown statuses.
  // Only known remaining quantities can decrease; the publisher applies this
  // same rule because the source supplies no inventory verification date.
  static void _scratch(dynamic before, dynamic after) {
    if (after is! Map || after['games'] is! List) {
      throw const FormatException('Missing Scratch catalog');
    }
    final normalized = jsonDecode(jsonEncode(after)) as Map<String, dynamic>;
    final oldGames = before['games'] as List;
    final games = normalized['games'] as List;
    if (games.length != oldGames.length) {
      throw const FormatException('Scratch identity loss');
    }
    for (var i = 0; i < games.length; i++) {
      final game = games[i];
      final old = oldGames[i];
      if (game is! Map || game['prizeTiers'] is! List) {
        throw const FormatException('Malformed Scratch game');
      }
      final tiers = game['prizeTiers'] as List;
      final oldTiers = old['prizeTiers'] as List;
      if (tiers.length != oldTiers.length) {
        throw const FormatException('Scratch tier loss');
      }
      for (var j = 0; j < tiers.length; j++) {
        final tier = tiers[j];
        if (tier is! Map ||
            tier['remaining'] is! int ||
            tier['remaining'] < 0 ||
            tier['remaining'] > oldTiers[j]['remaining']) {
          throw const FormatException('Scratch count regression');
        }
      }
      if (game['topPrizesRemaining'] is! int ||
          game['topPrizesRemaining'] != tiers.first['remaining']) {
        throw const FormatException('Scratch top-tier mismatch');
      }
      game['topPrizesRemaining'] = old['topPrizesRemaining'];
      for (var j = 0; j < tiers.length; j++) {
        tiers[j]['remaining'] = oldTiers[j]['remaining'];
      }
    }
    if (!_equal(normalized, before)) {
      throw const FormatException('Scratch structure or status changed');
    }
  }

  static void _raffle(dynamic before, dynamic after, DateTime collected) {
    if (!_zonesReady) {
      tzdata.initializeTimeZones();
      _zonesReady = true;
    }
    final local = tz.TZDateTime.from(
      collected,
      tz.getLocation('America/Boise'),
    );
    final asOf = DateTime.utc(local.year, local.month, local.day);
    if (!asOf.isBefore(DateTime.utc(2026, 12, 29))) {
      throw const FormatException('Raffle announcement requires source review');
    }
    if (after is! Map || after['dailyPromotions'] is! List) {
      throw const FormatException('Missing Raffle promotions');
    }
    final normalized = Map<String, dynamic>.from(after);
    final rows = normalized['dailyPromotions'] as List;
    final indexed = <String, dynamic>{};
    String? previous;
    for (final row in rows) {
      if (row is! Map ||
          !setEquals(row.keys.toSet(), {'date', 'ticketNumber'}) ||
          row['date'] is! String ||
          row['ticketNumber'] is! String) {
        throw const FormatException('Malformed Raffle promotion');
      }
      final date = row['date'] as String;
      final day = DateTime.tryParse(date);
      final number = row['ticketNumber'] as String;
      if (!RegExp(r'^2026-\d{2}-\d{2}$').hasMatch(date) ||
          day == null ||
          day.toIso8601String().substring(0, 10) != date ||
          day.isBefore(DateTime(2026, 10, 21)) ||
          day.isAfter(DateTime(2026, 11, 9)) ||
          DateTime.utc(day.year, day.month, day.day).isAfter(asOf) ||
          (previous != null && date.compareTo(previous) <= 0) ||
          !RegExp(r'^[0-9]{6}$').hasMatch(number) ||
          int.parse(number) < 1 ||
          int.parse(number) > 500000) {
        throw const FormatException('Invalid Raffle promotion');
      }
      indexed[date] = row;
      previous = date;
    }
    for (final row in before['dailyPromotions'] as List) {
      if (!_equal(indexed[row['date']], row)) {
        throw const FormatException('Raffle promotion correction or loss');
      }
    }
    normalized['dailyPromotions'] = before['dailyPromotions'];
    if (!_equal(normalized, before)) {
      throw const FormatException('Raffle rules or final result changed');
    }
  }

  static void continuity(Map<String, dynamic> old, Map<String, dynamic> next) {
    IdahoDrawValidator.continuity(old['results'], next['results']);
    for (final row in next['results']) {
      if (!row.containsKey('reportProvenance')) continue;
      final matches = (old['results'] as List)
          .where(
            (r) =>
                r['group'] == row['group'] && r['drawDate'] == row['drawDate'],
          )
          .toList();
      if (matches.length != 1 || matches.single['report'] == null) {
        throw const FormatException('No original retained report');
      }
      final prior = matches.single;
      dynamic expected = prior['reportProvenance'];
      if (expected == null) {
        final sources = (old['sourceEvidence'] as List)
            .where((e) => e['url'] == row['sourceUrl'])
            .toList();
        if (sources.length != 1) {
          throw const FormatException('Missing original evidence');
        }
        expected = {
          'collectionStartedAt': old['collectionStartedAt'],
          'sourceUrl': row['sourceUrl'],
          'sha256': sources.single['sha256'],
        };
      }
      if (!_equal(expected, row['reportProvenance'])) {
        throw const FormatException('Changed original report provenance');
      }
    }
    _scratch(old['scratch'], next['scratch']);
    _raffle(
      old['raffle'],
      next['raffle'],
      DateTime.parse(next['collectionStartedAt']),
    );
    if (DateTime.parse(
      next['collectionStartedAt'],
    ).isBefore(DateTime.parse(old['collectionStartedAt']))) {
      throw const FormatException('Idaho collection regression');
    }
  }
}
