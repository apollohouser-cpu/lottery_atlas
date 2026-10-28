import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/montana_coverage_loader.dart';

class MontanaProductSheet extends StatefulWidget {
  const MontanaProductSheet({
    super.key,
    this.coverageOverride,
    this.initialType = 'Scratch',
  });
  final Map<String, dynamic>? coverageOverride;
  final String initialType;
  @override
  State<MontanaProductSheet> createState() => _MontanaProductSheetState();
}

class _MontanaProductSheetState extends State<MontanaProductSheet> {
  late final data = widget.coverageOverride != null
      ? Future.value(widget.coverageOverride!)
      : MontanaCoverageLoader().load();
  late String type = widget.initialType;
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  Widget line(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(text),
  );
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

  Widget link(String label, String url) =>
      TextButton(onPressed: () => open(url), child: Text(label));
  String title(Map game) => game['title'] ?? 'Title unavailable';
  void detail(Map catalog, Map game, String url) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .88,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _PagedProductBody(
            closeTooltip: 'Close product details',
            children: [
              line(title(game)),
              line('Website entry ${game['cmsEntryId']} · \$${game['price']}'),
              line(
                'Website entry IDs are not printed game numbers. No title-based join to ending notices.',
              ),
              line(
                'Sales status and remaining prizes unavailable — not zero. Catalog appearance does not establish retailer stock.',
              ),
              line('Retrieved: ${catalog['retrievedAt']}'),
              line(game['overallOddsText'] ?? 'Overall odds unavailable'),
              line('Literal source wording'),
              line(
                (game['literalText'] as String).replaceAll(
                  '[advertised estimate]',
                  game['advertisedJackpot']['amountText'] ?? 'unavailable',
                ),
              ),
              if (game['advertisedJackpot']['amountText'] != null) ...[
                line(
                  'Advertised progressive estimate: ${game['advertisedJackpot']['amountText']}',
                ),
                line(
                  'Estimate only; not an actual payout, fixed prize or winner count.',
                ),
              ],
              for (final prose in game['prose'])
                line(
                  prose.toString().replaceAll(
                    '[advertised estimate]',
                    game['advertisedJackpot']['amountText'] ?? 'unavailable',
                  ),
                ),
              line('Literal prize structure'),
              for (final row in game['scheduleRows']) ...[
                line('Win: ${row['winText']}'),
                line('Prize: ${row['prizeText']}'),
                line('Odds: ${row['oddsText']}'),
              ],
              line(
                'Prize structures are not original or remaining prize quantities. Ticket and Jackpot labels remain categorical.',
              ),
              for (var i = 0; i < (game['images'] as List).length; i++)
                link('Official image ${i + 1}', game['images'][i]),
              link('Official product catalog', url),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> content(Map d) {
    if (type == 'Ending notice') {
      final ending = d['endings'];
      return [
        line('Scratch ending notice'),
        line(
          'Source printed: ${ending['sourcePrintedAt']} · timezone unpublished',
        ),
        line('Retrieved: ${ending['sourceRetrievedAt']}'),
        line(
          'Separate numbered-game notice. These rows are not joined to website catalog entries; matching titles do not establish the same edition. Absence never means active.',
        ),
        for (final row in ending['rows']) ...[
          line('Game ${row['gameNumber']} · ${row['title']}'),
          line('Sales start: ${row['salesStartDate']}'),
          line('Sales end: ${row['salesEndDate']}'),
          line('Last redemption: ${row['lastRedemptionDate']}'),
        ],
        link('Official ending notice', ending['sourceUrl']),
      ];
    }
    if (type == 'Raffle') {
      final raffle = d['raffle'];
      return [
        line('Montana Millionaire ${raffle['edition']} offer'),
        line(
          'Planned prize quantities, not actual winners. Current results unavailable; historical results excluded.',
        ),
        line(
          'Sales start: ${raffle['salesStartLocalText']} · timezone unpublished',
        ),
        line('Promotional drawing: ${raffle['promotionalDrawingDate']}'),
        line('Final drawing: ${raffle['finalDrawingDate']}'),
        line('Retrieved: ${raffle['retrievedAt']}'),
        // Pair every literal table cell with its column, preserving offer semantics.
        for (final section in raffle['sections']) ...offerSection(section),
        link('Official raffle offer', raffle['sourceUrl']),
      ];
    }
    final kind = type == 'Scratch' ? 'scratch' : 'treasure-play';
    final catalog = d['catalogs'][kind];
    final games = (catalog['entries'] as List)
        .where(
          (g) => '${title(g)} ${g['cmsEntryId']}'.toLowerCase().contains(
            search.text.toLowerCase(),
          ),
        )
        .toList();
    final url =
        'https://montanalottery.com/${kind == 'scratch' ? 'scratch-games' : 'treasure-play'}/';
    return [
      line(catalog['coverage']),
      line(
        'Sales status and remaining inventory unavailable. Website IDs are not printed game numbers.',
      ),
      TextField(
        controller: search,
        decoration: const InputDecoration(
          labelText: 'Search title or website entry',
        ),
        onChanged: (_) => setState(() {}),
      ),
      TextButton(
        onPressed: () {
          search.clear();
          setState(() {});
        },
        child: const Text('Reset search'),
      ),
      line('${games.length} catalog entries'),
      if (games.isEmpty) line('No matching catalog entries.'),
      for (final game in games)
        ListTile(
          title: Text(title(game)),
          subtitle: Text(
            'Website entry ${game['cmsEntryId']} · \$${game['price']} · remaining unavailable',
          ),
          onTap: () => detail(catalog, game, url),
        ),
      link('Official product catalog', url),
    ];
  }

  List<Widget> offerSection(Map section) {
    final result = <Widget>[];
    List<String>? cells;
    List<String>? cell;
    List<String>? headers;
    var table = false;
    for (final event in section['events']) {
      if (event[0] == 'start' && event[1] == 'table') {
        table = true;
        headers = null;
      }
      if (event[0] == 'start' && event[1] == 'tr') cells = [];
      if (event[0] == 'start' && ['td', 'th'].contains(event[1])) cell = [];
      if (event[0] == 'text') {
        if (cell != null) {
          cell.add(event[1]);
        } else if (!table) {
          result.add(line(event[1]));
        }
      }
      if (event[0] == 'end' && ['td', 'th'].contains(event[1])) {
        cells!.add(cell!.join(' '));
        cell = null;
      }
      if (event[0] == 'end' && event[1] == 'tr') {
        if (headers == null) {
          headers = List<String>.from(cells!);
        } else {
          for (var i = 0; i < cells!.length; i++) {
            result.add(
              line(
                '${i < headers.length ? headers[i] : 'Source column ${i + 1}'}: ${cells[i]}',
              ),
            );
          }
        }
        cells = null;
      }
      if (event[0] == 'end' && event[1] == 'table') table = false;
    }
    return result;
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
                    ? const Text('Montana products unavailable.')
                    : const CircularProgressIndicator(),
              );
            }
            return _PagedProductBody(
              key: ValueKey(type),
              closeTooltip: 'Close Montana products',
              children: [
                const Text(
                  'Montana catalogs and notices',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  value: type,
                  items: [
                    for (final label in [
                      'Scratch',
                      'Treasure Play',
                      'Raffle',
                      'Ending notice',
                    ])
                      DropdownMenuItem(value: label, child: Text(label)),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        type = v;
                        search.clear();
                      });
                    }
                  },
                ),
                ...content(snapshot.data!),
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// Keeps reading and exit controls reachable on short, enlarged layouts.
class _PagedProductBody extends StatefulWidget {
  const _PagedProductBody({
    super.key,
    required this.children,
    required this.closeTooltip,
  });
  final List<Widget> children;
  final String closeTooltip;

  @override
  State<_PagedProductBody> createState() => _PagedProductBodyState();
}

class _PagedProductBodyState extends State<_PagedProductBody> {
  final scroll = ScrollController();

  @override
  void dispose() {
    scroll.dispose();
    super.dispose();
  }

  void page(int direction) {
    if (!scroll.hasClients) return;
    final p = scroll.position;
    scroll.animateTo(
      (p.pixels + direction * p.viewportDimension * .8).clamp(
        p.minScrollExtent,
        p.maxScrollExtent,
      ),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) => Column(
    children: [
      Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          IconButton(
            tooltip: 'Previous product page',
            onPressed: () => page(-1),
            icon: const Icon(Icons.arrow_upward),
          ),
          IconButton(
            tooltip: 'Next product page',
            onPressed: () => page(1),
            icon: const Icon(Icons.arrow_downward),
          ),
          IconButton(
            tooltip: widget.closeTooltip,
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
          ),
        ],
      ),
      Expanded(
        child: ListView(controller: scroll, children: widget.children),
      ),
    ],
  );
}
