import 'dart:convert';
import '../../services/south_dakota_collection_contract.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/south_dakota_collection_loader.dart';

class SouthDakotaDrawCollectionSheet extends StatefulWidget {
  const SouthDakotaDrawCollectionSheet({
    super.key,
    this.reportsOverride,
    this.loader,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? reportsOverride;
  final SouthDakotaCollectionLoader? loader;
  final int initialIndex;
  @override
  State<SouthDakotaDrawCollectionSheet> createState() =>
      _SouthDakotaDrawCollectionSheetState();
}

class _SouthDakotaDrawCollectionSheetState
    extends State<SouthDakotaDrawCollectionSheet> {
  late final _data = widget.reportsOverride != null
      ? Future.value(widget.reportsOverride!)
      : (widget.loader ?? SouthDakotaCollectionLoader()).load();
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

  Widget entry(String title, List<String> lines) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Keep each field reachable independently of long source combinations.
        Semantics(
          container: true,
          child: Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        for (final line in lines) Semantics(container: true, child: Text(line)),
      ],
    ),
  );

  List<Widget> rules(List blocks) => [
    for (final b in blocks)
      if (b['kind'] == 'table') ...[
        for (final row in b['rows'])
          entry('Published schedule', [
            for (var i = 0; i < row.length; i++)
              '${b['columns'][i]}: ${row[i].isEmpty ? "(blank in source)" : row[i]}',
          ]),
      ] else
        entry(
          b['kind'] == 'heading' ? b['text'] : '',
          b['kind'] == 'heading' ? [] : [b['text']],
        ),
  ];

  List<Widget> details(Map d, Map r) {
    final report =
        (d['reports'] as List).firstWhere(
              (p) =>
                  p['game'] == r['game'] &&
                  p['variant'] == r['variant'] &&
                  p['drawId'] == r['drawId'],
            )
            as Map;
    final slug = (r['sourceUrl'] as String)
        .split('/')
        .where((s) => s.isNotEmpty)
        .last;
    final schedule =
        (d['schedules'] as List).firstWhere((s) => s['slug'] == slug) as Map;
    final teams = jsonDecode(southDakotaTeamsJson) as Map;
    return [
      entry('${r['game']} · ${r['variant']}', [
        'Local draw date: ${r['drawDate']} · America/Chicago',
        'Source calendar date; exact physical draw time is not inferred.',
        r['game'] == 'Xs and Os'
            ? 'Teams: ${(r['primary'] as List).map((v) => teams[v]).join(' · ')}'
            : 'Numbers: ${(r['primary'] as List).join(' · ')}',
        if ((r['secondary'] as List).isNotEmpty)
          'Special ball: ${(r['secondary'] as List).join(' · ')}',
        if (r['multiplier'] != null) 'Draw multiplier: ${r['multiplier']}X',
      ]),
      if (report['limitation'] != null) Text(report['limitation']),
      if (report['countUnit'] != null) Text(report['countUnit']),
      for (final t in report['tiers'])
        entry(t['match'], [
          'SD Winners (source label): ${t['sdWinners']}',
          if (t['sdOptionWinners'] != null)
            'SD ${report['optionLabel']}: ${t['sdOptionWinners']}',
          if (t['prizeAmountDollars'] != null)
            'Source prize dollars: ${t['prizeAmountDollars']}',
          if (t['prizeLabel'] != null) t['prizeLabel'],
        ]),
      OutlinedButton(
        onPressed: () =>
            _open('https://lottery.sd.gov/winners/winning-numbers/'),
        child: const Text('Official dated results search'),
      ),
      const Text(
        'Literal published rules and schedules — separate from dated reports.',
      ),
      if (r['game'] == 'Million 4 Life')
        const Text(
          'Source wording retains Lucky for Life references; these are the Millionaire for Life page’s literal rules.',
        ),
      if (r['game'] == 'Mega Millions')
        const Text(
          'The static source table lists base amounts. These are not final multiplier ticket payouts. Winner counts are unavailable here, not zero.',
        ),
      for (final section in schedule['sections']) ...[
        entry(section['title'], []),
        ...rules(section['blocks']),
      ],
      Text('Retrieved: ${d['retrievedAt']}'),
      const Text(
        'Bounded recent results only. No retailer joins or complete claims history.',
      ),
      OutlinedButton(
        onPressed: () => _open(r['sourceUrl']),
        child: const Text('Open official game page'),
      ),
    ];
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
            final d = snapshot.data!,
                reports = d['results'] as List,
                r = reports[_selected] as Map;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                LayoutBuilder(
                  builder: (context, constraints) {
                    const title = Text(
                      'South Dakota results and schedules',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    );
                    final actions = Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          tooltip: 'Official game source',
                          onPressed: () => _open(r['sourceUrl']),
                          icon: const Icon(Icons.open_in_new),
                        ),
                        IconButton(
                          tooltip: 'Close reports',
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.close),
                        ),
                      ],
                    );
                    if (MediaQuery.textScalerOf(context).scale(20) > 30) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          title,
                          Align(
                            alignment: Alignment.centerRight,
                            child: actions,
                          ),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        const Expanded(child: title),
                        actions,
                      ],
                    );
                  },
                ),
                DropdownButton<int>(
                  isExpanded: true,
                  value: _selected,
                  items: [
                    for (var i = 0; i < reports.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(
                          '${reports[i]['game']} · ${reports[i]['variant']} · ${reports[i]['drawDate']}',
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
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && _scroll.hasClients) _scroll.jumpTo(0);
                      });
                    }
                  },
                ),
                Expanded(
                  child: ListView(
                    key: ValueKey(_selected),
                    controller: _scroll,
                    children: [...details(d, r)],
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
