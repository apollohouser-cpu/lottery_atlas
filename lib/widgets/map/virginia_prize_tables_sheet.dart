import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/virginia_prize_tables_loader.dart';

class VirginiaPrizeTablesSheet extends StatefulWidget {
  const VirginiaPrizeTablesSheet({
    super.key,
    this.reportsOverride,
    this.loader,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? reportsOverride;
  final VirginiaPrizeTablesLoader? loader;
  final int initialIndex;
  @override
  State<VirginiaPrizeTablesSheet> createState() =>
      _VirginiaPrizeTablesSheetState();
}

class _VirginiaPrizeTablesSheetState extends State<VirginiaPrizeTablesSheet> {
  late final Future<Map<String, dynamic>> _data = widget.reportsOverride != null
      ? Future.value(widget.reportsOverride!)
      : (widget.loader ?? VirginiaPrizeTablesLoader()).load();
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
            final shares = r['game'] == 'keno';
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Virginia draw reports',
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
                          '${reports[i]['gameName']} · ${reports[i]['drawDate']} ${reports[i]['session'] ?? reports[i]['drawTime'] ?? ''}',
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
                        'Draw date: ${r['drawDate']}${r['session'] == null ? '' : ' · ${r['session']}'}${r['drawTime'] == null ? '' : ' · ${r['drawTime']} source local time'}',
                      ),
                      const Text('Source publication date unavailable'),
                      if (r['sourceNote'] != null) Text('${r['sourceNote']}'),
                      const SizedBox(height: 12),
                      Text(
                        r['totalWinners'] == null
                            ? 'Winner count: unavailable'
                            : '${r['countUnit']}: ${r['totalWinners']}',
                      ),
                      if (shares)
                        Text('Prize-winning shares: ${r['totalShares']}'),
                      Text(
                        r['totalPayout'] == null
                            ? 'Total payout: unavailable'
                            : 'Reported prize dollars: \$${r['totalPayout']}',
                      ),
                      if (r['multiplier'] != null)
                        Text(
                          'Power Play multiplier: ${r['multiplier']} · separate winner counts unavailable',
                        ),
                      for (final c in (r['components'] as List? ?? []))
                        Text('${c['name']}: \$${c['payout']}'),
                      if ((r['tiers'] as List).isNotEmpty)
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            columns: [
                              if (shares) const DataColumn(label: Text('Spot')),
                              const DataColumn(label: Text('Match')),
                              DataColumn(
                                label: Text(shares ? 'Shares' : 'Source count'),
                              ),
                              const DataColumn(
                                label: Text('Prize description'),
                              ),
                            ],
                            rows: [
                              for (final t in r['tiers'])
                                DataRow(
                                  cells: [
                                    if (shares) DataCell(Text('${t['spot']}')),
                                    DataCell(Text('${t['match']}')),
                                    DataCell(
                                      Text(
                                        '${t[shares ? 'shareCount' : 'winnerCount']}',
                                      ),
                                    ),
                                    DataCell(Text('${t['prizeDescription']}')),
                                  ],
                                ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                      Text('${r['limitations']}'),
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
                          title: Text(
                            '${source['gameName']} · ${source['period']}',
                          ),
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
