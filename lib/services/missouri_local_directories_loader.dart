import 'dart:convert';
import 'package:flutter/services.dart';

/// Reviewed city-limited public results, never mapped using inferred coordinates.
class MissouriLocalDirectoriesLoader {
  static Future<Map<String, dynamic>> load() async => decode(
    await rootBundle.loadString(
      'data/missouri_local_directories.generated.json',
    ),
  );
  static Map<String, dynamic> decode(String raw) {
    void require(bool v) {
      if (!v) {
        throw const FormatException('Invalid local directory');
      }
    }

    bool text(dynamic v) => v is String && v.trim().isNotEmpty;
    final d = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    require(d['stateCode'] == 'MO');
    final queries = d['queries'] as List;
    require(queries.length == 2);
    final cities = <String>{};
    for (final q in queries) {
      require(
        q['stateCode'] == 'MO' &&
            q['sourceDate'] == null &&
            q['sourceUrl'] ==
                'https://www.molottery.com/where-to-play/where-to-play.do' &&
            text(q['coverage']) &&
            DateTime.tryParse(q['updatedAt'] as String) != null,
      );
      final query = q['query'] as Map;
      require(
        ['Jefferson City', 'Columbia'].contains(query['city']) &&
            cities.add(query['city']) &&
            query['radiusMiles'] == 0 &&
            jsonEncode(query['productGroups']) ==
                '["online","keno","scratchers"]',
      );
      final rows = q['retailers'] as List;
      require(rows.isNotEmpty && rows.length <= 10000);
      final identities = <String>{};
      for (final r in rows) {
        require(
          text(r['name']) &&
              text(r['address']) &&
              r['city'] == query['city'] &&
              RegExp(r'^\d{5}(?:-\d{4})?$').hasMatch(r['zip'] as String) &&
              r['latitude'] == null &&
              r['longitude'] == null &&
              r['sourceRetailerId'] == null,
        );
        final products = List<String>.from(r['products']);
        require(
          products.isNotEmpty &&
              products.toSet().length == products.length &&
              products.every(
                ['Draw Games', 'Scratchers', 'Keno 2 Go', 'Club Keno'].contains,
              ),
        );
        require(
          identities.add(
            jsonEncode([r['name'], r['address'], r['city'], r['zip']]),
          ),
        );
      }
    }
    return d;
  }
}
