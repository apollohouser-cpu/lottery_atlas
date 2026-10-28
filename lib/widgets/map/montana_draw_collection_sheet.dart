import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/montana_coverage_loader.dart';

class MontanaDrawCollectionSheet extends StatefulWidget {
  const MontanaDrawCollectionSheet({
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
    'powerball-double-play': 'Powerball Double Play',
    'montana-cash': 'Montana Cash',
    'big-sky-bonus': 'Big Sky Bonus',
    'lotto-america': 'Lotto America',
  };
  static String label(Map row) => labels[row['game']]!;

  @override
  State<MontanaDrawCollectionSheet> createState() =>
      _MontanaDrawCollectionSheetState();
}

class _MontanaDrawCollectionSheetState
    extends State<MontanaDrawCollectionSheet> {
  late final data = widget.coverageOverride != null
      ? Future.value(widget.coverageOverride!)
      : MontanaCoverageLoader().load();
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
    final widgets = <Widget>[];
    for (final section in rule['sections']) {
      final doublePlay = section['id'] == 'eael-data-table-wrapper-553a46a';
      widgets.add(
        entry(
          doublePlay
              ? 'Double Play schedule'
              : 'Published rules and conditions',
          [],
        ),
      );
      if (doublePlay) {
        widgets.add(
          entry('Source table discrepancy', [
            'The source labels its last columns Odds / Prize, but places money before odds. Below they are labeled Prize / Odds to match the literal cell contents. Double Play does not use Power Play.',
          ]),
        );
      }
      List<String>? cells;
      List<String>? cell;
      List<String>? headers;
      var inTable = false;
      for (final event in section['events']) {
        if (event[0] == 'start' && event[1] == 'table') {
          inTable = true;
          headers = null;
        }
        if (event[0] == 'start' && event[1] == 'tr') cells = [];
        if (event[0] == 'start' && ['td', 'th'].contains(event[1])) cell = [];
        if (event[0] == 'text') {
          if (cell != null) {
            cell.add(event[1]);
          } else if (!inTable) {
            widgets.add(entry('', [event[1]]));
          }
        }
        if (event[0] == 'end' && ['td', 'th'].contains(event[1])) {
          cells!.add(cell!.join(' '));
          cell = null;
        }
        if (event[0] == 'end' && event[1] == 'tr') {
          if (headers == null) {
            headers = doublePlay
                ? ['Match', 'Prize', 'Odds']
                : List<String>.from(cells!);
          } else {
            widgets.add(
              entry('Match ${cells!.first}', [
                for (var i = 1; i < cells.length; i++)
                  '${i < headers.length ? headers[i] : 'Source column ${i + 1}'}: ${cells[i]}',
              ]),
            );
          }
          cells = null;
        }
        if (event[0] == 'end' && event[1] == 'table') inTable = false;
      }
    }
    return widgets;
  }

  List<Widget> details(Map coverage, Map row) {
    final rule =
        (coverage['rules'] as List).singleWhere(
              (r) =>
                  r['game'] ==
                  (row['game'] == 'powerball-double-play'
                      ? 'powerball'
                      : row['game']),
            )
            as Map;
    return [
      entry('${MontanaDrawCollectionSheet.label(row)} · ${row['drawDate']}', [
        'Published drawing date only; no drawing time supplied.',
        'Numbers: ${(row['numbers'] as List).join(' · ')}',
        if ((row['bonusNumbers'] as List).isNotEmpty)
          'Bonus ball: ${(row['bonusNumbers'] as List).join(' · ')}',
        if (row['multiplier'] != null)
          "${row['game'] == 'powerball' ? 'Power Play' : 'All Star Bonus'}: ${row['multiplier']}X",
        if (row['game'] == 'mega-millions')
          'Multiplier is assigned per play (2X, 3X, 4X, 5X or 10X); no drawing-wide multiplier.',
        if (row['game'] == 'montana-cash')
          'Official purchase prose contains conflicting cost and Double Play wording. No additional Montana Cash draw variant is inferred. Advertised jackpot amounts are not actual payouts.',
        if (row['game'] == 'powerball' ||
            row['game'] == 'powerball-double-play')
          'Power Play and optional Double Play are separate. The published About prose contains an unverified geographic sales claim; it does not establish count geography.',
        if (row['game'] == 'millionaire-for-life')
          'Lifetime top prizes are annual payments, not inferred lump sums.',
        'Result retrieved: ${row['sourceRetrievedAt']}',
      ]),
      entry('Winner report unavailable', [
        'No verified exact-date Montana count report. Unavailable does not mean zero winners.',
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
        'Six current regular draw families plus optional Powerball Double Play. Lucky for Life is retired; historical results are unavailable here. Scratch and Treasure Play catalogs do not establish inventory or current sales status.',
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
                        'Montana coverage unavailable. Please try again later.',
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
                  'Montana results and schedules',
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
                      tooltip: 'Close Montana results',
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
                          '${MontanaDrawCollectionSheet.label(rows[i])} · ${rows[i]['drawDate']}',
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
