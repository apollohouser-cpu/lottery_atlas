import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/oklahoma_coverage_loader.dart';

class OklahomaDrawCollectionSheet extends StatefulWidget {
  const OklahomaDrawCollectionSheet({
    super.key,
    this.coverageOverride,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? coverageOverride;
  final int initialIndex;
  static const labels = {
    'powerball': 'Powerball',
    'megamillions': 'Mega Millions',
    'lotto-america': 'Lotto America',
    'millionaire-for-life': 'Millionaire for Life',
    'powerball-xs-os': 'Powerball Xs & Os',
    'pick3': 'Pick3',
    'cash-5': 'Cash5',
  };
  static String label(Map row) => row['variant'] == 'double_play'
      ? 'Powerball Double Play'
      : labels[row['game']]!;

  @override
  State<OklahomaDrawCollectionSheet> createState() =>
      _OklahomaDrawCollectionSheetState();
}

class _OklahomaDrawCollectionSheetState
    extends State<OklahomaDrawCollectionSheet> {
  late final data = widget.coverageOverride != null
      ? Future.value(widget.coverageOverride!)
      : OklahomaCoverageLoader().load();
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
    if (node == null) return '';
    if (node['type'] == 'text') return node['text'] as String;
    final separator = node['type'] == 'paragraph' ? ' ' : '\n';
    return (node['children'] as List).map(prose).join(separator);
  }

  String literal(dynamic value) => value.toString().replaceAll(r'$$', r'$');
  List<Widget> details(Map coverage, Map row) {
    final rule =
        (coverage['rules'] as List).singleWhere((r) => r['game'] == row['game'])
            as Map;
    final doublePlay = row['variant'] == 'double_play';
    final groups = rule['prizeLegend'] as List;
    return [
      entry('${OklahomaDrawCollectionSheet.label(row)} · ${row['date']}', [
        'Oklahoma local drawing date',
        '${row['valueKind'] == 'source_codes' ? 'Literal source codes' : 'Numbers'}: ${(row['numbers'] as List).join(' · ')}',
        if (row['specialBall'] != null) 'Special ball: ${row['specialBall']}',
        if (row['multiplier'] != null)
          '${row['game'] == 'powerball' ? 'Power Play' : 'All Star Bonus'}: ${row['multiplier']}X',
        if (row['game'] == 'megamillions')
          'Multiplier is assigned per play; no drawing-wide multiplier.',
        if (row['game'] == 'pick3')
          'Session unavailable. Verified Midday and Evening histories are unavailable.',
        'Retrieved: ${row['retrievedAt']}',
      ]),
      entry('Winner report unavailable', [
        row['reportNote'] as String,
        'Unavailable does not mean zero winners.',
      ]),
      if (rule['sourceNote'] != null)
        entry('Source limitation', [rule['sourceNote'] as String]),
      entry('Prize schedules', [
        'Literal published schedules, not payouts for this drawing.',
      ]),
      for (var g = 0; g < (doublePlay ? 1 : groups.length); g++) ...[
        entry((groups[g]['title'] as String?) ?? '', []),
        for (final tier in groups[g]['matches'] as List)
          entry(literal(tier['match']), [
            for (final column in groups[g]['columnOrder'] as List)
              if (column.toString().toLowerCase() != 'match' &&
                  !(doublePlay &&
                      column.toString().toLowerCase() == 'powerball prize') &&
                  !(!doublePlay &&
                      column.toString().toLowerCase() == 'double play prize'))
                '$column: ${literal(tier[column.toString().toLowerCase()])}',
          ]),
      ],
      for (final section in {
        'How to play': 'howToPlay',
        'Source sales and drawing notice': 'disclaimer',
        'Prize conditions': 'prizeLegendPrimaryDescription',
        'Schedule notes': 'prizeLegendDescription',
      }.entries)
        if (rule[section.value] != null)
          entry(section.key, [prose(rule[section.value])]),
      entry('Coverage limits', [
        coverage['coverageNote'] as String,
        'Older and retired-game history is unavailable. Source codes are not inferred team names.',
      ]),
      TextButton(
        onPressed: () => open(row['sourceUrl']),
        child: const Text('Official game rules and results'),
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
                        'Oklahoma coverage unavailable. Please try again later.',
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
                  'Oklahoma results and schedules',
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
                      tooltip: 'Close Oklahoma results',
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
                          '${OklahomaDrawCollectionSheet.label(rows[i])} · ${rows[i]['date']}',
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
