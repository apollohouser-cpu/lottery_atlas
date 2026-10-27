import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/north_dakota_coverage_loader.dart';

class NorthDakotaDrawCollectionSheet extends StatefulWidget {
  const NorthDakotaDrawCollectionSheet({
    super.key,
    this.coverageOverride,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? coverageOverride;
  final int initialIndex;
  static const labels = {
    'powerball': 'Powerball',
    'mega-millions': 'Mega Millions',
    'millionaire-for-life': 'Millionaire for Life',
    '2by2': '2by2',
    'lotto-america': 'Lotto America',
  };
  static String label(Map row) => labels[row['game']]!;

  @override
  State<NorthDakotaDrawCollectionSheet> createState() =>
      _NorthDakotaDrawCollectionSheetState();
}

class _NorthDakotaDrawCollectionSheetState
    extends State<NorthDakotaDrawCollectionSheet> {
  late final data = widget.coverageOverride != null
      ? Future.value(widget.coverageOverride!)
      : NorthDakotaCoverageLoader().load();
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
  String prose(dynamic node) {
    if (node is String) return node;
    if (node is List) return node.map(prose).join(' ');
    return prose(node['children']);
  }

  List<Map> descendants(Map node, String tag) => [
    if (node['tag'] == tag) node,
    for (final child in node['children'])
      if (child is Map) ...descendants(child, tag),
  ];

  List<Widget> schedule(Map rule, Map row) {
    final game = row['game'];
    List<Widget> table(Map node) {
      final rows = descendants(node, 'tr');
      final start = game == 'millionaire-for-life' || game == '2by2' ? 2 : 3;
      final widgets = <Widget>[];
      final carry = <int, Map>{};
      for (var i = start; i < rows.length - 1; i++) {
        final cells = (rows[i]['children'] as List).whereType<Map>().toList();
        final values = <String>[];
        if (game == '2by2') {
          var index = 0;
          for (var col = 0; col < 4; col++) {
            if (carry.containsKey(col)) {
              values.add(carry[col]!['text']);
              carry[col]!['left']--;
              if (carry[col]!['left'] == 0) carry.remove(col);
            } else {
              final cell = cells[index++];
              values.add(prose(cell));
              final span = int.parse(cell['attrs']['rowspan'] ?? '1');
              if (span > 1) {
                carry[col] = {'text': prose(cell), 'left': span - 1};
              }
            }
          }
        } else {
          values.addAll(cells.map(prose));
        }
        final headers = game == '2by2'
            ? ['Match', 'Prize', 'Qualifying Tuesday double prize', 'Odds']
            : game == 'mega-millions'
            ? ['Match', 'Base', 'Per-play prize range', 'Odds']
            : game == 'millionaire-for-life'
            ? ['Match', 'Prize', 'Odds']
            : values.length == 4
            ? [
                'Match',
                'Base prize',
                game == 'powerball' ? 'Power Play' : 'All Star Bonus',
                'Odds',
              ]
            : game == 'powerball'
            ? [
                'Match',
                'Base prize',
                'Power Play 2X',
                'Power Play 3X',
                'Power Play 4X',
                'Power Play 5X',
                'Power Play 10X*',
                'Odds',
              ]
            : [
                'Match',
                'Base prize',
                'All Star Bonus 2X',
                'All Star Bonus 3X',
                'All Star Bonus 4X',
                'All Star Bonus 5X',
                'Odds',
              ];
        widgets.add(
          entry('Match ${values[0]}', [
            for (var j = 1; j < values.length; j++)
              '${headers[j]}: ${values[j]}',
          ]),
        );
      }
      widgets.add(entry('', [prose(rows.last)]));
      return widgets;
    }

    List<Widget> render(dynamic node) {
      if (node is! Map) return [];
      if (node['tag'] == 'table') return table(node);
      if (['h2', 'h3'].contains(node['tag'])) return [entry(prose(node), [])];
      if (['p', 'li'].contains(node['tag'])) {
        return [
          entry('', [prose(node)]),
        ];
      }
      return [for (final c in node['children']) ...render(c)];
    }

    return render(rule['document']);
  }

  List<Widget> details(Map coverage, Map row) {
    final rule =
        (coverage['rules'] as List).singleWhere((r) => r['game'] == row['game'])
            as Map;
    return [
      entry('${NorthDakotaDrawCollectionSheet.label(row)} · ${row['drawDate']}', [
        'Published drawing date only; no drawing time supplied.',
        '${row['game'] == '2by2' ? 'Red numbers' : 'Numbers'}: ${(row['numbers'] as List).join(' · ')}',
        if ((row['bonusNumbers'] as List).isNotEmpty)
          '${row['game'] == '2by2' ? 'White numbers' : 'Bonus ball'}: ${(row['bonusNumbers'] as List).join(' · ')}',
        if (row['multiplier'] != null)
          "${row['game'] == 'powerball' ? 'Power Play' : 'All Star Bonus'}: ${row['multiplier']}X",
        if (row['game'] == 'mega-millions')
          'Multiplier is assigned per play (2X, 3X, 4X, 5X or 10X); no drawing-wide multiplier.',
        if (row['game'] == '2by2')
          'Tuesday double prizes require qualifying consecutive 7-draw increments. Free Ticket and 2 Free Tickets are categorical prizes; see the full conditions below.',
        if (row['game'] == 'millionaire-for-life')
          'Lifetime top prizes are annual payments, not inferred lump sums.',
        'Result retrieved: ${row['sourceRetrievedAt']}',
      ]),
      entry('Winner report unavailable', [
        'No verified exact-date North Dakota count report. Unavailable does not mean zero winners.',
      ]),
      entry('Prize schedules', [
        'Published schedules and conditions, not payouts for this drawing.',
      ]),
      ...schedule(rule, row),
      entry('Rule retrieval', [rule['retrievedAt']]),
      TextButton(
        onPressed: () => open(rule['sourceUrl']),
        child: const Text('Official game rules'),
      ),
      entry('Current and retired products', [
        'Five current draw games. Lucky for Life ended February 21, 2026; retired results are unavailable here. North Dakota has no Scratch catalog.',
      ]),
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
                        'North Dakota coverage unavailable. Please try again later.',
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
                  'North Dakota results and schedules',
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
                      tooltip: 'Close North Dakota results',
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
                          '${NorthDakotaDrawCollectionSheet.label(rows[i])} · ${rows[i]['drawDate']}',
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
