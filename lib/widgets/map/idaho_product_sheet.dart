import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/idaho_coverage_loader.dart';

class IdahoProductSheet extends StatefulWidget {
  const IdahoProductSheet({
    super.key,
    this.coverageOverride,
    this.initialType = 'Scratch',
  });
  final Map<String, dynamic>? coverageOverride;
  final String initialType;
  @override
  State<IdahoProductSheet> createState() => _IdahoProductSheetState();
}

class _IdahoProductSheetState extends State<IdahoProductSheet> {
  late final data = widget.coverageOverride != null
      ? Future.value(widget.coverageOverride!)
      : IdahoCoverageLoader().load();
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
    final scratch = type == 'Scratch';
    final raffle = type == 'Raffle';
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
              line('$type · ${priceLabel(game)}'),
              line('Collected: ${coverage['collectionStartedAt']}'),
              if (scratch) ...[
                line('Inventory verification date: unavailable in source.'),
                line(game['inventoryNote']),
                for (final dateLabel in {
                  'startDate': 'Game start',
                  'endDistributionDate': 'Distribution ended',
                  'gameEndDate': 'Game ends',
                  'lastDayToRedeem': 'Redeem by',
                }.entries)
                  if (game[dateLabel.key] != null)
                    line('${dateLabel.value}: ${game[dateLabel.key]}'),
                if (game['inventoryStatus'] == 'unavailable')
                  line('Remaining prizes unavailable — not zero.'),
                for (final tier
                    in game['prizeTiers'] ?? game['prizeStructure']) ...[
                  line('Prize: \$${tier['prizeAmount']}'),
                  line('Original structure quantity: ${tier['original']}'),
                  line('Remaining: ${tier['remaining'] ?? 'unavailable'}'),
                  if (tier['sourceOdds'] != null)
                    line('Source odds: ${tier['sourceOdds']}'),
                ],
                if ((game['unavailableRemainingPrizeAmounts'] as List?)
                        ?.isNotEmpty ??
                    false)
                  line(
                    'Remaining counts unavailable for prize amounts: ${game['unavailableRemainingPrizeAmounts'].join(', ')}',
                  ),
              ] else if (raffle) ...[
                line(
                  'Final drawing result unavailable. Daily promotions are separate.',
                ),
                for (final p in game['dailyPromotions'])
                  line('Daily promotion ${p['date']}: ${p['ticketNumber']}'),
                for (final limitation in game['limitations']) line(limitation),
                for (final row in (game['schedule'] as List).skip(1))
                  line(
                    'Schedule quantity: ${row[0]} · Prize: ${row[1]} · Odds: ${row[2]}',
                  ),
                for (final text in game['sourceRules']) line(text),
              ] else ...[
                line(game['limitation']),
                line(game['listedPriceMeaning']),
                line('Remaining inventory unavailable.'),
                for (final tier in game['tiers']) ...[
                  if (tier['sourceWagerLabel'] != null)
                    line('Wager: ${tier['sourceWagerLabel']}'),
                  line(
                    tier['prizeStatus'] == 'unavailable_source_placeholder'
                        ? 'Prize unavailable (source placeholder: ${tier['sourcePrizeLabel']})'
                        : '${game['scheduleType'] == 'touch_wager' ? 'Top prize at this wager' : 'Printed prize'}: ${tier['sourcePrizeLabel']}',
                  ),
                  if (tier['schedulePrizeCount'] != null)
                    line('Schedule quantity: ${tier['schedulePrizeCount']}'),
                  line(
                    'Source odds: ${tier['sourceOdds'] ?? tier['sourceOverallOdds']}',
                  ),
                ],
                line(game['rules']),
                line(game['sourceOddsText']),
              ],
              TextButton(
                onPressed: () => open(game['sourceUrl']),
                child: const Text('Official game details'),
              ),
            ],
          ),
        ),
      ),
    );
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
                        'Idaho inventory unavailable. Please try again later.',
                      )
                    : const CircularProgressIndicator(),
              );
            }
            final coverage = snapshot.data!;
            final games = type == 'Scratch'
                ? [
                    ...coverage['scratch']['games'],
                    ...coverage['scratch']['unavailableInventoryGames'],
                  ]
                : type == 'Raffle'
                ? [
                    {...coverage['raffle'], 'name': 'Idaho Raffle 2026'},
                  ]
                : coverage['instantCatalogs'][type == 'InstaPlay'
                          ? 'instaplay'
                          : 'tabs']['games']
                      as List;
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
              closeTooltip: 'Close Idaho inventory',
              children: [
                const Text(
                  'Idaho product catalogs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  value: type,
                  items: [
                    for (final t in ['Scratch', 'InstaPlay', 'Tabs', 'Raffle'])
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
                Text('Collected: ${coverage['collectionStartedAt']}'),
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
                              child: Text('\$${(c / 100).toStringAsFixed(2)}'),
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
                  'Scratch has bounded remaining counts or explicit unknowns. InstaPlay and Tabs are printed schedules, not remaining inventory. No stock, claims or progressive inference.',
                ),
                for (final game in filtered)
                  ListTile(
                    title: Text('${game['name']} ${identity(game)}'),
                    subtitle: Text(
                      '${priceLabel(game)} · ${type == 'Scratch' ? (game['inventoryStatus'] == 'unavailable' ? 'Inventory unavailable' : 'Bounded remaining counts') : 'Published schedule'}',
                    ),
                    onTap: () => detail(coverage, game),
                  ),
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
