import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/new_york_prize_tables_loader.dart';

class NewYorkPrizeTablesSheet extends StatefulWidget {
  const NewYorkPrizeTablesSheet({
    super.key,
    this.reportsOverride,
    this.loader,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? reportsOverride;
  final NewYorkPrizeTablesLoader? loader;
  final int initialIndex;
  @override
  State<NewYorkPrizeTablesSheet> createState() =>
      _NewYorkPrizeTablesSheetState();
}

class _NewYorkPrizeTablesSheetState extends State<NewYorkPrizeTablesSheet> {
  late final Future<Map<String, dynamic>> _data = widget.reportsOverride != null
      ? Future.value(widget.reportsOverride!)
      : (widget.loader ?? NewYorkPrizeTablesLoader()).load();
  late int _selected = widget.initialIndex;
  final _scroll = ScrollController();
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
            final shares =
                r['gameName'] == 'NUMBERS' || r['gameName'] == 'Win4';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'New York draw reports',
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
                          '${reports[i]['gameName']} · ${reports[i]['drawDate']} ${reports[i]['drawingSession'] ?? ''}',
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
                      Text(
                        '${r['jurisdiction']}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        'Draw date: ${r['drawDate']} ${r['drawingSession'] ?? ''}',
                      ),
                      Text('Draw number: ${r['drawNumber']}'),
                      const Text('Source publication date unavailable'),
                      Text('${r['countUnit']}'),
                      if (shares || r['gameName'] == 'Quick Draw / Money Dots')
                        const Text('Winner count: unavailable'),
                      if (r['reportedTotalPrizes'] != null)
                        Text(
                          'Reported prize dollars: \$${r['reportedTotalPrizes']}',
                        ),
                      if (r['multiplier'] != null)
                        Text('Source multiplier: ${r['multiplier']}'),
                      for (final table in r['tables']) ...[
                        const SizedBox(height: 12),
                        Text(
                          '${table['variant']}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        if (table['reportedTotalPrizes'] != null)
                          Text(
                            'Reported prize dollars: \$${table['reportedTotalPrizes']}',
                          ),
                        if (table['drawnNumber'] != null)
                          Text(
                            'Drawn number: ${table['drawnNumber']} · Drawn prize: ${table['drawnPrizeLabel']}',
                          ),
                        if ((table['tiers'] as List).isNotEmpty)
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: DataTable(
                              columns: [
                                const DataColumn(label: Text('Tier')),
                                DataColumn(
                                  label: Text(
                                    shares
                                        ? 'Winning shares'
                                        : 'NY reported winners',
                                  ),
                                ),
                                const DataColumn(
                                  label: Text('Source prize label'),
                                ),
                              ],
                              rows: [
                                for (final tier in table['tiers'])
                                  DataRow(
                                    cells: [
                                      DataCell(Text('${tier['tier']}')),
                                      DataCell(
                                        Text(
                                          '${tier[shares ? 'reportedShares' : 'reportedWinners'] ?? 'Unavailable'}',
                                        ),
                                      ),
                                      DataCell(
                                        Text(
                                          '${tier['prizeLabel'] ?? 'Unavailable'}',
                                        ),
                                      ),
                                    ],
                                  ),
                              ],
                            ),
                          ),
                      ],
                      const SizedBox(height: 12),
                      Text('${r['limitation']}'),
                      Text('Retrieved: ${data['retrievedAt']}'),
                      Text('${data['cadence']}'),
                      const Text(
                        'Draw reports are separate from selected retailer winner releases and Scratch inventory.',
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
                      for (final source
                          in (data['additionalSources'] as List? ?? []))
                        ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text('${source['gameName']}'),
                          subtitle: Text('${source['limitations']}'),
                          trailing: const Icon(Icons.open_in_new),
                          onTap: () => _open(source['sourceUrl'] as String),
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
