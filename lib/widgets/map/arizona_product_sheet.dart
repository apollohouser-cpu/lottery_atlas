import 'arizona_coverage_limits.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Development presentation of validated coverage; no remote loading or map entry.
class ArizonaProductSheet extends StatefulWidget {
  const ArizonaProductSheet({
    super.key,
    required this.coverage,
    this.openSource,
  });
  final Map<String, dynamic> coverage;
  final Future<bool> Function(Uri)? openSource;

  @override
  State<ArizonaProductSheet> createState() => _ArizonaProductSheetState();
}

class _ArizonaProductSheetState extends State<ArizonaProductSheet> {
  String family = 'scratchers';
  final search = TextEditingController();

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

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

  Widget line(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(text),
  );

  void details(Map product) {
    final presentation = product['rulePresentation'] as Map;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .9,
        child: Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: IconButton(
                tooltip: 'Close product details',
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  line(product['header']),
                  if (product['sourceStatus'] == 'ended') line('Ended game'),
                  line('Source observed: ${product['retrievedAt']}'),
                  line(
                    'Remaining prizes are prize counts, not tickets or retailer stock. Catalog listing does not establish current availability.',
                  ),
                  if (product['progressiveJackpotObserved'] != null)
                    line(
                      'Observed progressive jackpot: ${product['progressiveJackpotObserved']}. Not guaranteed or an actual payout.',
                    ),
                  line('Overall odds: 1 in ${product['overallOddsOneIn']}'),
                  const Divider(),
                  for (final tier in product['tiers'])
                    line(
                      '${tier['prizeLabel']} · Odds 1 in ${tier['oddsOneIn']}\nRemaining prizes: ${tier['remainingPrizes']} of ${tier['originalPrizes']}',
                    ),
                  // This retained wording includes annuity and other prize caveats.
                  ExpansionTile(
                    title: const Text('Full source prize wording'),
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(12),
                        child: Text(product['prizeDetails']),
                      ),
                    ],
                  ),
                  line('How to play'),
                  if (presentation['status'] == 'literal-text')
                    line(presentation['text'])
                  else
                    line(
                      'Consult the official illustrated instructions for matching symbols. Complete symbol instructions are not available here.',
                    ),
                  TextButton(
                    onPressed: () => open(product['sourceUrl']),
                    child: const Text(
                      'Official game and illustrated instructions',
                    ),
                  ),
                  for (final faq in product['faq'] ?? []) line(faq['text']),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final query = search.text.trim().toLowerCase();
    final products = (widget.coverage['products'][family] as List)
        .where(
          (p) =>
              '${p['header']} ${p['gameNumber']}'.toLowerCase().contains(query),
        )
        .toList();
    final endings = widget.coverage['endingNotices'][family] as Map;
    return SafeArea(
      child: Column(
        children: [
          Row(
            children: [
              const Expanded(
                child: Padding(
                  padding: EdgeInsets.all(12),
                  child: Text('Arizona instant games'),
                ),
              ),
              IconButton(
                tooltip: 'Close Arizona products',
                onPressed: () => Navigator.maybePop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: DropdownButtonFormField<String>(
              initialValue: family,
              isExpanded: true,
              items: const [
                DropdownMenuItem(
                  value: 'scratchers',
                  child: Text('Scratchers'),
                ),
                DropdownMenuItem(value: 'fast-play', child: Text('Fast Play')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    family = value;
                    search.clear();
                  });
                }
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              controller: search,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                labelText: 'Search name or game number',
                suffixIcon: IconButton(
                  tooltip: 'Clear product search',
                  icon: const Icon(Icons.clear),
                  onPressed: () => setState(search.clear),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(12),
              children: [
                line(
                  'Source-listed products; no retailer inventory or ticket availability.',
                ),
                ArizonaCoverageLimits(coverage: widget.coverage),
                if (products.isEmpty)
                  line('No matching games. Clear search to show all products.'),
                for (final product in products)
                  ListTile(
                    title: Text(
                      (product['header'] as String).split('\n').first,
                    ),
                    subtitle: Text(
                      product['sourceStatus'] == 'ended'
                          ? 'Ended game'
                          : 'Start date listed; availability not confirmed',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => details(product),
                  ),
                ExpansionTile(
                  title: const Text('Ending notices'),
                  children: [
                    line('Observed: ${endings['retrievedAt']}'),
                    for (final conflict in endings['sourceConflicts'])
                      line(conflict),
                    for (final notice in endings['notices'])
                      ListTile(
                        title: Text(
                          '${notice['title']} #${notice['gameNumber']}',
                        ),
                        subtitle: Text(
                          '${notice['dateLabel']}: ${notice['dateText']}',
                        ),
                        onTap: () => open(notice['sourceUrl']),
                      ),
                    line(
                      'Dates retain source labels. No adjusted claim deadline is calculated.',
                    ),
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
