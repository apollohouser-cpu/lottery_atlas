import 'package:flutter/material.dart';
import 'arizona_rule_schedule.dart';
import 'package:url_launcher/url_launcher.dart';

/// Development presentation; callers must supply validated Arizona coverage.
class ArizonaDrawCollectionSheet extends StatefulWidget {
  const ArizonaDrawCollectionSheet({
    super.key,
    required this.coverage,
    this.openSource,
  });
  final Map<String, dynamic> coverage;
  final Future<bool> Function(Uri)? openSource;
  static const labels = {
    'powerball': 'Powerball',
    'powerball-double-play': 'Powerball Double Play',
    'powerball-xs-os': 'Powerball Xs & Os',
    'mega-millions': 'Mega Millions',
    'the-pick': 'The Pick',
    'fantasy-5': 'Fantasy 5',
    'triple-twist': 'Triple Twist',
    'pick-3-midday': 'Pick 3 Midday',
    'pick-3-evening': 'Pick 3 Evening',
    'pick-4-midday': 'Pick 4 Midday',
    'pick-4-evening': 'Pick 4 Evening',
    'one-to-win': 'One To Win',
    'two-to-win': 'Two to Win',
    '5-in-a-line': '5 In-A-Line',
    'money-roll': 'Money Roll',
    'pick-your-bet': 'Pick Your Bet',
    '51045': '5/10/45',
    'lucky-links': 'Lucky Links',
    'hi-lo': 'Hi-Lo',
  };
  static String resultText(Map r) {
    final lines = <String>[];
    if (r['numbers'] != null) {
      lines.add('Numbers: ${(r['numbers'] as List).join(' · ')}');
    }
    if (r['digits'] != null) lines.add('Ordered digits: ${r['digits']}');
    if (r['diceLabels'] != null) {
      lines.add(
        'Dice in source order: ${(r['diceLabels'] as List).join(' · ')}',
      );
    }
    if (r['teamLabels'] != null) {
      lines.add('Team labels: ${(r['teamLabels'] as List).join(' · ')}');
    }
    for (final entry in {
      'powerball': 'Powerball',
      'megaBall': 'Mega Ball',
      'powerPlay': 'Power Play',
      'superBonus': 'Super Bonus',
      'bullseye': 'Bullseye',
      'number': 'Winning number',
      'basePrizeAmount': 'Base prize amount',
      'winningNumber': 'Winning number',
      'parity': 'Parity',
      'band': 'Band',
      'highNumberTotal': 'High number total',
      'lowNumberTotal': 'Low number total',
    }.entries) {
      if (r.containsKey(entry.key)) {
        lines.add('${entry.value}: ${r[entry.key]}');
      }
    }
    return lines.join('\n');
  }

  @override
  State<ArizonaDrawCollectionSheet> createState() =>
      _ArizonaDrawCollectionSheetState();
}

class _ArizonaDrawCollectionSheetState
    extends State<ArizonaDrawCollectionSheet> {
  String selected = 'powerball';
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  Widget line(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(text),
  );
  Future<void> open(String source) async {
    final uri = Uri.tryParse(source);
    var success = false;
    if (uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'www.arizonalottery.com') {
      try {
        success =
            await (widget.openSource?.call(uri) ??
                launchUrl(uri, mode: LaunchMode.externalApplication));
      } catch (_) {}
    }
    if (!success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the official source.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final rows = widget.coverage['drawGroups'][selected] as List;
    final family = selected == 'powerball-double-play'
        ? 'powerball'
        : selected.replaceFirst(RegExp(r'-(midday|evening)$'), '');
    final details = widget.coverage['ruleDetails'][family] as Map;
    final provenance = widget.coverage['drawProvenance'][selected] as List;
    return SafeArea(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Arizona draw results'),
                ),
              ),
              IconButton(
                tooltip: 'Close Arizona draws',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.maybePop(context),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: DropdownButtonFormField<String>(
              initialValue: selected,
              isExpanded: true,
              items: [
                for (final e in ArizonaDrawCollectionSheet.labels.entries)
                  DropdownMenuItem(value: e.key, child: Text(e.value)),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() => selected = value);
                  if (scroll.hasClients) scroll.jumpTo(0);
                }
              },
            ),
          ),
          Expanded(
            child: ListView(
              controller: scroll,
              padding: const EdgeInsets.all(16),
              children: [
                line(
                  'Two recent observed results. Full history and actual payout reports are unavailable.',
                ),
                for (final row in rows)
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          line(
                            '${row['drawDate']}${row['drawTime'] != null ? ' · ${row['drawTime']} Arizona time' : ' · date only'}',
                          ),
                          if (row['drawId'] != null)
                            line('Draw ID: ${row['drawId']}'),
                          line(ArizonaDrawCollectionSheet.resultText(row)),
                          if (selected == 'powerball-xs-os')
                            line(
                              'Random team-logo drawing; independent of football outcomes.',
                            ),
                          if (row['basePrizeAmount'] != null)
                            line(
                              'Base amount is multiplied by the ticket wager; not an actual payout report.',
                            ),
                          TextButton(
                            onPressed: () => open(row['sourceUrl']),
                            child: const Text('Official result source'),
                          ),
                        ],
                      ),
                    ),
                  ),
                ExpansionTile(
                  key: ValueKey('provenance-$selected'),
                  title: const Text('Source observations'),
                  children: [
                    for (final p in provenance)
                      line(
                        '${p['selectedDate'] ?? 'Product page'} · ${p['retrievedAt']}',
                      ),
                  ],
                ),
                ExpansionTile(
                  key: ValueKey('schedule-$selected'),
                  title: const Text('Prize schedules and add-ons'),
                  children: [
                    ArizonaRuleSchedule(rule: widget.coverage['rules'][family]),
                  ],
                ),
                for (final conflict in details['sourceConflicts'])
                  line(conflict),
                TextButton(
                  onPressed: () => open(details['sourceUrl']),
                  child: const Text('Official full rules and instructions'),
                ),
                ExpansionTile(
                  key: ValueKey('rules-$selected'),
                  title: const Text('Source rule wording'),
                  children: [
                    line(
                      'Literal source wording; consult official illustrated instructions for symbols and diagrams. Prize schedules are not actual payouts.',
                    ),
                    for (final section in details['sections'])
                      line(section['text']),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
