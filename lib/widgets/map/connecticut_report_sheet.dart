import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Literal source report rows, with no cross-tier or distinct-ticket total.
class ConnecticutReportSheet extends StatelessWidget {
  const ConnecticutReportSheet({
    super.key,
    required this.report,
    this.openSource,
  });
  final Map<String, dynamic> report;
  final Future<bool> Function(Uri)? openSource;

  Widget line(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Text(text),
  );

  List<Widget> tier(Map row, {required bool doublePlay}) => [
    const Divider(),
    line('Match: ${row['match']}'),
    if (row.containsKey('reportedWinningPlays'))
      line('Winning Plays: ${row['reportedWinningPlays']}')
    else
      line(
        '${report['countLabel'] ?? 'Reported winning tickets'}: ${row['reportedWinningTickets']}',
      ),
    if (row['countMeaning'] != null) line('${row['countMeaning']}'),
    if (row['prizeLabel'] != null) line('${row['prizeLabel']}'),
    if (row['reportedPrizeAmount'] != null)
      line('Reported prize amount: \$${row['reportedPrizeAmount']}'),
    if (row['minimumWagerPrizeLabel'] != null)
      line('Minimum-wager reference prize: ${row['minimumWagerPrizeLabel']}'),
    if (row['numericPrizeWithheldReason'] != null)
      line('Numeric prize withheld: ${row['numericPrizeWithheldReason']}'),
    if (!doublePlay && report['game'] == 'powerball') ...[
      line('Power Play count: ${row['withPowerPlay'] ?? 'Not supplied'}'),
      if (row['powerPlayPrizeAmount'] != null)
        line('Power Play reference prize: \$${row['powerPlayPrizeAmount']}'),
    ],
  ];

  Future<void> open(BuildContext context) async {
    final uri = Uri.tryParse(report['sourceUrl'] as String);
    var success = false;
    if (uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'ctlottery.com' &&
        uri.userInfo.isEmpty &&
        (!uri.hasPort || uri.port == 443)) {
      try {
        success =
            await (openSource?.call(uri) ??
                launchUrl(uri, mode: LaunchMode.externalApplication));
      } catch (_) {}
    }
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the official report.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Connecticut count report')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          line(
            '${report['game']}${report['session'] == null ? '' : ' · ${report['session']}'}',
          ),
          line('Draw date: ${report['drawDate']}'),
          line('${report['dateEvidence']}'),
          line(
            'Saved source report. Counts are not selling-location activity. '
            'No distinct-ticket total is derived. Prize amounts do not establish individual cash payments.',
          ),
          for (final limitation in report['limitations'] as List)
            line('$limitation'),
          TextButton(
            onPressed: () => open(context),
            child: const Text('Official report source'),
          ),
          for (final row in report['rows'] as List)
            ...tier(row as Map, doublePlay: false),
          if (report['doublePlayRows'] is List) ...[
            line('Double Play — separate report tiers'),
            for (final row in report['doublePlayRows'])
              ...tier(row as Map, doublePlay: true),
          ],
        ],
      ),
    ),
  );
}
