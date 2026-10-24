import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/idaho_coverage_loader.dart';

class IdahoDrawCollectionSheet extends StatefulWidget {
  const IdahoDrawCollectionSheet({
    super.key,
    this.coverageOverride,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? coverageOverride;
  final int initialIndex;
  static const labels = {
    'powerball': 'Powerball',
    'powerball-double-play': 'Powerball Double Play',
    'mega-millions': 'Mega Millions',
    'lotto-america': 'Lotto America',
    'millionaire-for-life': 'Millionaire for Life',
    'idaho-cash': 'Idaho Cash',
    'powerball-xs-os': 'Powerball Xs & Os',
    'pick-3-day': 'Pick 3 Day',
    'pick-3-night': 'Pick 3 Night',
    'pick-4-day': 'Pick 4 Day',
    'pick-4-night': 'Pick 4 Night',
  };

  @override
  State<IdahoDrawCollectionSheet> createState() =>
      _IdahoDrawCollectionSheetState();
}

class _IdahoDrawCollectionSheetState extends State<IdahoDrawCollectionSheet> {
  late final data = widget.coverageOverride != null
      ? Future.value(widget.coverageOverride!)
      : IdahoCoverageLoader().load();
  late int selected = widget.initialIndex;
  final scroll = ScrollController(keepScrollOffset: false);
  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void page(int direction) {
    if (!scroll.hasClients) return;
    final position = scroll.position;
    // Overlap pages so a tier split at the viewport edge remains readable.
    final target =
        (position.pixels + direction * position.viewportDimension * .8).clamp(
          position.minScrollExtent,
          position.maxScrollExtent,
        );
    scroll.animateTo(
      target,
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  Future<void> open(String url) async {
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
        if (title.isNotEmpty)
          Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        for (final line in lines) Semantics(container: true, child: Text(line)),
      ],
    ),
  );
  List<Widget> details(Map coverage, Map row) {
    final group = row['group'] as String;
    final family = group.startsWith('pick-3')
        ? 'pick-3'
        : group.startsWith('pick-4')
        ? 'pick-4'
        : group == 'powerball-double-play'
        ? 'powerball'
        : group;
    final chart = coverage['schedules'][family];
    final rules = coverage['rules'][family];
    final report = row['report'];
    final sum = coverage['sumSchedules'][family];
    return [
      entry('${IdahoDrawCollectionSheet.labels[group]} · ${row['drawDate']}', [
        '${group == 'powerball-xs-os' ? 'Official team image codes' : 'Numbers'}: ${(row['numbers'] as List).join(' · ')}',
        if (row['specialNumber'] != null)
          'Special ball: ${row['specialNumber']}',
        if (row['multiplier'] != null)
          '${group == 'powerball' ? 'Power Play' : 'All Star Bonus'}: ${row['multiplier']}X',
        if (group == 'mega-millions')
          'Multiplier is assigned per play; no shared draw multiplier.',
        if (group == 'powerball-xs-os') row['numberMeaning'],
        'Collected: ${coverage['collectionStartedAt']}',
        'Two bounded results per group; not complete history.',
      ]),
      if (report == null)
        entry('Dated Idaho report unavailable', [
          row['reportGap'],
          'Unavailable does not mean zero winners.',
        ])
      else ...[
        entry('Dated Idaho report', [
          report['sourceLabel'],
          if (row['reportProvenance'] != null)
            'Retained exact-date report. Originally collected: ${row['reportProvenance']['collectionStartedAt']}. Not reverified by the current collection.',
          report['countDefinition'],
          if (report['limitation'] != null) report['limitation'],
        ]),
        for (final tier in report['tiers'])
          entry(tier['sourceTier'] ?? tier['sourceMatch'], [
            if (tier['prizeLabel'] != null) tier['prizeLabel'],
            'Published winner count: ${tier['publishedWinnerCount']}',
          ]),
      ],
      if (family == 'powerball')
        entry('Shared Powerball and Double Play schedule', [
          'The official table has separate PowerPlay and Double Play prize columns. These are different drawings; no base winner count is inferred.',
          if (group == 'powerball-double-play')
            'Power Play multipliers and regular jackpot terms do not apply to Double Play.',
        ]),
      entry('Literal official schedule', [
        'Published schedule; not a dated ticket payout.',
        'Match notation: X is a main-number or team-code match; Y is the special ball where shown. Literal source match labels are retained.',
      ]),
      for (final tier in chart['rows'])
        entry('Match: ${tier['match']}', [
          for (var i = 1; i < (tier['cells'] as List).length; i++)
            '${chart['headers'][i]}: ${tier['cells'][i]}',
        ]),
      entry('Source schedule text and footnotes', [chart['containerText']]),
      entry('Source qualifications and discrepancies', [
        for (final limitation in rules['limitations']) limitation,
      ]),
      entry('Official rules', [rules['sourceText']]),
      if (sum != null) ...[
        entry('Sum It Up — reviewed image schedule', [
          sum['wagerBasisPrintedOnImage'] ??
              'Wager basis is not printed on the reviewed image; no basis inferred.',
          'Published schedule; not a dated payout report.',
        ]),
        for (final tier in sum['rows'])
          entry('Sum ${tier['sumLabel']}', [
            'Prize: \$${tier['prizeDollars']}',
          ]),
        TextButton(
          onPressed: () => open(sum['sourceUrl']),
          child: const Text('Official Sum It Up chart'),
        ),
      ],
      TextButton(
        onPressed: () =>
            open('https://www.idaholottery.com/games/draw/$family'),
        child: const Text('Official rules and schedules'),
      ),
      entry('Coverage limits', [
        coverage['coverage'],
        'Pick count units remain excluded. Retired-game history is unavailable. External sources may require selecting a game and date.',
      ]),
      TextButton(
        onPressed: () => open(row['sourceUrl']),
        child: const Text('Official dated result source'),
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
                        'Idaho coverage unavailable. Please try again later.',
                      )
                    : const CircularProgressIndicator(),
              );
            }
            final d = snapshot.data!,
                rows = d['results'] as List,
                row = rows[selected];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Idaho results and schedules',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      tooltip: 'Previous page',
                      onPressed: () => page(-1),
                      icon: const Icon(Icons.keyboard_arrow_up),
                    ),
                    IconButton(
                      tooltip: 'Next page',
                      onPressed: () => page(1),
                      icon: const Icon(Icons.keyboard_arrow_down),
                    ),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Official game source',
                      onPressed: () => open(row['sourceUrl']),
                      icon: const Icon(Icons.open_in_new),
                    ),
                    IconButton(
                      tooltip: 'Close Idaho results',
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
                          '${IdahoDrawCollectionSheet.labels[rows[i]['group']]} · ${rows[i]['drawDate']}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selected = value);
                      // Reset after the new schedule and dropdown focus settle.
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted && scroll.hasClients) scroll.jumpTo(0);
                      });
                    }
                  },
                ),
                Expanded(
                  child: ListView(
                    key: ValueKey(selected),
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
