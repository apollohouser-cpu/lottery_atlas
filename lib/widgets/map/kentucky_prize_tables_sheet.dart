import 'package:flutter/material.dart';
import '../../services/kentucky_prize_tables_loader.dart';
import 'package:url_launcher/url_launcher.dart';

/// Statewide source columns are deliberately separate from map activity totals.
class KentuckyPrizeTablesSheet extends StatefulWidget {
  const KentuckyPrizeTablesSheet({
    super.key,
    this.reportsOverride,
    this.loader,
  });
  final KentuckyPrizeTablesLoader? loader;
  final Map<String, dynamic>? reportsOverride;
  @override
  State<KentuckyPrizeTablesSheet> createState() =>
      _KentuckyPrizeTablesSheetState();
}

class _KentuckyPrizeTablesSheetState extends State<KentuckyPrizeTablesSheet> {
  late final Future<Map<String, dynamic>> _reports =
      widget.reportsOverride != null
      ? Future.value(widget.reportsOverride!)
      : (widget.loader ?? KentuckyPrizeTablesLoader()).load();
  int _selected = 0;
  final _horizontal = ScrollController();
  final _vertical = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .88,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _reports,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: snapshot.hasError
                    ? const Text(
                        'Prize tables unavailable. Please try again later.',
                      )
                    : const CircularProgressIndicator(),
              );
            }
            final data = snapshot.data!;
            final reports = data['reports'] as List;
            final report = reports[_selected] as Map;
            final headers = report['headers'] as List;
            final rows = [...report['tiers'] as List, report['reportedTotals']];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Kentucky statewide prize tables',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                      tooltip: 'Close prize tables',
                    ),
                  ],
                ),
                const Text(
                  'Reported winners by tier • Not retailer map counts',
                ),
                const SizedBox(height: 12),
                DropdownButton<int>(
                  isExpanded: true,
                  value: _selected,
                  items: [
                    for (var i = 0; i < reports.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(
                          '${reports[i]['gameName']}${reports[i]['drawingSession'] == null ? '' : ' · ${reports[i]['drawingSession']}'}',
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      if (_horizontal.hasClients) _horizontal.jumpTo(0);
                      if (_vertical.hasClients) _vertical.jumpTo(0);
                      setState(() => _selected = value);
                    }
                  },
                ),
                Text(
                  'Draw date: ${report['drawDate']} • Source publication date unavailable',
                ),
                const SizedBox(height: 8),
                Text(
                  report['tableNote'] as String? ??
                      'Base prize and multiplier are separate. Tier payout is their product times reported Kentucky winners, not verified cash claims. Scroll horizontally for all columns.',
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) => Scrollbar(
                      controller: _vertical,
                      thumbVisibility: true,
                      notificationPredicate: (notification) =>
                          notification.metrics.axis == Axis.vertical,
                      child: Scrollbar(
                        controller: _horizontal,
                        thumbVisibility: true,
                        child: SingleChildScrollView(
                          controller: _horizontal,
                          scrollDirection: Axis.horizontal,
                          child: SizedBox(
                            width: headers.length * 166.0 + 48,
                            height: constraints.maxHeight,
                            child: SingleChildScrollView(
                              controller: _vertical,
                              key: ValueKey(_selected),
                              child: DataTable(
                                headingRowHeight: 80,
                                dataRowMinHeight: 48,
                                dataRowMaxHeight: 72,
                                columns: [
                                  for (final header in headers)
                                    DataColumn(
                                      label: SizedBox(
                                        width: 110,
                                        child: Text(
                                          '$header',
                                          softWrap: true,
                                          maxLines: 4,
                                        ),
                                      ),
                                    ),
                                ],
                                rows: [
                                  for (final row in rows)
                                    DataRow(
                                      cells: [
                                        for (final cell in row as List)
                                          DataCell(
                                            SizedBox(
                                              width: 110,
                                              child: Text('$cell'),
                                            ),
                                          ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                Text(
                  '${data['coverage']}',
                  style: const TextStyle(fontSize: 11),
                ),
                Wrap(
                  spacing: 8,
                  children: [
                    TextButton.icon(
                      onPressed: () => launchUrl(
                        Uri.parse(report['sourceUrl'] as String),
                        mode: LaunchMode.externalApplication,
                      ),
                      icon: const Icon(Icons.open_in_new),
                      label: const Text('Open official draw report'),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
