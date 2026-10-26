import 'dart:convert';
import 'new_mexico_coverage_contract.dart';

/// Initial fail-closed contract: dated draws/reports/rules remain baseline-bound.
/// Capture times may advance and estimated top-prize counts may decrease.
class NewMexicoCoverageValidator {
  static final Map<String, dynamic> _baseline = jsonDecode(
    newMexicoCoverageContractJson,
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
      throw const FormatException('Missing capture timezone');
    }
    final stamp = DateTime.parse(value);
    if (stamp.isAfter(DateTime.now().toUtc().add(const Duration(minutes: 5)))) {
      throw const FormatException('Future capture');
    }
    return stamp;
  }

  static Map<String, dynamic> decode(String raw) {
    final data = jsonDecode(raw) as Map<String, dynamic>;
    continuity(_baseline, data);
    return data;
  }

  static void continuity(
    Map<String, dynamic> prior,
    Map<String, dynamic> next,
  ) {
    final normalized = jsonDecode(jsonEncode(next)) as Map<String, dynamic>;
    final updated = _time(next['updatedAt']);
    if (updated.isBefore(_time(prior['updatedAt']))) {
      throw const FormatException('Collection regression');
    }
    final captured = <String, String>{};
    for (final source in next['sources'] as List) {
      if (captured.containsKey(source['url'])) {
        throw const FormatException('Duplicate capture');
      }
      if (source['bytes'] is! int ||
          source['bytes'] <= 0 ||
          source['sha256'] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(source['sha256'])) {
        throw const FormatException('Invalid capture fingerprint');
      }
      captured[source['url'] as String] = source['retrievedAt'] as String;
    }
    void join(dynamic url, dynamic stamp) {
      if (captured[url] != stamp) {
        throw const FormatException('Capture join mismatch');
      }
    }

    for (final row in next['results'] as List) {
      join(row['sourceUrl'], row['retrievedAt']);
      if (row['report'] != null) {
        join(row['report']['sourceUrl'], row['report']['retrievedAt']);
      }
    }
    for (final rule in next['rules'] as List) {
      join(rule['sourceUrl'], rule['retrievedAt']);
    }
    final scratch = next['scratch'] as Map;
    join(scratch['inventorySource'], scratch['retrievedAt']);
    join(scratch['endingSource'], scratch['endingRetrievedAt']);

    // Only reviewed dynamic fields are normalized. Unknown keys, changed rules,
    // units, result identities or report values still fail the full comparison.
    void normalize(dynamic value, dynamic old) {
      if (value is Map && old is Map) {
        for (final key in value.keys.toList()) {
          if (!old.containsKey(key)) continue;
          if (['updatedAt', 'retrievedAt', 'endingRetrievedAt'].contains(key)) {
            final stamp = _time(value[key]);
            if (stamp.isAfter(updated) || stamp.isBefore(_time(old[key]))) {
              throw const FormatException('Capture regression or future join');
            }
            value[key] = old[key];
          } else {
            normalize(value[key], old[key]);
          }
        }
      } else if (value is List && old is List && value.length == old.length) {
        for (var i = 0; i < value.length; i++) {
          normalize(value[i], old[i]);
        }
      }
    }

    normalize(normalized, prior);
    final sources = normalized['sources'] as List;
    final oldSources = prior['sources'] as List;
    if (sources.length != oldSources.length) {
      throw const FormatException('Capture set changed');
    }
    for (var i = 0; i < sources.length; i++) {
      sources[i]['bytes'] = oldSources[i]['bytes'];
      sources[i]['sha256'] = oldSources[i]['sha256'];
    }
    final games = normalized['scratch']['games'] as List;
    final oldGames = prior['scratch']['games'] as List;
    if (games.length != oldGames.length) {
      throw const FormatException('Unreviewed Scratch set');
    }
    for (var i = 0; i < games.length; i++) {
      final count = games[i]['topPrizesRemaining'];
      if (count is! int ||
          count < 0 ||
          count > oldGames[i]['topPrizesRemaining']) {
        throw const FormatException('Estimated top-prize regression');
      }
      games[i]['topPrizesRemaining'] = oldGames[i]['topPrizesRemaining'];
    }
    if (!_equal(normalized, prior)) {
      throw const FormatException('Unreviewed New Mexico contract change');
    }
  }
}
