import 'dart:convert';
import 'oklahoma_coverage_contract.dart';

/// Initial strict baseline with numeric inventory continuity.
/// Dated result advancement remains fail-closed until its dynamic gate lands.
class OklahomaCoverageValidator {
  static final Map<String, dynamic> _baseline = jsonDecode(
    oklahomaCoverageContractJson,
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

  static DateTime _time(dynamic value) {
    if (value is! String || !RegExp(r'(Z|[+-]\d\d:\d\d)$').hasMatch(value)) {
      throw const FormatException('Missing timestamp timezone');
    }
    final time = DateTime.parse(value);
    if (time.isAfter(DateTime.now().toUtc().add(const Duration(minutes: 5)))) {
      throw const FormatException('Future retrieval time');
    }
    return time;
  }

  static Map<String, dynamic> decode(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    final normalized = jsonDecode(raw) as Map<String, dynamic>;
    final updated = _time(data['updatedAt']);
    if (updated.isBefore(_time(_baseline['updatedAt']))) {
      throw const FormatException('Baseline time regression');
    }
    void stamp(Map item, Map expected, String key) {
      final value = _time(item[key]);
      if (value.isAfter(updated) || value.isBefore(_time(expected[key]))) {
        throw const FormatException('Invalid capture provenance');
      }
      item[key] = expected[key];
    }

    normalized['updatedAt'] = _baseline['updatedAt'];
    for (final field in ['sources', 'results']) {
      final list = normalized[field] as List;
      final expected = _baseline[field] as List;
      if (list.length != expected.length)
        throw const FormatException('Changed baseline window');
      for (var i = 0; i < list.length; i++) {
        stamp(list[i] as Map, expected[i] as Map, 'retrievedAt');
      }
    }
    for (final kind in ['scratch', 'fastPlay']) {
      final catalog = normalized['products'][kind] as Map;
      final expected = _baseline['products'][kind] as Map;
      stamp(catalog, expected, 'listingRetrievedAt');
      final games = catalog['games'] as List;
      final originals = expected['games'] as List;
      if (games.length != originals.length)
        throw const FormatException('Changed catalog');
      for (var i = 0; i < games.length; i++) {
        final game = games[i] as Map;
        final original = originals[i] as Map;
        stamp(game, original, 'retrievedAt');
        final tiers = game['prizeTiers'] as List;
        final prior = original['prizeTiers'] as List;
        if (tiers.length != prior.length)
          throw const FormatException('Changed inventory structure');
        for (var j = 0; j < tiers.length; j++) {
          final count = tiers[j]['remainingPrizes'];
          if (count is! int ||
              count < 0 ||
              count > prior[j]['remainingPrizes']) {
            throw const FormatException('Invalid remaining count');
          }
        }
        if (kind == 'scratch') {
          final top = tiers.singleWhere(
            (t) => t['prizeAmount'] == game['topPrize'],
          );
          if (game['topPrizesRemaining'] != top['remainingPrizes']) {
            throw const FormatException('Top tier mismatch');
          }
          game['topPrizesRemaining'] = original['topPrizesRemaining'];
        } else {
          final estimate = game['progressiveEstimate'];
          if (estimate != null && (estimate is! int || estimate <= 0)) {
            throw const FormatException('Invalid progressive estimate');
          }
          game['progressiveEstimate'] = original['progressiveEstimate'];
        }
        for (var j = 0; j < tiers.length; j++) {
          tiers[j]['remainingPrizes'] = prior[j]['remainingPrizes'];
        }
      }
    }
    if (!_equal(normalized, _baseline)) {
      throw const FormatException('Changed Oklahoma contract requires review');
    }
    return data;
  }

  static void continuity(Map<String, dynamic> old, Map<String, dynamic> next) {
    if (_time(next['updatedAt']).isBefore(_time(old['updatedAt']))) {
      throw const FormatException('Cache time regression');
    }
    for (final kind in ['scratch', 'fastPlay']) {
      final before = old['products'][kind]['games'] as List;
      final after = next['products'][kind]['games'] as List;
      for (var i = 0; i < before.length; i++) {
        final tiers = before[i]['prizeTiers'] as List;
        for (var j = 0; j < tiers.length; j++) {
          if (after[i]['prizeTiers'][j]['remainingPrizes'] >
              tiers[j]['remainingPrizes']) {
            throw const FormatException('Inventory increased against cache');
          }
        }
      }
    }
  }
}
