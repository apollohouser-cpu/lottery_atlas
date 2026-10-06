import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/oregon_draw_reports_loader.dart';

class OregonDrawReportsSheet extends StatefulWidget {
  const OregonDrawReportsSheet({
    super.key,
    this.reportsOverride,
    this.loader,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? reportsOverride;
  final OregonDrawReportsLoader? loader;
  final int initialIndex;
  @override
  State<OregonDrawReportsSheet> createState() => _OregonDrawReportsSheetState();
}

class _OregonDrawReportsSheetState extends State<OregonDrawReportsSheet> {
  late final Future<Map<String, dynamic>> _data = widget.reportsOverride != null
      ? Future.value(widget.reportsOverride!)
      : (widget.loader ?? OregonDrawReportsLoader()).load();
  late int _selected = widget.initialIndex;
  final _scroll = ScrollController();

  static const _sources = [
    {
      'gameName': 'Keno and options',
      'path': '/jackpot/keno/',
      'limitations':
          'Keno, Special Keno, Bulls-Eye, Multiplier, 8-spot bonus and Keno To Go. No winner-count feed here.',
    },
    {
      'gameName': 'Scratch-its catalog',
      'path': '/scratch-its/list/',
      'limitations':
          'Unclaimed prizes are not store stock or recent winning activity.',
    },
    {
      'gameName': 'Second Chance',
      'path': '/second-chance/',
      'limitations':
          'Separate Scratch-it drawings; official dates, prizes and results.',
    },
    {
      'gameName': 'Raffle',
      'path': '/jackpot/raffle/',
      'limitations':
          'Seasonal drawing. Advertised prize allocation is not claims received.',
    },
    {
      'gameName': 'Video Lottery',
      'path': '/video-lottery/',
      'limitations':
          'Separate product. No retailer winning counts provided here.',
    },
    {
      'gameName': 'Sports',
      'path': '/sports/',
      'limitations':
          'Official provider information; no wagering or count integration.',
    },
    {
      'gameName': 'Lucky Lines — historical',
      'path': '/jackpot/lucky-lines/',
      'limitations': 'Final draw January 12, 2025; replaced by Cash Pop.',
    },
    {
      'gameName': 'Mega Millions — historical',
      'path': '/mega-millions/mega-millions-winning-numbers-previous/',
      'limitations':
          'Previous game version, separate from current aggregate reports.',
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
                        'Oregon draw reports',
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
                          '${reports[i]['game']} · ${reports[i]['drawDate']} ${reports[i]['drawingTime'] ?? ''}',
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
                        'Published Oregon draw reports',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Draw date: ${r['drawDate']} ${r['drawingTime'] ?? ''}',
                      ),
                      Text('Draw number: ${r['drawNumber']}'),
                      const Text('Source publication date unavailable'),
                      const SizedBox(height: 12),
                      const Text(
                        'Distinct ticket and person counts: unverified',
                      ),
                      Text('${r['countUnit']}'),
                      Text('${r['dateBasis']}'),
                      if (r['multiplier'] != null)
                        Text(
                          'Published Power Play multiplier: ${r['multiplier']}× (context only)',
                        ),
                      if (r['tiers'] == null) ...[
                        Text(
                          'Reported Oregon winners: ${r['reportedWinners']}',
                        ),
                        Text(
                          'Published payout: \$${(r['publishedPayoutDollars'] as num).toStringAsFixed(2)}',
                        ),
                        const Text(
                          'Aggregate payout, not a jackpot or prize-tier breakdown.',
                        ),
                      ] else ...[
                        const Text(
                          'Published prize rows',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        for (final tier in r['tiers'] as List)
                          ListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text('${tier['prizeText']}'),
                            subtitle: Text(
                              '${tier['match'] ?? 'Source prize row(s) ${(tier['sourceRows'] as List).join(', ')}'} · Reported winners: ${tier['reportedWinners']}',
                            ),
                          ),
                        const Text(
                          'Rows are not summed into distinct tickets. Shared prizes and lifetime payments retain source meaning.',
                        ),
                      ],
                      const SizedBox(height: 12),
                      Text('${r['limitations']}'),
                      Text('Retrieved: ${data['retrievedAt']}'),
                      Text('${data['cadence']}'),
                      const Text(
                        'Draw reports are separate from the retailer directory and Scratch inventory. No retailer allocation or complete statewide claims coverage.',
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
                            'https://www.oregonlottery.org${source['path']}',
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
