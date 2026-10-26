import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/new_mexico_coverage_loader.dart';

class NewMexicoProductSheet extends StatefulWidget {
  const NewMexicoProductSheet({
    super.key,
    this.coverageOverride,
    this.initialType = 'Scratch',
  });
  final Map<String, dynamic>? coverageOverride;
  final String initialType;
  @override
  State<NewMexicoProductSheet> createState() => _NewMexicoProductSheetState();
}

class _NewMexicoProductSheetState extends State<NewMexicoProductSheet> {
  late final data = widget.coverageOverride != null
      ? Future.value(widget.coverageOverride!)
      : NewMexicoCoverageLoader().load();
  late String type = widget.initialType;
  int? cost;
  final search = TextEditingController();
  @override
  void dispose() {
    search.dispose();
    super.dispose();
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

  int? price(Map g) =>
      g['listedPriceCents'] ??
      (g['cost'] == null ? null : ((g['cost'] as num) * 100).round());
  String priceLabel(Map g) => price(g) == null
      ? 'See official rules'
      : '\$${(price(g)! / 100).toStringAsFixed(2)}';
  String identity(Map g) => g['id'] ?? g['sourceGameId'] ?? '';
  Widget line(String text) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Text(text),
  );

  void detail(Map coverage, Map game) {
    final catalog = coverage['scratch'] as Map;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .88,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: _PagedInventoryBody(
            closeTooltip: 'Close game details',
            children: [
              Text(
                game['name'],
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              line('Scratch · Game ${identity(game)} · ${priceLabel(game)}'),
              line('Top prize: \$${game['topPrize']}'),
              line(
                'Estimated top prizes remaining: ${game['topPrizesRemaining']}',
              ),
              line(game['inventoryNote']),
              line('Inventory retrieved: ${catalog['retrievedAt']}'),
              line('Source timestamp timezone: unpublished'),
              line(
                'Sales end: ${game['endDate'] ?? 'not published in this snapshot'}',
              ),
              line(
                'Last day to redeem: ${game['lastDayToRedeem'] ?? 'not published in this snapshot'}',
              ),
              line('Ending notices retrieved: ${catalog['endingRetrievedAt']}'),
              line(
                'Includes ended games still within their claim period. No store stock, all-tier inventory or complete claims history.',
              ),
              TextButton(
                onPressed: () => open(game['sourceUrl']),
                child: const Text('Official estimated inventory'),
              ),
              TextButton(
                onPressed: () => open(catalog['endingSource']),
                child: const Text('Official ending and claim notices'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> status() => [
    line('Fast Play availability unverified'),
    line(
      'Status sources screened October 25, 2026; not a live availability check.',
    ),
    line(
      'The official page identifies Break \'Em, Chile Cash, Crazy8s, Lucky Day, Roadrunner Doubler and Tic Tac Toe as ended. It announces March 2026 ending for Jackpot7s and Red Hot Jackpot Bingo, and a March pause for JackpotUSA.',
    ),
    line(
      'Retained sales text does not verify reopening. Current catalog, remaining inventory and progressive values are unavailable; unavailable is not zero.',
    ),
    TextButton(
      onPressed: () => open('https://www.nmlottery.com/games/fast-play/'),
      child: const Text('Official Fast Play status'),
    ),
    line('Historical games'),
    line(
      'Daily Millions, Mega Match4, 4 This Way!, Hot Lotto, legacy Pick3/Pick4, Lucky Numbers Bingo, MONOPOLY MILLIONAIRES’ CLUB and New Year’s Eve Raffle histories are unavailable here. Lucky Numbers Bingo ended in March 2019. Archive selectors do not establish complete records.',
    ),
    line('Promotions and second chance'),
    line(
      'Promotions and player rewards are separate from ordinary drawing results. Comprehensive prize/claims records and retailer-linked wins are unavailable.',
    ),
    TextButton(
      onPressed: () => open('https://www.nmlottery.com/games/'),
      child: const Text('Official games and promotions'),
    ),
  ];

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
                        'New Mexico inventory unavailable. Please try again later.',
                      )
                    : const CircularProgressIndicator(),
              );
            }
            final coverage = snapshot.data!;
            final games = coverage['scratch']['games'] as List;
            final costs =
                games.map((g) => price(g)).whereType<int>().toSet().toList()
                  ..sort();
            final filtered = games
                .where(
                  (g) =>
                      (cost == null || price(g) == cost) &&
                      ('${g['name']} ${identity(g)}'.toLowerCase().contains(
                        search.text.toLowerCase(),
                      )),
                )
                .toList();
            return _PagedInventoryBody(
              closeTooltip: 'Close New Mexico inventory',
              children: [
                const Text(
                  'New Mexico Scratch and game status',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  value: type,
                  items: [
                    for (final t in ['Scratch', 'Game status'])
                      DropdownMenuItem(value: t, child: Text(t)),
                  ],
                  onChanged: (v) {
                    if (v != null) {
                      setState(() {
                        type = v;
                        cost = null;
                        search.clear();
                      });
                    }
                  },
                ),
                if (type == 'Game status')
                  ...status()
                else ...[
                  Text('Collection completed: ${coverage['updatedAt']}'),
                  Text(
                    'Estimated source inventory: ${coverage['scratch']['sourceTimestamp']} (timezone unpublished)',
                  ),
                  TextField(
                    controller: search,
                    decoration: const InputDecoration(
                      labelText: 'Search game name or number',
                    ),
                    onChanged: (_) => setState(() {}),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          value: cost,
                          hint: const Text('All prices'),
                          items: [
                            const DropdownMenuItem<int>(
                              value: null,
                              child: Text('All prices'),
                            ),
                            for (final c in costs)
                              DropdownMenuItem(
                                value: c,
                                child: Text(
                                  '\$${(c / 100).toStringAsFixed(2)}',
                                ),
                              ),
                          ],
                          onChanged: (v) => setState(() => cost = v),
                        ),
                      ),
                      TextButton(
                        onPressed: () => setState(() {
                          cost = null;
                          search.clear();
                        }),
                        child: const Text('Reset'),
                      ),
                    ],
                  ),
                  Text(
                    '${filtered.length} of ${games.length} $type entries in catalog',
                  ),
                  const Text(
                    'Estimated top-prize entries within published claim deadlines. Counts may include sold tickets awaiting redemption. No retailer stock or complete claims history.',
                  ),
                  for (final game in filtered)
                    ListTile(
                      title: Text('${game['name']} ${identity(game)}'),
                      subtitle: Text(
                        '${priceLabel(game)} · Estimated top prizes',
                      ),
                      onTap: () => detail(coverage, game),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    ),
  );
}

/// Keeps reading and exit controls reachable on short, enlarged layouts.
class _PagedInventoryBody extends StatefulWidget {
  const _PagedInventoryBody({
    required this.children,
    required this.closeTooltip,
  });
  final List<Widget> children;
  final String closeTooltip;

  @override
  State<_PagedInventoryBody> createState() => _PagedInventoryBodyState();
}

class _PagedInventoryBodyState extends State<_PagedInventoryBody> {
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
            tooltip: 'Previous inventory page',
            onPressed: () => page(-1),
            icon: const Icon(Icons.arrow_upward),
          ),
          IconButton(
            tooltip: 'Next inventory page',
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
