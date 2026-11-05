import 'package:flutter/material.dart';

/// Literal schedules with reviewed matching-ball symbols exposed as text.
class ArizonaRuleSchedule extends StatelessWidget {
  const ArizonaRuleSchedule({super.key, required this.rule});
  final Map rule;

  static String cellText(dynamic value, dynamic symbols, String game) {
    final text = value.toString();
    if (symbols is int && symbols > 0) {
      return '$symbols matching numbers${text.isEmpty ? '' : ' · $text'}';
    }
    if (symbols is List && symbols.isNotEmpty) {
      final ordinary = symbols.where((s) => s == 'winning-ball').length;
      final special = symbols.where((s) => s == 'winning-ball m').length;
      if (ordinary + special != symbols.length) {
        throw const FormatException('Unreviewed matching symbols');
      }
      final specialLabel = game == 'mega-millions' ? 'Mega Ball' : 'Powerball';
      return '$ordinary matching white numbers + $special $specialLabel${text.isEmpty ? '' : ' · $text'}';
    }
    return text;
  }

  static List<String> tableLines(Map table, String game) {
    final rows = table['rows'] as List;
    final symbols = table['matchingSymbols'] as List?;
    return [
      for (var i = 0; i < rows.length; i++)
        [
          for (var j = 0; j < (rows[i] as List).length; j++)
            cellText(rows[i][j], symbols == null ? null : symbols[i][j], game),
        ].where((s) => s.isNotEmpty).join(' · '),
    ];
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Text(
        'Published prize schedules, not actual payouts. Source exceptions and sharing rules apply.',
      ),
      for (final table in rule['tables']) ...[
        for (final text in tableLines(table, rule['game']))
          if (text.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(text),
            ),
        for (final nested in table['nestedTables'] ?? []) ...[
          Text(
            nested['label'] ?? 'Source detail table',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          for (final text in tableLines(nested, rule['game']))
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Text(text),
            ),
        ],
        ExpansionTile(
          title: const Text('Complete schedule wording and caveats'),
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: Text(table['sectionText']),
            ),
          ],
        ),
        const Divider(),
      ],
      Text(rule['howToPlay']),
      Text('Rules observed: ${rule['retrievedAt']}'),
    ],
  );
}
