import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Bounded scope; absence of records never means zero activity.
class ConnecticutCoverageLimits extends StatelessWidget {
  const ConnecticutCoverageLimits({super.key, this.openSource});
  final Future<bool> Function(Uri)? openSource;

  Future<void> open(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    var success = false;
    try {
      success =
          await (openSource?.call(uri) ??
              launchUrl(uri, mode: LaunchMode.externalApplication));
    } catch (_) {}
    if (!success && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the official source.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(title: const Text('Connecticut coverage')),
    body: SafeArea(
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Saved snapshots and source dates',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Draws and count reports are retained observations, not a live feed or complete history. '
            'Each result, report and Scratch inventory retains its own source date. '
            'Retrieval does not make an older observation current.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Counts and locations',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'No complete all-tier claims or verified selling-location activity is established. '
            'Missing records do not mean zero winners. Results, remaining prizes and promotional entries '
            'do not create map points or distinct-ticket totals. Play3/Play4 report groups overlap.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Excluded and limited coverage',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'Scratch game 1725 is excluded because catalog cash values conflict with the detail rules. '
            'Ended games are labeled sales ended; an unknown claim deadline remains unknown. '
            'Mega Millions payout counts are withheld because aggregate and multiplier counts do not reconcile. '
            'Life-prize API amounts with unverified meaning are withheld; annual prize labels are preserved.',
          ),
          const SizedBox(height: 16),
          const Text(
            'Fast Play and historical games',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'The official rules index provides a Fast Play rules route. This does not establish '
            'current Fast Play game inventory or results. Historical games have no complete archive here; '
            'retained rules are not evidence of a current recurring schedule.',
          ),
          TextButton(
            onPressed: () =>
                open(context, 'https://ctlottery.com/lottery-rules'),
            child: const Text('Official rules index — including Fast Play'),
          ),
          const SizedBox(height: 16),
          const Text(
            'Second Chance and promotions',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const Text(
            'These are separate programs. Entries and promotional awards are not included in '
            'retail lottery draw counts or mapped activity. Source links require an internet connection.',
          ),
          TextButton(
            onPressed: () =>
                open(context, 'https://ct.secondchancebonuszone.com/'),
            child: const Text('Official Second Chance program'),
          ),
          TextButton(
            onPressed: () => open(context, 'https://ctlottery.com/promotions'),
            child: const Text('Official promotions'),
          ),
        ],
      ),
    ),
  );
}
