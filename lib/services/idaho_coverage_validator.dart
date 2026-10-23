import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'idaho_coverage_contract.dart';

/// Initial audited baseline gate. Not yet a validator for advancing source data.
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
    if (!_equal(content, _contract)) {
      throw const FormatException('Idaho content outside audited baseline');
    }
    return data;
  }

  static void continuity(Map<String, dynamic> old, Map<String, dynamic> next) {
    if (DateTime.parse(
      next['collectionStartedAt'],
    ).isBefore(DateTime.parse(old['collectionStartedAt']))) {
      throw const FormatException('Idaho collection regression');
    }
  }
}
