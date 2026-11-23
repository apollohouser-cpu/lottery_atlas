import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Literal detail-verified inventory; remaining prizes are not store stock.
class ConnecticutScratchDetail extends StatelessWidget {
  const ConnecticutScratchDetail({
    super.key,
    required this.game,
    this.openSource,
  });
  final Map<String, dynamic> game;
  final Future<bool> Function(Uri)? openSource;

  Widget line(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(text),
  );

  Future<void> open(BuildContext context) async {
    final uri = Uri.tryParse(game['sourceUrl'] as String);
    var success = false;
    if (uri != null &&
        uri.scheme == 'https' &&
        {'ctlottery.com', 'www.ctlottery.org'}.contains(uri.host) &&
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
        const SnackBar(
          content: Text('Could not open the official game source.'),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (game['id'].toString() == '1725') {
      return Scaffold(
        appBar: AppBar(title: const Text('Connecticut Scratch')),
        body: const Padding(
          padding: EdgeInsets.all(16),
          child: Text(
            'Game 1725 excluded: catalog cash value conflicts with the detail rules.',
          ),
        ),
      );
    }
    final annuity = (game['prizeTiers'] as List).any(
      (tier) => tier['prizeCategory'] == 'annuity',
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Connecticut Scratch detail')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            line('${game['name']} · Game ${game['id']}'),
            line('Ticket price: \$${game['cost']}'),
            line('Source inventory date: ${game['sourceDate']}'),
            line(
              game['status'] == 'ended'
                  ? 'Sales ended'
                  : 'Source status: ${game['status']}',
            ),
            line('Game start: ${game['startDate']}'),
            line('Sales end: ${game['endDate'] ?? 'Not supplied / TBD'}'),
            line(
              'Last day to claim: ${game['lastDayToRedeem'] ?? 'Not supplied / TBD'}',
            ),
            if (annuity) ...[
              line('Advertised top prize: ${game['topPrizeLabel']}'),
              line('Verified top cash option: \$${game['topPrize']}'),
            ] else
              line('Top prize: \$${game['topPrize']}'),
            line('${game['inventoryNote']}'),
            line(
              'Cumulative unclaimed prizes, not dated wins or verified store stock. '
              'An ended game is not advertised as currently on sale.',
            ),
            TextButton(
              onPressed: () => open(context),
              child: const Text('Official game source'),
            ),
            for (final tier in game['prizeTiers'] as List) ...[
              const Divider(),
              line(
                'Prize: ${tier['prizeLabel']}${tier['prizeCategory'] == 'annuity' ? ' (annuity)' : ''}',
              ),
              line('Original prizes: ${tier['total']}'),
              line('Unclaimed prizes: ${tier['remaining']}'),
            ],
          ],
        ),
      ),
    );
  }
}
