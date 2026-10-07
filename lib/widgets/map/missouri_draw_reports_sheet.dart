import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/missouri_draw_reports_loader.dart';

class MissouriDrawReportsSheet extends StatefulWidget {
  const MissouriDrawReportsSheet({
    super.key,
    this.reportsOverride,
    this.loader,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? reportsOverride;
  final MissouriDrawReportsLoader? loader;
  final int initialIndex;
  @override
  State<MissouriDrawReportsSheet> createState() =>
      _MissouriDrawReportsSheetState();
}

class _MissouriDrawReportsSheetState extends State<MissouriDrawReportsSheet> {
  late final _data = widget.reportsOverride != null
      ? Future.value(widget.reportsOverride!)
      : (widget.loader ?? MissouriDrawReportsLoader()).load();
  late int _selected = widget.initialIndex;
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _open(String url) async {
    try {
      if (await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the official source.')),
      );
    }
  }

  static const routes = {
    'Scratchers inventory': 'https://www.molottery.com/scratchers-list.do',
    'Find retailers':
        'https://www.molottery.com/where-to-play/where-to-play.do',
    'Club Keno and options':
        'https://www.molottery.com/club-keno/club-keno.jsp',
    'Pull-Tabs': 'https://www.molottery.com/pull-tabs/pull-tabs.jsp',
    'Promotions and second chance':
        'https://playersclub.molottery.com/promotions',
    'Show Me Cash / EZ Match rules':
        'https://www.molottery.com/show-me-cash/show-me-cash-rules.jsp',
    'Lotto — historical': 'https://www.molottery.com/lotto/winning-numbers.do',
    'Cash4Life — historical':
        'https://www.molottery.com/cash4life/winning-numbers.do',
  };
  String payout(Map r) =>
      r['sourcePayoutLabel'] as String? ?? '\$${r['sourcePayoutDollars']}';
  List<Widget> table(Map v) => [
    if (v['variant'] != null)
      Padding(
        padding: const EdgeInsets.only(top: 16, bottom: 8),
        child: Text(
          v['variant'],
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    if (v['sourceWinnerCount'] != null)
      Text(
        'Source prizes: ${v['sourceWinnerCount']} • Published payout: ${payout(v)}',
      ),
    for (final t in v['tiers'] as List)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 7),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: Text(t['matchLabel'] ?? 'Prize amount')),
            const SizedBox(width: 8),
            Expanded(flex: 2, child: Text(t['prizeLabel'])),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                t['sourcePrizeCount']?.toString() ?? 'Unavailable',
                textAlign: TextAlign.right,
              ),
            ),
          ],
        ),
      ),
  ];
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
            final d = snapshot.data!,
                reports = d['reports'] as List,
                r = reports[_selected] as Map;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Missouri draw reports',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close reports',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
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
                          '${reports[i]['game']} · ${reports[i]['drawDate']} ${reports[i]['sessionLabel'] ?? ''}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      if (_scroll.hasClients) {
                        _scroll.jumpTo(0);
                      }
                      setState(() => _selected = v);
                    }
                  },
                ),
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    children: [
                      Text(
                        'Draw date: ${r['drawDate']} ${r['sessionLabel'] ?? ''}',
                      ),
                      const Text(
                        'Source publication date unavailable • Finality unverified',
                      ),
                      const Text(
                        'Counts are source prizes, not verified distinct tickets or people.',
                      ),
                      if (r['powerPlayMultiplier'] != null)
                        Text('Power Play: ${r['powerPlayMultiplier']}×'),
                      if (r['playBasisCents'] != null)
                        const Text(
                          r'Based on $.50 plays. Base and Wild ball columns remain separate.',
                        ),
                      if (r['sourcePayoutCents'] != null)
                        Text(
                          'Combined source prizes: ${r['sourceWinnerCount']} • Published payout: ${r['sourcePayoutLabel']}',
                        ),
                      if (r['mainSourceWinnerCount'] != null)
                        Text(
                          'Main drawing source prizes: ${r['mainSourceWinnerCount']} • Published payout: \$${r['mainSourcePayoutDollars']} (Double Play excluded)',
                        ),
                      const SizedBox(height: 12),
                      const Text(
                        'Match / source prize label / source prize count',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (r['variants'] != null) ...[
                        for (final v in r['variants']) ...table(v),
                      ] else
                        ...table(r),
                      const Divider(),
                      Text(r['coverage']),
                      const Text(
                        'Jackpot, prize ranges and printed zero labels are retained as published. They do not verify cash options; a zero top label with no winners does not mean a zero jackpot. Unavailable values are not zero.',
                      ),
                      const Text(
                        'No complete statewide claims, retailer win map or exact draw/claim timestamp is provided by these reports.',
                      ),
                      Text('Retrieved: ${d['updatedAt']}'),
                      Text(d['coverage']),
                      TextButton.icon(
                        onPressed: () => _open(r['sourceUrl']),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open this official report'),
                      ),
                      const Divider(),
                      const Text(
                        'Other official game sources',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const Text(
                        'These links do not add winner counts to this report. Scratchers inventory is not store stock or dated claims. Keno, Pull-Tabs, promotions and EZ Match have no verified complete winner feed here. Lotto and Cash4Life are historical games.',
                      ),
                      for (final e in routes.entries)
                        TextButton(
                          onPressed: () => _open(e.value),
                          child: Align(
                            alignment: Alignment.centerLeft,
                            child: Text(e.key),
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
