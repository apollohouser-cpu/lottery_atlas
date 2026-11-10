import 'delaware_coverage_limits.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Presentation of validated Delaware detail joins. Routes are enabled separately.
class DelawareProductSheet extends StatefulWidget {
  const DelawareProductSheet({
    super.key,
    required this.coverage,
    this.openSource,
  });
  final Map<String, dynamic> coverage;
  final Future<bool> Function(Uri)? openSource;

  @override
  State<DelawareProductSheet> createState() => _DelawareProductSheetState();
}

class _DelawareProductSheetState extends State<DelawareProductSheet> {
  String query = '';

  @override
  Widget build(BuildContext context) {
    final rows = (widget.coverage['instantProductDetails'] as List).cast<Map>();
    final filtered = rows.where((row) {
      final product = row['product'] as Map;
      return '${row['gameId']} ${product['name']} ${product['ticketDesigns'].join(' ')}'
          .toLowerCase()
          .contains(query.toLowerCase());
    }).toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Delaware Instant Games'),
        actions: [
          IconButton(
            tooltip: 'Coverage and closeouts',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) => DelawareCoverageLimits(
                  coverage: widget.coverage,
                  openSource: widget.openSource,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Search name or game number',
                ),
                onChanged: (value) => setState(() => query = value),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                'Retained catalog observations. Top-prize inventory is not dated claims or store stock.',
              ),
            ),
            if (filtered.isEmpty)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No matching games.'),
              ),
            Expanded(
              child: ListView.builder(
                itemCount: filtered.length,
                itemBuilder: (context, index) {
                  final row = filtered[index];
                  final product = row['product'] as Map;
                  return ListTile(
                    key: ValueKey('delaware-product-${row['gameId']}'),
                    title: Text('${product['name']} · #${row['gameId']}'),
                    subtitle: Text(
                      '\$${product['cost']} ticket · ${product['topPrizesRemaining']} top prizes remaining\nInventory date: ${product['sourceDate']}',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => DelawareProductDetail(
                          detail: row,
                          openSource: widget.openSource,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DelawareProductDetail extends StatelessWidget {
  const DelawareProductDetail({
    super.key,
    required this.detail,
    this.openSource,
  });
  final Map detail;
  final Future<bool> Function(Uri)? openSource;

  Future<void> open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    var success = false;
    if (uri != null &&
        uri.scheme == 'https' &&
        uri.userInfo.isEmpty &&
        ((uri.host == 'www.delottery.com') ||
            (uri.host == 'delotterywebcontent.blob.core.windows.net' &&
                uri.path.startsWith(
                  '/delottery-site-assets/images/instant-lottery/instant-details/',
                )))) {
      try {
        success =
            await (openSource?.call(uri) ??
                launchUrl(uri, mode: LaunchMode.externalApplication));
      } catch (_) {}
    }
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the official source.')),
      );
    }
  }

  Widget paragraph(String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(value),
  );

  @override
  Widget build(BuildContext context) {
    final product = detail['product'] as Map;
    final instructions = detail['instructions'] as Map;
    final structure = detail['prizeStructure'] as Map?;
    final excluded = detail['prizeStructureExclusion'] as Map?;
    return Scaffold(
      appBar: AppBar(title: Text('${product['name']} · #${detail['gameId']}')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Wrap(
              spacing: 12,
              children: [
                TextButton(
                  onPressed: () => open(context, product['sourceUrl']),
                  child: const Text('Official inventory source'),
                ),
                TextButton(
                  onPressed: () => open(context, instructions['sourceUrl']),
                  child: const Text('Official illustrated rules'),
                ),
              ],
            ),
            paragraph(
              'Ticket designs: ${(product['ticketDesigns'] as List).join(', ')}',
            ),
            paragraph(
              'Ticket price: \$${product['cost']} · Advertised top prize: \$${product['topPrize']}',
            ),
            paragraph(
              'Top prizes remaining: ${product['topPrizesRemaining']} of ${product['originalTopPrizes']} originally offered',
            ),
            paragraph(product['inventoryNote']),
            paragraph(detail['inventoryScope']),
            const Divider(),
            paragraph('How to play'),
            paragraph(instructions['instructionSummary']),
            paragraph(
              'Illustrated source observed: ${instructions['sourceRetrievedAt']}',
            ),
            paragraph(instructions['boundary']),
            for (final qualification in instructions['qualifications'] as List)
              paragraph(qualification),
            const Divider(),
            paragraph(detail['printedStructureScope']),
            if (excluded != null) ...[
              paragraph('Prize structure unavailable'),
              paragraph(excluded['reason']),
            ],
            if (structure != null) ...[
              paragraph('Printed prize structure'),
              paragraph(
                'Tickets ordered: ${structure['statedTicketsOrdered']}',
              ),
              paragraph(
                'Printed prize quantity: ${structure['printedPrizeTotal']} · Printed prize value: \$${structure['printedPrizeValue']}',
              ),
              paragraph(
                'Printed average odds: ${structure['printedAverageOdds']}',
              ),
              for (final tier in structure['tiers'] as List)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(tier['combination']),
                        Text(
                          'Printed WIN: \$${tier['win']} · Odds: 1 in ${tier['oddsOneIn']}',
                        ),
                        Text(
                          'Printed quantity: ${tier['printedWinners']} · Printed value: \$${tier['printedPrizeValue']}',
                        ),
                      ],
                    ),
                  ),
                ),
            ],
            paragraph(
              'Dated claims, all-tier remaining inventory and retailer stock are unavailable.',
            ),
          ],
        ),
      ),
    );
  }
}
