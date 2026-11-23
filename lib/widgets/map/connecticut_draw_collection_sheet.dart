import 'connecticut_coverage_limits.dart';
import 'connecticut_report_sheet.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Presentation of reviewed result snapshots; never contributes map activity.
class ConnecticutDrawCollectionSheet extends StatefulWidget {
  const ConnecticutDrawCollectionSheet({
    super.key,
    required this.coverage,
    this.openSource,
  });
  final Map<String, dynamic> coverage;
  final Future<bool> Function(Uri)? openSource;

  @override
  State<ConnecticutDrawCollectionSheet> createState() =>
      _ConnecticutDrawCollectionSheetState();
}

class _ConnecticutDrawCollectionSheetState
    extends State<ConnecticutDrawCollectionSheet> {
  String? selected;
  static const names = {
    'powerball': 'Powerball',
    'doubleplay': 'Double Play',
    'xsandos': 'Xs & Os',
    'megamillions': 'Mega Millions',
    'mfl': 'Millionaire for Life',
    'lotto': 'Lotto',
    'keno': 'Keno',
    'cash5': 'Cash5',
    'play3': 'Play3',
    'play4': 'Play4',
  };
  String group(Map row) =>
      '${names[row['game']] ?? row['game']}${row['session'] == null ? '' : ' · ${row['session']}'}';

  Future<void> open(String url) async {
    final uri = Uri.tryParse(url);
    var success = false;
    if (uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'ctlottery.com' &&
        uri.userInfo.isEmpty &&
        (!uri.hasPort || uri.port == 443)) {
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

  Widget line(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(text),
  );

  @override
  Widget build(BuildContext context) {
    final rows = (widget.coverage['draws'] as List).cast<Map>();
    final groups = rows.map(group).toSet().toList();
    final current = groups.contains(selected)
        ? selected
        : (groups.isEmpty ? null : groups.first);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connecticut Drawings'),
        actions: [
          IconButton(
            tooltip: 'Coverage and exclusions',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    ConnecticutCoverageLimits(openSource: widget.openSource),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            line(
              'Saved result snapshots, not a live feed or complete history. '
              'Results do not establish winning-ticket counts or selling locations.',
            ),
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final name in groups)
                  ChoiceChip(
                    label: Text(name),
                    selected: current == name,
                    onSelected: (_) => setState(() => selected = name),
                  ),
              ],
            ),
            if (groups.isEmpty) line('No reviewed result snapshots available.'),
            for (final row in rows.where((row) => group(row) == current)) ...[
              line('Draw date: ${row['drawDate']}'),
              for (final reference
                  in (widget.coverage['ruleReferences'] as List? ?? [])
                      .cast<Map<String, dynamic>>()
                      .where(
                        (reference) =>
                            reference['game'] ==
                            (row['game'] == 'doubleplay'
                                ? 'powerball'
                                : row['game']),
                      )) ...[
                for (final note in reference['notes'] as List? ?? [])
                  line('$note'),
                TextButton(
                  onPressed: () => open(reference['sourceUrl'] as String),
                  child: const Text('Official game rules (external PDF)'),
                ),
                line(
                  'Rule link retained from the source page; PDF content is not available offline.',
                ),
              ],

              for (final report
                  in (widget.coverage['reports'] as List? ?? [])
                      .cast<Map<String, dynamic>>()
                      .where(
                        (report) =>
                            report['game'] ==
                                (row['game'] == 'doubleplay'
                                    ? 'powerball'
                                    : row['game']) &&
                            report['session'] == row['session'] &&
                            report['drawDate'] == row['drawDate'],
                      ))
                TextButton(
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute<void>(
                      builder: (_) => ConnecticutReportSheet(
                        report: report,
                        openSource: widget.openSource,
                      ),
                    ),
                  ),
                  child: Text(
                    row['game'] == 'doubleplay'
                        ? 'Powerball / Double Play count report'
                        : 'Dated count report',
                  ),
                ),

              if (row['gameNumber'] != null)
                line('Game number: ${row['gameNumber']}'),
              if (row['teams'] is List)
                for (final team in row['teams']) line('$team')
              else
                line('Numbers: ${(row['numbers'] as List).join(' · ')}'),
              if (row['special'] is Map)
                line('${row['special']['label']}: ${row['special']['number']}'),
              if (row['game'] == 'powerball' && row['powerPlay'] != null)
                line('Power Play: ${row['powerPlay']}X'),
              if (row['bonus'] != null) line('Bonus: ${row['bonus']}'),
              if (row['game'] == 'keno')
                line(
                  'Saved Keno game only. The source supplies a date, not a verified draw time.',
                ),
              if (row['game'] == 'megamillions')
                line(
                  'Payout counts withheld: source aggregate and multiplier counts remain unresolved.',
                ),
              TextButton(
                onPressed: () => open(row['sourceUrl'] as String),
                child: const Text('Official result source'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
