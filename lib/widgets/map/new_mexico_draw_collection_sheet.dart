import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/new_mexico_coverage_loader.dart';

class NewMexicoDrawCollectionSheet extends StatefulWidget {
  const NewMexicoDrawCollectionSheet({
    super.key,
    this.coverageOverride,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? coverageOverride;
  final int initialIndex;
  static const labels = {
    'powerball': 'Powerball',
    'megamillions': 'Mega Millions',
    'lottoamerica': 'Lotto America',
    'roadrunnercash': 'Roadrunner Cash',
    'pick3plus': 'Pick3 Plus',
    'pick4plus': 'Pick4 Plus',
  };
  static String label(Map row) => row['variant'] == 'double_play'
      ? 'Powerball Double Play'
      : '${labels[row['game']]}${row['session'] == null ? '' : ' ${row['session']}'}';

  @override
  State<NewMexicoDrawCollectionSheet> createState() =>
      _NewMexicoDrawCollectionSheetState();
}

class _NewMexicoDrawCollectionSheetState
    extends State<NewMexicoDrawCollectionSheet> {
  late final data = widget.coverageOverride != null
      ? Future.value(widget.coverageOverride!)
      : NewMexicoCoverageLoader().load();
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
  List<Widget> schedule(Map rule, Map row) {
    final tables = rule['tables'] as List;
    const names = {
      'powerball': ['Powerball', 'Power Play', 'Double Play'],
      'megamillions': ['Mega Millions prizes', 'Per-play multiplier odds'],
      'lottoamerica': ['Lotto America', 'All Star Bonus'],
      'roadrunnercash': ['Roadrunner Cash'],
      'pick3plus': ['Pick3 Plus play types'],
      'pick4plus': ['Pick4 Plus play types'],
    };
    final widgets = <Widget>[];
    for (var t = 0; t < tables.length; t++) {
      if (row['game'] == 'powerball' &&
          (row['variant'] == 'double_play' ? t != 2 : t == 2)) {
        continue;
      }
      widgets.add(entry(names[row['game']]![t], []));
      // Expand only explicit HTML spans, so shared cells keep their printed labels.
      final grid = <List<Map?>>[];
      final table = tables[t] as List;
      for (var r = 0; r < table.length; r++) {
        while (grid.length <= r) {
          grid.add([]);
        }
        var col = 0;
        for (final cell in table[r] as List) {
          while (col < grid[r].length && grid[r][col] != null) {
            col++;
          }
          for (var dy = 0; dy < cell['rowspan']; dy++) {
            while (grid.length <= r + dy) {
              grid.add([]);
            }
            for (var dx = 0; dx < cell['colspan']; dx++) {
              while (grid[r + dy].length <= col + dx) {
                grid[r + dy].add(null);
              }
              grid[r + dy][col + dx] = cell as Map;
            }
          }
          col += cell['colspan'] as int;
        }
      }
      final headers = grid.first.map((c) => c?['text'] ?? '').toList();
      for (var r = 1; r < grid.length; r++) {
        widgets.add(
          entry('Schedule row $r', [
            for (var c = 0; c < grid[r].length; c++)
              '${c < headers.length ? headers[c] : 'Source cell'}: ${grid[r][c]?['text'] ?? ''}',
          ]),
        );
        for (final cell in grid[r].whereType<Map>().toSet()) {
          for (final picture in cell['images'] as List) {
            widgets.add(
              TextButton(
                onPressed: () => open(picture['src']),
                child: Text('Official ${cell['text']} example image'),
              ),
            );
          }
        }
      }
    }
    return widgets;
  }

  List<Widget> details(Map coverage, Map row) {
    final rule =
        (coverage['rules'] as List).singleWhere((r) => r['game'] == row['game'])
            as Map;
    final report = row['report'] as Map?;
    return [
      entry('${NewMexicoDrawCollectionSheet.label(row)} · ${row['date']}', [
        'New Mexico local drawing date',
        'Numbers: ${(row['numbers'] as List).join(' · ')}',
        if (row['specialBall'] != null) 'Special ball: ${row['specialBall']}',
        if (row['multiplier'] != null)
          '${row['game'] == 'powerball' ? 'Power Play' : 'All Star Bonus'}: ${row['multiplier']}X',
        if (row['game'] == 'megamillions')
          'Multiplier is assigned per play; no drawing-wide multiplier.',
        'Result retrieved: ${row['retrievedAt']}',
      ]),
      if (report == null)
        entry('Winner report unavailable', [
          'No verified exact-date New Mexico report in this snapshot. Unavailable does not mean zero winners.',
        ])
      else ...[
        entry('New Mexico exact-date report', [
          report['countNote'],
          'Report date: ${report['date']}',
          'Report retrieved: ${report['retrievedAt']}',
          'Source Total Prizes Won: ${report['totalPrizesWon']}',
          'Source Total Prize Value: \$${report['totalPrizeValue']}',
        ]),
        for (final tier in report['tiers'] as List)
          entry(tier['match'], [
            if (tier['column'] != null) 'Source column: ${tier['column']}',
            if (tier['multiplier'] != null)
              'Per-play multiplier: ${tier['multiplier']}X',
            'Prize: ${tier['prizeLabel']}',
            'Source Winners: ${tier['sourceWinners']}',
          ]),
        TextButton(
          onPressed: () => open(report['sourceUrl']),
          child: const Text('Official winner report'),
        ),
      ],
      entry('Prize schedules', [
        'Literal published schedules, not payouts for this drawing.',
      ]),
      ...schedule(rule, row),
      entry('Official rule text and conditions', [rule['text']]),
      entry('Rule retrieval', [rule['retrievedAt']]),
      TextButton(
        onPressed: () => open(rule['sourceUrl']),
        child: const Text('Official game rules'),
      ),
      entry('Coverage limits', [
        coverage['coverageNote'],
        ...List<String>.from(coverage['unavailable']),
      ]),
      TextButton(
        onPressed: () => open(row['sourceUrl']),
        child: const Text('Official dated results'),
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
                        'New Mexico coverage unavailable. Please try again later.',
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
                  'New Mexico results and schedules',
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
                      tooltip: 'Close New Mexico results',
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
                          '${NewMexicoDrawCollectionSheet.label(rows[i])} · ${rows[i]['date']}',
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
