import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/ohio_payout_reports_loader.dart';

class OhioPayoutReportsSheet extends StatefulWidget {
  const OhioPayoutReportsSheet({
    super.key,
    this.reportsOverride,
    this.loader,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? reportsOverride;
  final OhioPayoutReportsLoader? loader;
  final int initialIndex;
  @override
  State<OhioPayoutReportsSheet> createState() => _OhioPayoutReportsSheetState();
}

class _OhioPayoutReportsSheetState extends State<OhioPayoutReportsSheet> {
  late final Future<Map<String, dynamic>> _data = widget.reportsOverride != null
      ? Future.value(widget.reportsOverride!)
      : (widget.loader ?? OhioPayoutReportsLoader()).load();
  late int _selected = widget.initialIndex;
  final _scroll = ScrollController();

  static const _sources = [
    {
      'gameName': 'Powerball / Power Play',
      'path': '/games/draw-games/powerball',
      'limitations':
          'Official game and results. Ohio tier counts are not provided here.',
    },
    {
      'gameName': 'Mega Millions',
      'path': '/games/draw-games/mega-millions',
      'limitations':
          'Built-in multiplier game. Ohio tier counts are not provided here.',
    },
    {
      'gameName': 'Millionaire for Life',
      'path': '/games/draw-games/millionaire-for-life',
      'limitations':
          'Top prizes are annual payments for life; tier counts are not verified here.',
    },
    {
      'gameName': 'Classic Lotto / KICKER',
      'path': '/games/draw-games/classic-lotto',
      'limitations':
          'KICKER is a separate add-on; its payout is not inferred from Classic Lotto.',
    },
    {
      'gameName': 'KENO / Booster',
      'path': '/games/keno',
      'limitations':
          'Monitor game. No complete tier-count history in this app.',
    },
    {
      'gameName': 'The Lucky One',
      'path': '/games/the-lucky-one',
      'limitations':
          'Separate monitor game. Fixed prizes do not establish winner counts.',
    },
    {
      'gameName': 'EZPLAY',
      'path': '/games/ezplay-games',
      'limitations':
          'Terminal instant tickets; no drawing. Separate from Scratch-Offs.',
    },
    {
      'gameName': 'Cash Explosion',
      'path': '/games/cash-explosion-show',
      'limitations':
          'Television game show; selected releases are not recurring draw results.',
    },
    {
      'gameName': 'Lucky for Life — historical',
      'path': '/games/draw-games/lucky-for-life',
      'limitations':
          'Last draw February 21, 2026. Not a current recurring schedule.',
    },
  ];

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    final ok = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the official report.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .9,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _data,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: snapshot.hasError
                    ? const Text(
                        'Draw reports unavailable. Please try again later.',
                      )
                    : const CircularProgressIndicator(),
              );
            }
            final data = snapshot.data!;
            final reports = data['reports'] as List;
            final r = reports[_selected] as Map;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Ohio draw payouts',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close reports',
                    ),
                  ],
                ),
                DropdownButton<int>(
                  isExpanded: true,
                  value: _selected,
                  items: [
                    for (var i = 0; i < reports.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(
                          '${reports[i]['game']} · ${reports[i]['drawDate']} ${reports[i]['drawingSession'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      if (_scroll.hasClients) _scroll.jumpTo(0);
                      setState(() => _selected = value);
                    }
                  },
                ),
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    children: [
                      const Text(
                        'Published Ohio draw payouts',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Draw date: ${r['drawDate']} ${r['drawingSession'] ?? ''}',
                      ),
                      Text('Draw number: ${r['drawNumber']}'),
                      const Text('Source publication date unavailable'),
                      const SizedBox(height: 12),
                      Text(
                        'Published payout: \$${(r['publishedPayoutDollars'] as num).toStringAsFixed(2)}',
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Text('Winner and ticket counts: unavailable'),
                      const SizedBox(height: 12),
                      Text('${r['limitations']}'),
                      Text('Retrieved: ${data['retrievedAt']}'),
                      Text('${data['cadence']}'),
                      const Text(
                        'Payout dollars are separate from selected retailer releases and Scratch inventory. Tier counts are not verified.',
                      ),
                      Align(
                        alignment: Alignment.centerLeft,
                        child: TextButton.icon(
                          onPressed: () => _open(r['sourceUrl'] as String),
                          icon: const Icon(Icons.open_in_new),
                          label: const Text('Open official game report'),
                        ),
                      ),
                      const Divider(),
                      for (final source in _sources)
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${source['gameName']}'),
                          subtitle: Text('${source['limitations']}'),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () => _open(
                            'https://www.ohiolottery.com${source['path']}',
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
