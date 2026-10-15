import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/kansas_collection_loader.dart';

class KansasDrawCollectionSheet extends StatefulWidget {
  const KansasDrawCollectionSheet({
    super.key,
    this.reportsOverride,
    this.loader,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? reportsOverride;
  final KansasCollectionLoader? loader;
  final int initialIndex;
  @override
  State<KansasDrawCollectionSheet> createState() =>
      _KansasDrawCollectionSheetState();
}

class _KansasDrawCollectionSheetState extends State<KansasDrawCollectionSheet> {
  late final _data = widget.reportsOverride != null
      ? Future.value(widget.reportsOverride!)
      : (widget.loader ?? KansasCollectionLoader()).load();
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

  List<Widget> details(Map d, Map r) {
    final schedule = d['schedules'][r['scheduleKey']] as Map;
    final prizes = (d['advertisedPrizes'] as List).where(
      (p) => p['scheduleKey'] == r['scheduleKey'],
    );
    final frequent = r['session'] == 'Frequent';
    return [
      Text(r['coverage']),
      if (frequent)
        const Text(
          'Two recent snapshots only. This is not a live results service.',
        ),
      Text('Local draw date: ${r['drawDate']} · America/Chicago'),
      Text('Source timestamp: ${r['sourceDrawTimestamp']}'),
      Text('Source UTC date: ${r['sourceDrawingDate']}'),
      for (final warning in r['sourceWarnings'])
        entry('Source warning', [warning]),
      entry('Drawn numbers', [
        if (r['teams'].isNotEmpty)
          'Teams: ${(r['teams'] as List).join(' · ')}'
        else
          'Numbers: ${(r['numbers'] as List).join(' · ')}',
        if (r['specialNumbers'].isNotEmpty)
          '${r['group'] == 'keno'
              ? "Bull’s-eye"
              : r['group'] == '2by2'
              ? 'White numbers'
              : 'Special number'}: ${(r['specialNumbers'] as List).join(' · ')}',
        if (r['group'] == '2by2') 'The first number group is red.',
        if (r['group'] == 'keno')
          'Source order: ${(r['sourceNumberOrder'] as List).map((x) => "${x['value']}${x['type'] == 'SPECIAL' ? '*' : ''}").join(' · ')} (* Bull’s-eye)',
        if (r['group'] == 'racetrax')
          'Horses shown in first, second, third, fourth order.',
        if (r['multiplier'] != null) 'Source multiplier: ${r['multiplier']}×',
      ]),
      for (final p in prizes)
        entry('Separately advertised prize', [
          'For local drawing ${p['drawDate']} · America/Chicago',
          'Source timestamp: ${p['sourceDrawTimestamp']}',
          'Source UTC date: ${p['sourceDrawingDate']}',
          if (p['advertisedAnnuityDollars'] != null)
            'Advertised annuity: \$${p['advertisedAnnuityDollars']}',
          'Advertised cash: \$${p['advertisedCashDollars']}',
          if (!DateTime.parse(p['sourceDrawTimestamp']).isAfter(DateTime.now()))
            'This advertised draw time has passed.',
          p['coverage'],
          ...List<String>.from(p['sourceWarnings']),
        ]),
      entry('Literal prize schedules — not actual winners', [
        schedule['coverage'],
        ...List<String>.from(schedule['sourceWarnings']),
      ]),
      for (final line in schedule['primaryDescription']) Text(line),
      for (final table in schedule['tables']) ...[
        entry(table['title'].isEmpty ? 'Published schedule' : table['title'], [
          table['description'],
        ]),
        for (final row in table['rows'])
          entry('${table['columns'][0]}: ${row[0]}', [
            for (var i = 1; i < row.length; i++)
              '${table['columns'][i]}: ${row[i].isEmpty ? '(blank in source)' : row[i]}',
          ]),
        Text(table['footer']),
        for (final card in table['prizeInformationCards'] ?? []) ...[
          entry(card['title'], [
            card['description'],
            'Minimum return: ${card['minReturn']}',
            'Maximum return: ${card['maxReturn']}',
          ]),
          TextButton(
            onPressed: () => _open(card['pdfHref']),
            child: Text(card['pdfLink']),
          ),
        ],
        if (table['prizeInformationFooter'] != null)
          Text(table['prizeInformationFooter']),
      ],
      entry(
        'Source qualifications',
        List<String>.from(schedule['qualifications']),
      ),
      entry('How to play — source rules', List<String>.from(schedule['rules'])),
      entry('Source disclaimer', List<String>.from(schedule['disclaimer'])),
      const Divider(),
      Text('Retrieved: ${d['retrievedAt']}'),
      for (final value in (d['coverage'] as Map).values)
        Text(value is List ? value.join(' • ') : value),
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
                reports = d['reports'] as List,
                r = reports[_selected] as Map;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Kansas results and schedules',
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
                          '${reports[i]['family']} · ${reports[i]['session']} · ${reports[i]['drawDate']} ${reports[i]['session'] == 'Frequent' ? reports[i]['drawNumber'] : ''}',
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
