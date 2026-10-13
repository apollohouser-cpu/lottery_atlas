import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/louisiana_draw_reports_loader.dart';

class LouisianaDrawReportsSheet extends StatefulWidget {
  const LouisianaDrawReportsSheet({
    super.key,
    this.reportsOverride,
    this.loader,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? reportsOverride;
  final LouisianaDrawReportsLoader? loader;
  final int initialIndex;
  @override
  State<LouisianaDrawReportsSheet> createState() =>
      _LouisianaDrawReportsSheetState();
}

class _LouisianaDrawReportsSheetState extends State<LouisianaDrawReportsSheet> {
  late final _data = widget.reportsOverride != null
      ? Future.value(widget.reportsOverride!)
      : (widget.loader ?? LouisianaDrawReportsLoader()).load();
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
        Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        for (final line in lines) Text(line),
      ],
    ),
  );

  List<Widget> reportRows(Map r) => [
    if (r['digits'] != null)
      Text('Digits: ${(r['digits'] as List).join(' · ')}'),
    if (r['numbers'] != null)
      Text('Numbers: ${(r['numbers'] as List).join(' · ')}'),
    if (r['powerball'] != null) Text('Powerball: ${r['powerball']}'),
    if (r['megaBall'] != null) Text('Mega Ball: ${r['megaBall']}'),
    if (r['powerPlay'] != null) Text('Power Play: ${r['powerPlay']}'),
    if (r['advertisedJackpot'] != null)
      Text('Advertised jackpot: ${r['advertisedJackpot']}'),
    if (r['tiers'] != null)
      for (final t in r['tiers'])
        entry('Match ${t['match']}', [
          'Source match label: ${t['sourceMatchLabel']}',
          if (r['game'] == 'Powerball') ...[
            'Base — Winners: ${t['baseWinners']} · Prize: ${t['basePrizeLabel']}',
            'Power Play — Winners: ${t['powerPlayWinnersLabel']} · Prize: ${t['powerPlayPrizeLabel']}',
          ] else if (r['game'] == 'Mega Millions') ...[
            for (final m in t['multipliers'])
              '${m['multiplier']}× — Winners: ${m['winners']} · Prize: ${m['prizeLabel']}',
          ] else
            'Winners: ${t['winners']} · Prize: ${t['prizeLabel']}',
        ]),
    if (r['playTypes'] != null) ...[
      Text(
        (r['summaryColumns'] as List).join(' / '),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      for (final p in r['playTypes'])
        entry(p['playType'], [
          if (p.containsKey('statewideWinners'))
            'Statewide Winners: ${p['statewideWinners']}',
          'Statewide Total: ${p['statewideTotalLabel']}',
        ]),
    ],
  ];

  // Expand the source's two-row Straight/Box cells into labelled readable rows.
  // The continuation keeps its inherited play type and wager, never a new count.
  List<Widget> schedules(Map r) {
    final result = <Widget>[
      const Divider(),
      const Text(
        'Published payout schedules',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      const Text(
        'Literal examples, odds and wager costs; these are not observed draw winners or dollar totals.',
      ),
    ];
    for (final s in r['payoutSchedule']) {
      final columns = <String>[];
      for (var i = 0; i < s['columns'].length; i++) {
        final span = s['columnSpans'][i] as int;
        for (var j = 0; j < span; j++) {
          columns.add(
            '${s['columns'][i]}${span == 1 ? '' : ' (source column ${j + 1})'}',
          );
        }
      }
      List previous = [];
      for (final row in s['rows']) {
        final cells = row['cells'] as List;
        final expanded = cells.length == 2
            ? [...previous.take(2), ...cells]
            : cells;
        result.add(
          entry(expanded[0], [
            for (var i = 1; i < expanded.length; i++)
              '${columns[i]}: ${expanded[i]}',
          ]),
        );
        previous = expanded;
      }
    }
    return result;
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
                reports = d['reports'] as List,
                r = reports[_selected] as Map;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Louisiana draw reports',
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
                          '${reports[i]['game']} · ${reports[i]['drawDate']} ${reports[i]['session'] ?? ''}',
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
                    children: [
                      Text('Draw date: ${r['drawDate']} ${r['session'] ?? ''}'),
                      Text(r['coverage']),
                      Text(r['sourceUpdatedText']),
                      for (final warning in r['sourceWarnings'] ?? [])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Source warning: $warning',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ...reportRows(r),
                      if (r['payoutSchedule'] != null) ...schedules(r),
                      for (final q in r['qualifications'])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Text(q),
                        ),
                      const Divider(),
                      Text('Retrieved: ${d['updatedAt']}'),
                      Text(d['coverage']),
                      TextButton.icon(
                        onPressed: () => _open(r['sourceUrl']),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open this official report'),
                      ),
                      const Text(
                        'Fast Play, promotions, Club Lotteaux, bundles and older history are outside these bounded reports. No retailer positions, cash-option conversions or complete statewide claims are inferred.',
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
