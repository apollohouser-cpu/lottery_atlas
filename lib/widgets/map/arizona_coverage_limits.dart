import 'package:flutter/material.dart';

/// Keep the reviewed coverage boundaries available in each Arizona collection.
class ArizonaCoverageLimits extends StatelessWidget {
  const ArizonaCoverageLimits({super.key, required this.coverage});

  final Map<String, dynamic> coverage;

  @override
  Widget build(BuildContext context) => ExpansionTile(
    title: const Text('Coverage and unavailable information'),
    children: [
      for (final limitation in coverage['limitations'] as List)
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(limitation as String),
          ),
        ),
    ],
  );
}
