import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/nebraska_collection_loader.dart';

class NebraskaDrawCollectionSheet extends StatefulWidget {
  const NebraskaDrawCollectionSheet({
    super.key,
    this.reportsOverride,
    this.loader,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? reportsOverride;
  final NebraskaCollectionLoader? loader;
  final int initialIndex;
  @override
  State<NebraskaDrawCollectionSheet> createState() =>
      _NebraskaDrawCollectionSheetState();
}

class _NebraskaDrawCollectionSheetState
    extends State<NebraskaDrawCollectionSheet> {
  late final _data = widget.reportsOverride != null
      ? Future.value(widget.reportsOverride!)
      : (widget.loader ?? NebraskaCollectionLoader()).load();
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

  List<Widget> tiers(Map report) => [
    if (report['applicable'] == false)
      const Text(
        'Tuesday option is not applicable to this drawing. Source zero placeholders are excluded.',
      ),
    for (final t in report['tiers'])
      entry(t['match'] ?? t['sourceMatchLabel'], [
        if (t['prizeLabel'] != null) 'Source prize: ${t['prizeLabel']}',
        if (t['oddsLabel'] != null) 'Source odds: ${t['oddsLabel']}',
        if (t.containsKey('sourceWinners'))
          'Nebraska Winners (source label): ${t['sourceWinners']}',
        for (final count in t['counts'] ?? [])
          '${count['multiplier']}X source category · Nebraska Winners: ${count['sourceWinners']}',
      ]),
  ];

  List<Widget> details(Map d, Map r) {
    final family =
        (d['familyReports'] as List).firstWhere(
              (f) => f['family'] == r['family'],
            )
            as Map;
    final reports = (family['reports'] ?? [family]) as List;
    final selectedReports = reports
        .where(
          (p) =>
              p['drawDate'] == r['drawDate'] &&
              (r['group'] == 'double-play'
                  ? p['variant'] == 'double-play'
                  : p['variant'] != 'double-play'),
        )
        .toList();
    return [
      entry('${r['family']} · ${r['group']}', [
        'Local draw date: ${r['drawDate']} · America/Chicago',
        'Date-only source; no draw time inferred.',
      ]),
      for (final f in r['fields'])
        entry(f['label'], [(f['values'] as List).join(' · ')]),
      Text(family['limitation']),
      if (selectedReports.isEmpty)
        const Text(
          'No dated prize report retained for this selection. Latest winner counts are not applied to older results.',
        ),
      for (final p in selectedReports) ...[
        entry('Dated Nebraska prize report', [
          'Draw date: ${p['drawDate']}',
          'Variant: ${p['sourceLabel'] ?? p['variant'] ?? "Regular"}',
          'Winners is the source label, not unique people or a complete claims history. Do not sum overlapping categories.',
        ]),
        ...tiers(p),
      ],
      const Divider(),
      entry('Published game rules and schedules', [
        'Undated rules are separate from the selected drawing and actual winner counts.',
      ]),
      ...rules(family['ruleBlocks']),
      const Divider(),
      Text('Retrieved: ${d['retrievedAt']}'),
      Text(d['limitation']),
      TextButton.icon(
        onPressed: () => _open(r['sourceUrl']),
        icon: const Icon(Icons.open_in_new),
        label: const Text('Open official game page'),
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
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Nebraska results and schedules',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
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
                ),
                DropdownButton<int>(
                  isExpanded: true,
                  value: _selected,
                  items: [
                    for (var i = 0; i < reports.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(
                          '${reports[i]['family']} · ${reports[i]['group']} · ${reports[i]['drawDate']}',
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
