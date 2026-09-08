import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  test('published launch activity begins on January 1, 2026', () {
    final root = Map<String, dynamic>.from(
      jsonDecode(File('docs/activity.json').readAsStringSync()) as Map,
    );
    final records = (root['activities'] as List)
        .map((record) => Map<String, dynamic>.from(record as Map))
        .toList(growable: false);

    expect(records, isNotEmpty);
    expect(
      records.every(
        (record) => !DateTime.parse(
          record['drawDate'] as String,
        ).toUtc().isBefore(DateTime.utc(2026)),
      ),
      isTrue,
    );
    expect(root['coverage'], contains('January 1, 2026'));
  });
}
