import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

/// Literal source schedules/reports; preserves source units and table boundaries.
class DelawareReferenceSheet extends StatelessWidget {
  const DelawareReferenceSheet({
    super.key,
    required this.coverage,
    this.reports = false,
    this.openSource,
  });
  final Map<String, dynamic> coverage;
  final bool reports;
  final Future<bool> Function(Uri)? openSource;

  @override
  Widget build(BuildContext context) {
    final rows =
        (reports
                ? coverage['publishedReports']['reports']
                : coverage['rules']['rules'])
            as List;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          reports ? 'Published count reports' : 'Prize schedules and rules',
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              reports
                  ? 'Published categories retain their source units. They are not complete state totals, unique people or geographic win activity.'
                  : 'Published prize schedules describe game rules, not actual payouts or current jackpots.',
            ),
            if (reports)
              for (final note
                  in coverage['publishedReports']['limitations'] as List)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Text(note),
                ),
            for (final row in rows)
              ListTile(
                title: Text(
                  (row[reports ? 'report' : 'rule']['game'] ??
                          row['family'].toString().replaceAll('-', ' '))
                      .toString(),
                ),
                subtitle: Text(
                  row[reports ? 'report' : 'rule']['status'] ??
                      (reports
                          ? 'Dated source report'
                          : 'Retained source schedule'),
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => DelawareReferenceDetail(
                      entry: row as Map,
                      reports: reports,
                      openSource: openSource,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class DelawareReferenceDetail extends StatelessWidget {
  const DelawareReferenceDetail({
    super.key,
    required this.entry,
    required this.reports,
    this.openSource,
  });
  final Map entry;
  final bool reports;
  final Future<bool> Function(Uri)? openSource;
  static const hidden = {
    'sourceUrl',
    'chartUrl',
    'oddsSourceUrl',
    'chartSha256',
    'auditedBodyTextSha256',
    'reviewMethod',
  };
  static const labels = {
    'publishedCount': 'Published category count',
    'source50CentBetWins': 'Source 50-cent bet prize',
    'sourceAveragePrize': 'Source AVERAGE PRIZE column',
    'sourceTotals': 'Source totals (not recomputed)',
    'sourceMultiplierTotals': 'Source multiplier totals',
    'sourceUnit': 'Source unit',
    'sourceGeography': 'Source geography',
    'prize50CentBet': 'Prize for 50-cent bet',
    'prize1DollarBet': 'Prize for one-dollar bet',
    'multiplierSummary': 'Source multiplier summary cells (original order)',
  };
  String label(String key) =>
      labels[key] ??
      key
          .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (m) => '${m[1]} ${m[2]}')
          .replaceFirstMapped(RegExp(r'^.'), (m) => m[0]!.toUpperCase());
  Widget text(String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 5),
    child: Text(value),
  );
  List<Widget> fields(Map value) => [
    for (final item in value.entries)
      if (!hidden.contains(item.key))
        ...render(item.key.toString(), item.value),
  ];
  List<Widget> render(String key, dynamic value) {
    if (value is Map)
      return [
        text(label(key)),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: fields(value),
            ),
          ),
        ),
      ];
    if (value is List)
      return [
        text(label(key)),
        for (final item in value)
          if (item is Map)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: fields(item),
                ),
              ),
            )
          else
            text(
              item == null
                  ? 'Unavailable'
                  : item.toString().isEmpty
                  ? '(blank source cell)'
                  : item.toString(),
            ),
      ];
    return [text('${label(key)}: ${value ?? 'Unavailable'}')];
  }

  Future<void> open(BuildContext context, String url) async {
    final uri = Uri.tryParse(url);
    var ok = false;
    if (uri != null &&
        uri.scheme == 'https' &&
        uri.userInfo.isEmpty &&
        (uri.host == 'www.delottery.com' ||
            uri.host == 'delotterywebcontent.blob.core.windows.net')) {
      try {
        ok =
            await (openSource?.call(uri) ??
                launchUrl(uri, mode: LaunchMode.externalApplication));
      } catch (_) {}
    }
    if (!ok && context.mounted)
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the official source.')),
      );
  }

  @override
  Widget build(BuildContext context) {
    final data = entry[reports ? 'report' : 'rule'] as Map;
    final evidence = entry['evidence'] is List
        ? entry['evidence'] as List
        : [entry['evidence']];
    final body = Map.of(data)..remove('coverage');
    return Scaffold(
      appBar: AppBar(
        title: Text(
          data['game'] ?? entry['family'].toString().replaceAll('-', ' '),
        ),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            text(data['coverage']),
            if (reports)
              text(
                'Report dates and sessions are independent of the selected drawing. No inferred payout or cross-category total.',
              ),
            for (final source in evidence) ...[
              text('Source observed: ${source['retrievedAt']}'),
              TextButton(
                onPressed: () => open(context, source['url']),
                child: const Text('Official source'),
              ),
            ],
            if (data['chartUrl'] != null)
              TextButton(
                onPressed: () => open(context, data['chartUrl']),
                child: const Text('Official prize chart'),
              ),
            if (data['oddsSourceUrl'] != null)
              TextButton(
                onPressed: () => open(context, data['oddsSourceUrl']),
                child: const Text('Official odds source'),
              ),
            ...fields(body),
          ],
        ),
      ),
    );
  }
}
