import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/wyoming_coverage_loader.dart';

class WyomingDrawCollectionSheet extends StatefulWidget {
  const WyomingDrawCollectionSheet({
    super.key,
    this.coverageOverride,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? coverageOverride;
  final int initialIndex;
  static const labels = {
    'cowboy-draw': 'Cowboy Draw',
    'powerball': 'Powerball',
    'mega-millions': 'Mega Millions',
    'millionaire-for-life': 'Millionaire for Life',
    '2by2': '2by2',
    'keno': 'Keno',
  };
  static String label(Map row) =>
      '${labels[row['game']]}${row['game'] == 'keno' ? ' #${row['drawId']}' : ''}';

  @override
  State<WyomingDrawCollectionSheet> createState() =>
      _WyomingDrawCollectionSheetState();
}

class _WyomingDrawCollectionSheetState
    extends State<WyomingDrawCollectionSheet> {
  late final data = widget.coverageOverride != null
      ? Future.value(widget.coverageOverride!)
      : WyomingCoverageLoader().load();
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
    if (node is List) {
      return node.map(prose).where((s) => s.isNotEmpty).join(' ');
    }
    if (node is! Map) return '';
    if (node['type'] == 'text') return node['data']['text'] as String;
    return prose(node['content']);
  }

  List<Widget> schedule(Map rule, Map row) {
    final widgets = <Widget>[];
    final visual = rule['visualSchedule'] as Map?;
    if (visual != null) {
      for (final cells in visual['rows'] as List) {
        widgets.add(
          entry('Match ${cells[0]}', [
            'Scheduled prize: ${cells[1]}',
            if (cells.length > 2) 'Qualifying Tuesday prize: ${cells[2]}',
          ]),
        );
      }
      widgets.add(entry('Overall odds', [visual['overallOdds']]));
      widgets.add(
        TextButton(
          onPressed: () => open(rule['image']['url']),
          child: const Text('Official schedule image'),
        ),
      );
    }
    for (final section in rule['rules'] as List) {
      widgets.add(entry(section['title'], []));
      for (final block in section['content'] as List) {
        final d = block['data'] as Map;
        if (block['contentType'] == 'text') {
          for (final paragraph in d['document'] as List) {
            final text = prose(paragraph);
            if (text.isNotEmpty) widgets.add(entry('', [text]));
          }
        } else if (block['contentType'] == 'csvTable') {
          widgets.add(entry(d['name'], []));
          final headers = d['headers'] as List;
          for (final cells in d['rows'] as List) {
            widgets.add(
              entry('Match ${cells[0]}', [
                for (var i = 0; i < cells.length; i++)
                  '${headers[i]}: ${cells[i]}',
              ]),
            );
          }
          widgets.add(entry('', List<String>.from(d['footer'] ?? [])));
        }
      }
    }
    return widgets;
  }

  List<Widget> details(Map coverage, Map row) {
    final rule =
        (coverage['rules'] as List).singleWhere((r) => r['game'] == row['game'])
            as Map;
    return [
      entry('${WyomingDrawCollectionSheet.label(row)} · ${row['drawDate']}', [
        'Wyoming local drawing date (America/Denver)',
        'Drawing ID: ${row['drawId']}',
        'Drawing time (UTC): ${row['drawTimeUtc']}',
        '${row['game'] == '2by2' ? 'White numbers' : 'Numbers'}: ${(row['numbers'] as List).join(' · ')}',
        if (row['game'] != 'keno' && (row['bonusNumbers'] as List).isNotEmpty)
          '${row['game'] == '2by2' ? 'Red numbers' : 'Bonus ball'}: ${(row['bonusNumbers'] as List).join(' · ')}',
        if (row['multiplier'] != null) 'Power Play: ${row['multiplier']}X',
        if (row['game'] == 'mega-millions')
          'Multiplier is assigned per play (2X, 3X, 4X, 5X or 10X); no drawing-wide multiplier.',
        if (row['game'] == 'keno')
          'Five bounded drawing IDs only. No continuous history or live-draw claim. Schedules below use a \$1 wager.',
        if (row['game'] == '2by2')
          'Tuesday doubling requires qualifying multidraw tickets. Free-play redemptions are excluded; free plays are categorical prizes. Source asterisks are retained without inference.',
        if (row['game'] == 'millionaire-for-life')
          'Lifetime top prizes are annual payments, not inferred lump sums.',
        'Result retrieved: ${row['sourceRetrievedAt']}',
      ]),
      entry('Winner report unavailable', [
        'No verified exact-date Wyoming count report. Unavailable does not mean zero winners.',
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
                        'Wyoming coverage unavailable. Please try again later.',
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
                  'Wyoming results and schedules',
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
                      tooltip: 'Close Wyoming results',
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
                          '${WyomingDrawCollectionSheet.label(rows[i])} · ${rows[i]['drawDate']}',
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
