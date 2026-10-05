import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/colorado_draw_reports_loader.dart';

class ColoradoDrawReportsSheet extends StatefulWidget {
  const ColoradoDrawReportsSheet({
    super.key,
    this.reportsOverride,
    this.loader,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? reportsOverride;
  final ColoradoDrawReportsLoader? loader;
  final int initialIndex;
  @override
  State<ColoradoDrawReportsSheet> createState() =>
      _ColoradoDrawReportsSheetState();
}

class _ColoradoDrawReportsSheetState extends State<ColoradoDrawReportsSheet> {
  late final Future<Map<String, dynamic>> _data = widget.reportsOverride != null
      ? Future.value(widget.reportsOverride!)
      : (widget.loader ?? ColoradoDrawReportsLoader()).load();
  late int _selected = widget.initialIndex;
  final _scroll = ScrollController();

  static const _sources = [
    {
      'gameName': 'Scratch catalog',
      'path': '/en/games/scratch/',
      'limitations':
          'Official games and remaining prizes; not store stock or complete claims.',
    },
    {
      'gameName': 'Bonus Draws',
      'path': '/en/games/bonus-draws/',
      'limitations':
          'Separate promotions; results can be posted after the drawing.',
    },
    {
      'gameName': 'Monthly second chance',
      'path': '/en/news/monthly-second-chance/',
      'limitations':
          'Separate promotion with ticket eligibility rules; not ordinary Scratch results.',
    },
    {
      'gameName': 'Lucky for Life — historical',
      'path': '/en/games/luckyforlife/drawings/',
      'limitations':
          'Official history navigation; not a current recurring report feed.',
    },
    {
      'gameName': 'Free Play Zone',
      'path': '/en/games/play-free-digital-games/',
      'limitations':
          'Free digital games, separate from monetary prize reports.',
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
                        'Colorado draw reports',
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
                        'Published Colorado draw reports',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Draw date: ${r['drawDate']} ${r['drawingSession'] ?? ''}',
                      ),
                      const Text(
                        'Reported winners are not verified distinct tickets.',
                      ),
                      if (r['powerPlayMultiplier'] != null)
                        Text(
                          'Power Play multiplier: ${r['powerPlayMultiplier']}',
                        ),
                      const SizedBox(height: 12),
                      for (final tier in r['tiers'] as List)
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${tier['variant']} · ${tier['match']}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                if (tier['wagerDollars'] != null)
                                  Text('Wager: \$${tier['wagerDollars']}'),
                                Text(
                                  tier['available'] == false
                                      ? 'Wager unavailable'
                                      : 'Prize: ${tier['prizeLabel']}',
                                ),
                                Text(
                                  'Reported winners: ${tier['reportedWinners'] ?? 'Unavailable'}',
                                ),
                              ],
                            ),
                          ),
                        ),
                      for (final note in r['prizeNotes'] as List) Text('$note'),
                      if (r['ezMatch'] != null) ...[
                        const Divider(),
                        const Text(
                          'EZ Match — separate from Cash 5 draw tiers',
                        ),
                        Text(
                          'Reported players: ${r['ezMatch']['reportedPlayers']}',
                        ),
                        Text(
                          'Published payout: \$${r['ezMatch']['publishedPayoutDollars']}',
                        ),
                        Text(
                          '${r['ezMatch']['date']} · ${r['ezMatch']['periodLabel']}',
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text('${r['limitations']}'),
                      Text('Retrieved: ${data['retrievedAt']}'),
                      Text('${data['cadence']}'),
                      const Text(
                        'Separate from selected retailer winner rows and Scratch inventory. No combined variant total or retailer allocation.',
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
                            'https://www.coloradolottery.com${source['path']}',
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
