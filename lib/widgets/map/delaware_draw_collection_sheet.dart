import 'delaware_reference_sheet.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Retained observed results only. Never supplies map activity or winner counts.
class DelawareDrawCollectionSheet extends StatefulWidget {
  const DelawareDrawCollectionSheet({
    super.key,
    required this.coverage,
    this.openSource,
  });
  final Map<String, dynamic> coverage;
  final Future<bool> Function(Uri)? openSource;
  @override
  State<DelawareDrawCollectionSheet> createState() =>
      _DelawareDrawCollectionSheetState();
}

class _DelawareDrawCollectionSheetState
    extends State<DelawareDrawCollectionSheet> {
  String? selected;
  static String group(Map row) =>
      '${row['game']}${row['session'] == null ? '' : ' · ${row['session']}'}';

  Future<void> open(String url) async {
    final uri = Uri.tryParse(url);
    var success = false;
    if (uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'www.delottery.com' &&
        uri.userInfo.isEmpty) {
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
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Text(text),
  );

  @override
  Widget build(BuildContext context) {
    final results = (widget.coverage['draws']['results'] as List).cast<Map>();
    final groups = results.map(group).toSet().toList();
    final current = selected ?? groups.first;
    final rows = results.where((row) => group(row) == current).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Delaware Drawings')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 12,
              children: [
                for (final reports in [false, true])
                  TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => DelawareReferenceSheet(
                          coverage: widget.coverage,
                          reports: reports,
                          openSource: widget.openSource,
                        ),
                      ),
                    ),
                    child: Text(
                      reports
                          ? 'Published count reports'
                          : 'Prize schedules and rules',
                    ),
                  ),
              ],
            ),

            line(
              'Retained observations with original draw and source dates. This is not a live or complete result history.',
            ),
            DropdownButtonFormField<String>(
              initialValue: current,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Game and session'),
              items: groups
                  .map(
                    (name) => DropdownMenuItem(value: name, child: Text(name)),
                  )
                  .toList(),
              onChanged: (value) => setState(() => selected = value),
            ),
            line(
              'Draw results are not winning-ticket counts or geographic win activity. Missing sessions are unavailable, never zero.',
            ),
            for (final row in rows)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      line(
                        '${row['game']} · ${row['drawDate']}${row['session'] == null ? '' : ' · ${row['session']}'}',
                      ),
                      if (row['digits'] != null)
                        line(
                          'Drawn digits: ${(row['digits'] as List).join(' ')}',
                        ),
                      if (row['numbers'] != null)
                        line(
                          'Drawn numbers: ${(row['numbers'] as List).join(' · ')}',
                        ),
                      if (row['powerball'] != null)
                        line('Powerball: ${row['powerball']}'),
                      if (row['specialBall'] != null)
                        line(
                          '${row['game'] == 'Mega Millions' ? 'Mega Ball' : 'Star Ball'}: ${row['specialBall']}',
                        ),
                      if (row['powerPlay'] != null)
                        line('Power Play: ${row['powerPlay']}x'),
                      if (row['allStarBonus'] != null)
                        line('All Star Bonus: ${row['allStarBonus']}x'),
                      if (row['gameNumber'] != null)
                        line('Game number: ${row['gameNumber']}'),
                      if (row['displayTime'] != null)
                        line(
                          'Source display time: ${row['displayTime']} · timezone unspecified',
                        ),
                      if (row['bonusMultiplier'] != null)
                        line('Keno Bonus: ${row['bonusMultiplier']}x'),
                      if (row['teams'] != null) ...[
                        line('Drawn team symbols'),
                        for (final team in row['teams'] as List)
                          line('${team['code']} · ${team['name']}'),
                      ],
                      line(row['coverage']),
                      line(
                        'Source observed: ${row['provenance']['retrievedAt']}',
                      ),
                      TextButton(
                        onPressed: () => open(row['provenance']['url']),
                        child: const Text('Official result source'),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
