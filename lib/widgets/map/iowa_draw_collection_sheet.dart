import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/iowa_coverage_loader.dart';

class IowaDrawCollectionSheet extends StatefulWidget {
  const IowaDrawCollectionSheet({
    super.key,
    this.coverageOverride,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? coverageOverride;
  final int initialIndex;
  static const labels = {
    'powerball': 'Powerball',
    'double_play': 'Powerball Double Play',
    'mega_millions': 'Mega Millions',
    'lotto_america': 'Lotto America',
    'millionaire_for_life': 'Millionaire for Life',
    'xsos': 'Powerball Xs & Os',
    'pick3_midday': 'Pick3 Midday',
    'pick3_evening': 'Pick3 Evening',
    'pick4_midday': 'Pick4 Midday',
    'pick4_evening': 'Pick4 Evening',
  };
  @override
  State<IowaDrawCollectionSheet> createState() =>
      _IowaDrawCollectionSheetState();
}

class _IowaDrawCollectionSheetState extends State<IowaDrawCollectionSheet> {
  late final data = widget.coverageOverride != null
      ? Future.value(widget.coverageOverride!)
      : IowaCoverageLoader().load();
  late int selected = widget.initialIndex;
  final scroll = ScrollController();
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  Future<void> open(String url) async {
    try {
      if (await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication)) {
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
        if (title.isNotEmpty)
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        for (final line in lines) Semantics(container: true, child: Text(line)),
      ],
    ),
  );
  List<Widget> details(Map coverage, Map row) {
    final group = row['group'] as String;
    final family = group.startsWith('pick3')
        ? 'pick3'
        : group.startsWith('pick4')
        ? 'pick4'
        : group;
    final chartName = family == 'pick3'
        ? 'Pick3'
        : family == 'pick4'
        ? 'Pick4'
        : IowaDrawCollectionSheet.labels[group];
    final draws = coverage['draws'];
    final chart = (draws['charts'] as List).firstWhere(
      (c) => c['game'] == chartName,
    );
    final report = row['report'];
    final ruleKey = group == 'double_play'
        ? 'powerball'
        : family.startsWith('pick')
        ? '${family}_rules'
        : family;
    final rule = (draws['rules'] as List).firstWhere(
      (r) => r['game'] == ruleKey,
    );
    final ruleSets = [
      rule,
      if (family.startsWith('pick'))
        (draws['rules'] as List).firstWhere((r) => r['game'] == family),
    ];
    return [
      entry('${IowaDrawCollectionSheet.labels[group]} · ${row['drawDate']}', [
        if (group == 'xsos')
          'Official source team abbreviations: ${(row['teamCodes'] as List).join(' · ')}'
        else
          'Numbers: ${(row['numbers'] as List).join(' · ')}',
        if (row['specialBall'] != null) 'Special ball: ${row['specialBall']}',
        if (row['multiplier'] != null)
          '${group == 'powerball' ? 'Power Play' : 'All Star Bonus'}: ${row['multiplier']}X',
        if (group == 'mega_millions')
          'Multiplier is assigned per play; no shared draw multiplier.',
        'Retrieved: ${coverage['retrievedAt']}',
        'Two bounded results per group; not complete history.',
      ]),
      if (report == null)
        entry('Dated report unavailable', [row['reportLimitation']])
      else ...[
        entry('Dated Iowa report', [
          report['countLabel'],
          'Source winners are not unique people or paid claims.',
          if (report['sourceJackpotText'] != null)
            report['advertisedJackpotDollars'] == null
                ? 'Advertised jackpot unavailable: source zero placeholder.'
                : 'Source advertised jackpot: ${report['sourceJackpotText']}',
        ]),
        for (final tier in report['tiers'])
          entry(tier['sourceTierLabel'], [
            'Source winners: ${tier['sourceWinners']}',
          ]),
      ],
      entry('Literal ${chart['game']} prize schedule', [
        'Published schedule; not a dated ticket payout.',
      ]),
      for (final tier in chart['rows'])
        entry(tier['match'], [
          for (var i = 0; i < (tier['prizes'] as List).length; i++)
            '${chart['columns'][i]}: ${tier['prizes'][i]}',
          'Odds: ${tier['odds']}',
        ]),
      entry('Schedule qualifications', [
        if (chart['overallOdds'] != null)
          'Overall odds: ${chart['overallOdds']}',
        '${chart['notes']}',
      ]),
      TextButton(
        onPressed: () => open(chart['sourceUrl']),
        child: const Text('Official prize chart'),
      ),
      if (group == 'double_play')
        entry('Shared Powerball source page', [
          'The following source sections separately describe regular Powerball and Double Play. Regular jackpot, Power Play and annuity terms do not describe Double Play prizes.',
        ]),
      for (final rules in ruleSets) ...[
        for (final section in rules['sections'])
          if (section['kind'] == 'table') ...[
            for (final values in (section['rows'] as List).skip(1))
              entry('Source table', [
                for (var i = 0; i < values.length; i++)
                  '${section['rows'][0][i]}: ${values[i]}',
              ]),
          ] else if (section['kind'] == 'ul' || section['kind'] == 'ol')
            entry('', [for (final item in section['items']) '$item'])
          else
            entry(
              section['kind'] == 'p' ? '' : section['text'],
              section['kind'] == 'p' ? [section['text']] : [],
            ),
        TextButton(
          onPressed: () => open(rules['sourceUrl']),
          child: const Text('Official rules and qualifications'),
        ),
      ],
      entry('Coverage limits', [
        'No retailer joins or coordinates. Pick counts remain excluded pending source-unit verification. Lucky for Life is historical only. External sources may require selecting the game and date.',
      ]),
      TextButton(
        onPressed: () => open(row['sourceUrl']),
        child: const Text('Official results and history'),
      ),
    ];
  }

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .92,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>>(
          future: data,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: snapshot.hasError
                    ? const Text(
                        'Iowa coverage unavailable. Please try again later.',
                      )
                    : const CircularProgressIndicator(),
              );
            }
            final d = snapshot.data!,
                rows = d['draws']['results'] as List,
                row = rows[selected];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Iowa results and schedules',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Official game source',
                      onPressed: () => open(row['sourceUrl']),
                      icon: const Icon(Icons.open_in_new),
                    ),
                    IconButton(
                      tooltip: 'Close Iowa results',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                DropdownButton<int>(
                  isExpanded: true,
                  value: selected,
                  items: [
                    for (var i = 0; i < rows.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(
                          '${IowaDrawCollectionSheet.labels[rows[i]['group']]} · ${rows[i]['drawDate']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      if (scroll.hasClients) scroll.jumpTo(0);
                      setState(() => selected = value);
                    }
                  },
                ),
                Expanded(
                  child: ListView(
                    controller: scroll,
                    children: details(d, row),
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
