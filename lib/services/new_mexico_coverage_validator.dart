import 'dart:convert';
import 'new_mexico_report_validator.dart';
import 'new_mexico_draw_validator.dart';
import 'new_mexico_scratch_validator.dart';
import 'new_mexico_coverage_contract.dart';

/// Dynamic dated results and exact-report contracts with retained provenance.
/// Capture/source times and estimated inventory may advance with strict continuity.
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
    NewMexicoDrawValidator.continuity(
      prior['results'] as List,
      prior['queryWindow'] as Map,
      next['results'] as List,
      next['queryWindow'] as Map,
      updated,
    );
    NewMexicoReportValidator.continuity(
      prior['results'] as List,
      next['results'] as List,
    );
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
    final retained = next['retainedReportSources'] as List? ?? [];
    final usedRetained = <String>{};
    final retainedKeys = <String>{};
    for (final source in retained) {
      final key = '${source['url']}|${source['retrievedAt']}';
      if (!retainedKeys.add(key) ||
          source.length != 4 ||
          source['bytes'] is! int ||
          source['bytes'] <= 0 ||
          source['sha256'] is! String ||
          !RegExp(r'^[a-f0-9]{64}$').hasMatch(source['sha256']) ||
          _time(source['retrievedAt']).isAfter(updated)) {
        throw const FormatException('Invalid retained report provenance');
      }
    }
    void reportJoin(Map report) {
      final stamp = _time(report['retrievedAt']);
      if (stamp.isAfter(updated) ||
          stamp.isBefore(DateTime.parse(report['date'] as String))) {
        throw const FormatException('Invalid report capture date');
      }
      if (captured[report['sourceUrl']] == report['retrievedAt']) {
        return;
      }
      final key = '${report['sourceUrl']}|${report['retrievedAt']}';
      if (!retainedKeys.contains(key)) {
        throw const FormatException('Missing retained report source');
      }
      usedRetained.add(key);
      final previousSources = [
        ...prior['sources'] as List,
        ...?prior['retainedReportSources'] as List?,
      ];
      final known = previousSources.where(
        (s) =>
            s['url'] == report['sourceUrl'] &&
            s['retrievedAt'] == report['retrievedAt'],
      );
      if (known.isNotEmpty &&
          NewMexicoReportValidator.canonical(known.first) !=
              NewMexicoReportValidator.canonical(
                retained.firstWhere(
                  (s) => '${s['url']}|${s['retrievedAt']}' == key,
                ),
              )) {
        throw const FormatException('Retained fingerprint changed');
      }
    }

    void join(dynamic url, dynamic stamp) {
      if (_time(stamp).isAfter(updated) || captured[url] != stamp) {
        throw const FormatException('Capture join mismatch');
      }
    }

    for (final row in next['results'] as List) {
      join(row['sourceUrl'], row['retrievedAt']);
      if (row['report'] != null) {
        reportJoin(row['report'] as Map);
      }
    }
    if (usedRetained.length != retainedKeys.length) {
      throw const FormatException('Unused retained source');
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

    normalized['results'] = jsonDecode(jsonEncode(prior['results']));
    normalized['queryWindow'] = prior['queryWindow'];
    normalized.remove('retainedReportSources');
    if (prior.containsKey('retainedReportSources')) {
      normalized['retainedReportSources'] = prior['retainedReportSources'];
    }
    normalize(normalized, prior);
    final sources = normalized['sources'] as List;
    final oldSources = prior['sources'] as List;
    if (sources.length != oldSources.length) {
      throw const FormatException('Capture set changed');
    }
    for (var i = 0; i < sources.length; i++) {
      final url = sources[i]['url'] as String;
      final previousUrl = oldSources[i]['url'] as String;
      if (previousUrl.contains('/pastdrawings/search/?')) {
        final game = Uri.parse(previousUrl).queryParameters['game']!;
        if (url !=
            NewMexicoDrawValidator.queryUrl(game, next['queryWindow'] as Map)) {
          throw const FormatException('Archive source identity changed');
        }
        sources[i]['url'] = previousUrl;
      }
      sources[i]['bytes'] = oldSources[i]['bytes'];
      sources[i]['sha256'] = oldSources[i]['sha256'];
    }
    NewMexicoScratchValidator.normalize(
      normalized['scratch'] as Map,
      prior['scratch'] as Map,
      next['queryWindow']['end'] as String,
    );
    if (!_equal(normalized, prior)) {
      throw const FormatException('Unreviewed New Mexico contract change');
    }
  }
}
