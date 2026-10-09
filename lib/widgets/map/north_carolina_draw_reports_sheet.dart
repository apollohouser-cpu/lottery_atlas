import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/north_carolina_draw_reports_loader.dart';

class NorthCarolinaDrawReportsSheet extends StatefulWidget {
  const NorthCarolinaDrawReportsSheet({
    super.key,
    this.reportsOverride,
    this.loader,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? reportsOverride;
  final NorthCarolinaDrawReportsLoader? loader;
  final int initialIndex;
  @override
  State<NorthCarolinaDrawReportsSheet> createState() =>
      _NorthCarolinaDrawReportsSheetState();
}

class _NorthCarolinaDrawReportsSheetState
    extends State<NorthCarolinaDrawReportsSheet> {
  late final _data = widget.reportsOverride != null
      ? Future.value(widget.reportsOverride!)
      : (widget.loader ?? NorthCarolinaDrawReportsLoader()).load();
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

  List<Widget> table(Map v) => [
    if (v['name'] != null)
      Text(v['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
    if (v['winningNumbers'] != null)
      Text('Numbers: ${(v['winningNumbers'] as List).join(' · ')}'),
    if (v['powerball'] != null) Text('Powerball: ${v['powerball']}'),
    if (v['megaBall'] != null) Text('Mega Ball: ${v['megaBall']}'),
    if (v['millionaireBall'] != null)
      Text('Millionaire Ball: ${v['millionaireBall']}'),
    if (v['multiplierLabel'] != null) Text(v['multiplierLabel']),
    if (v['multiplierHeading'] != null)
      Text('Source heading: ${v['multiplierHeading']}'),
    if (v['teamLabels'] != null)
      Text('Teams: ${(v['teamLabels'] as List).join(' · ')}'),
    const Text(
      'Match / literal prize / source Wins',
      style: TextStyle(fontWeight: FontWeight.bold),
    ),
    for (final t in v['tiers'] as List)
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    '${t['matchLabel']}${t['multiplierLabel'] == null ? '' : ' · ${t['multiplierLabel']}'}',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(flex: 3, child: Text(t['prizeLabel'])),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${t['reportedWins']}',
                    textAlign: TextAlign.right,
                  ),
                ),
              ],
            ),
            if (t['sourceMatchLabel'] != null &&
                t['sourceMatchLabel'] != t['matchLabel'])
              Text('Source accessibility label: ${t['sourceMatchLabel']}'),
          ],
        ),
      ),
    for (final note in v['notes'] ?? []) Text(note),
    const SizedBox(height: 16),
  ];
  List<Widget> schedule(Map s) => [
    const Divider(),
    Text(s['title'], style: const TextStyle(fontWeight: FontWeight.bold)),
    Text(s['coverage']),
    Text(s['payoutHeading']),
    for (final row in s['rows'])
      Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('${row['playType']} ${row['matchLabel']}'),
            for (var i = 0; i < 2; i++)
              Text('${s['wagerLabels'][i]}: ${row['payoutLabels'][i]}'),
          ],
        ),
      ),
    for (final note in s['notes']) Text(note),
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
                        'North Carolina draw reports',
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
                    }
                  },
                ),
                Expanded(
                  child: ListView(
                    controller: _scroll,
                    children: [
                      Text('Draw date: ${r['drawDate']} ${r['session'] ?? ''}'),
                      Text(r['coverage']),
                      const Text(
                        'Publication date and finality are unverified. Source Wins and winners are not verified distinct people or complete claims.',
                      ),
                      for (final warning in r['sourceWarnings'] ?? [])
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          child: Text(
                            'Source warning: $warning',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      if (r['winningDigits'] != null)
                        Text(
                          'Digits: ${(r['winningDigits'] as List).join(' · ')} • Fireball: ${r['fireball']}',
                        ),
                      if (r['pop'] != null)
                        Text('Pop: ${r['pop']} • ${r['sessionTimeLabel']}'),
                      if (r['reportedWinners'] != null)
                        Text(
                          'Source winners: ${r['reportedWinners']} • Published payout: ${r['reportedPayoutLabel']}',
                        ),
                      if (r['sourceSummaryLabel'] != null)
                        Text(r['sourceSummaryLabel']),
                      if (r['variants'] != null)
                        for (final v in r['variants']) ...table(v),
                      if (r['tiers'] != null) ...table(r),
                      if (r['payoutSchedules'] != null)
                        for (final s in r['payoutSchedules']) ...schedule(s),
                      const Divider(),
                      Text('Retrieved: ${d['updatedAt']}'),
                      Text(d['coverage']),
                      TextButton.icon(
                        onPressed: () => _open(r['sourceUrl']),
                        icon: const Icon(Icons.open_in_new),
                        label: const Text('Open this official report'),
                      ),
                      const Text(
                        'Keno, Fast Play, Digital Instants, promotions and older history are outside these bounded reports. No retailer positions, cash-option conversions or complete statewide claims are inferred.',
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
