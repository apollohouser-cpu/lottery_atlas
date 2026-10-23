import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'idaho_coverage_contract.dart';

/// Reviewed contract with numeric Scratch continuity. Draw advancement is pending.
class IdahoCoverageValidator {
  static final Map<String, dynamic> _contract = jsonDecode(
    idahoCoverageContractJson,
  );

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
    _scratch(_contract['scratch'], normalized['scratch']);
    normalized['scratch'] = _contract['scratch'];
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

  static void continuity(Map<String, dynamic> old, Map<String, dynamic> next) {
    _scratch(old['scratch'], next['scratch']);
    if (DateTime.parse(
      next['collectionStartedAt'],
    ).isBefore(DateTime.parse(old['collectionStartedAt']))) {
      throw const FormatException('Idaho collection regression');
    }
  }
}
