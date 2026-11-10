import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class DelawareCoverageLimits extends StatelessWidget {
  const DelawareCoverageLimits({
    super.key,
    required this.coverage,
    this.openSource,
  });
  final Map<String, dynamic> coverage;
  final Future<bool> Function(Uri)? openSource;
  Future<void> open(BuildContext context, String url) async {
    var ok = false;
    final uri = Uri.tryParse(url);
    if (uri != null &&
        uri.scheme == 'https' &&
        uri.host == 'www.delottery.com' &&
        uri.userInfo.isEmpty) {
      try {
        ok =
            await (openSource?.call(uri) ??
                launchUrl(uri, mode: LaunchMode.externalApplication));
      } catch (_) {}
    }
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the official source.')),
      );
    }
  }

  Widget paragraph(String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 7),
    child: Text(value),
  );
  @override
  Widget build(BuildContext context) {
    final source = coverage['productEvidence']['closeout'] as Map;
    return Scaffold(
      appBar: AppBar(title: const Text('Delaware coverage and closeouts')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            paragraph('Retained source observations'),
            paragraph(
              'Results cover selected observed drawings, not live results or complete history. Published prize schedules are not actual payouts. Count reports preserve their source units and do not establish unique people, tickets or statewide totals.',
            ),
            paragraph(
              'Lucky For Life is historical/legacy coverage. Its presence here does not establish current operation or a retirement date.',
            ),
            paragraph(
              'Instant Games inventory covers top prizes only. Printed prize structures describe ordered-ticket quantities, not remaining prizes or dated claims. Shared ticket designs use one printed game identity. Conflicting structures remain excluded with explanations.',
            ),
            paragraph(
              'No verified within-state win locations, retailer stock or retailer-to-win joins are available. Draw numbers do not create map heat points.',
            ),
            paragraph(
              'Complete retired catalogs, complete promotion archives and ten-year history are unavailable. Sports betting, video lottery, casino table games and iGaming are outside this coverage. No ticket entry, registration or betting is performed.',
            ),
            const Divider(),
            paragraph('Announced sales closeouts'),
            paragraph(
              'These are retained announced end-of-sales dates, not prize-claim deadlines or a complete retired catalog. Check the official source for current notices.',
            ),
            paragraph('Source observed: ${source['retrievedAt']}'),
            TextButton(
              onPressed: () => open(context, source['url']),
              child: const Text('Official closeout schedule'),
            ),
            for (final row in coverage['closeouts'] as List)
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Game #${row['gameId']}'),
                      Text('Launch date: ${row['dateLaunched']}'),
                      Text(
                        'Announced end of sales: ${row['announcedEndOfSales']}',
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
