import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

/// Statewide source columns are deliberately separate from map activity totals.
class TexasPrizeTablesSheet extends StatefulWidget {
  const TexasPrizeTablesSheet({super.key, this.reportsOverride});
  final Map<String, dynamic>? reportsOverride;
  @override
  State<TexasPrizeTablesSheet> createState() => _TexasPrizeTablesSheetState();
}

class _TexasPrizeTablesSheetState extends State<TexasPrizeTablesSheet> {
  static const _cacheKey = 'texas_prize_tables_v1';
  late final Future<Map<String, dynamic>> _reports = _load();
  int _selected = 0;
  final _horizontal = ScrollController();
  final _vertical = ScrollController();

  @override
  void dispose() {
    _horizontal.dispose();
    _vertical.dispose();
    super.dispose();
  }

  Map<String, dynamic> _decode(String raw) {
    final data = Map<String, dynamic>.from(jsonDecode(raw) as Map);
    final reports = data['reports'] as List;
    if (reports.isEmpty) throw const FormatException('No prize reports');
    for (final report in reports) {
      final headers = report['headers'] as List;
      final rows = [...report['tiers'] as List, report['reportedTotals']];
      if (headers.isEmpty ||
          rows.any((row) => (row as List).length != headers.length)) {
        throw const FormatException('Invalid prize columns');
      }
      final uri = Uri.parse(report['sourceUrl'] as String);
      if (uri.scheme != 'https' || uri.host != 'www.texaslottery.com') {
        throw const FormatException('Nonofficial source');
      }
    }
    return data;
  }

  Future<Map<String, dynamic>> _load() async {
    if (widget.reportsOverride != null) return widget.reportsOverride!;
    final prefs = SharedPreferencesAsync();
    Map<String, dynamic>? cached;
    try {
      final raw = await prefs.getString(_cacheKey);
      if (raw != null) cached = _decode(raw);
    } catch (_) {}
    try {
      final response = await http
          .get(
            Uri.parse(
              'https://apollohouser-cpu.github.io/lottery_atlas/texas_draw_tiers.json',
            ),
          )
          .timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = _decode(response.body);
        await prefs.setString(_cacheKey, response.body);
        return data;
      }
    } catch (_) {}
    return cached ??
        _decode(
          await rootBundle.loadString('data/texas_draw_tiers.generated.json'),
        );
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
                        'Texas statewide prize tables',
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
                const Text(
                  'Keep columns separate: multiplier counts can overlap total winners. Prize amounts are source-listed amounts, not verified cash payouts. Scroll horizontally for all columns.',
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
                TextButton.icon(
                  onPressed: () => launchUrl(
                    Uri.parse(report['sourceUrl'] as String),
                    mode: LaunchMode.externalApplication,
                  ),
                  icon: const Icon(Icons.open_in_new),
                  label: const Text('Open official draw report'),
                ),
              ],
            );
          },
        ),
      ),
    ),
  );
}
