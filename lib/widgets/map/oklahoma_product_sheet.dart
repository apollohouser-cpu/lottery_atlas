import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/oklahoma_coverage_loader.dart';

class OklahomaProductSheet extends StatefulWidget {
  const OklahomaProductSheet({
    super.key,
    this.coverageOverride,
    this.initialType = 'Scratch',
  });
  final Map<String, dynamic>? coverageOverride;
  final String initialType;
  @override
  State<OklahomaProductSheet> createState() => _OklahomaProductSheetState();
}

class _OklahomaProductSheetState extends State<OklahomaProductSheet> {
  late final data = widget.coverageOverride != null
      ? Future.value(widget.coverageOverride!)
      : OklahomaCoverageLoader().load();
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

  bool unavailable(Map g) =>
      g['inventoryStatus'] == 'unavailable' ||
      (g['prizeTiers'] as List).isEmpty;

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
    final fastPlay = type == 'Fast Play';
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
              line('$type · Game ${identity(game)} · ${priceLabel(game)}'),
              line('Retrieved: ${game['retrievedAt']}'),
              line('Inventory verification date: unavailable in source.'),
              line(game['inventoryNote']),
              line('Game start: ${game['startDate']}'),
              line('Original tickets: ${game['totalTickets']}'),
              if (fastPlay) ...[
                line(
                  'Variable progressive estimate: ${game['progressiveEstimate'] == null ? 'unavailable' : '\$${game['progressiveEstimate']}'}',
                ),
                line(
                  'The estimate is separate from the categorical JACKPOT tier. It is not a fixed prize, payout or claim.',
                ),
              ],
              if (unavailable(game))
                line('Remaining prizes unavailable — not zero.'),
              for (final tier in game['prizeTiers']) ...[
                line(
                  'Prize: ${tier['prizeAmount'] == null ? tier['prizeLabel'] : '\$${tier['prizeAmount']}'}',
                ),
                line('Original quantity: ${tier['totalPrizes']}'),
                line('Remaining: ${tier['remainingPrizes'] ?? 'unavailable'}'),
              ],
              line(
                'Remaining prizes are not retailer stock or complete claims history.',
              ),
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
                        'Oklahoma inventory unavailable. Please try again later.',
                      )
                    : const CircularProgressIndicator(),
              );
            }
            final coverage = snapshot.data!;
            final games =
                coverage['products'][type == 'Scratch'
                        ? 'scratch'
                        : 'fastPlay']['games']
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
              closeTooltip: 'Close Oklahoma inventory',
              children: [
                const Text(
                  'Oklahoma product catalogs',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  value: type,
                  items: [
                    for (final t in ['Scratch', 'Fast Play'])
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
                Text('Collection completed: ${coverage['updatedAt']}'),
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
                  'Scratch and Fast Play show bounded remaining and original quantities or explicit unknowns. Progressive estimates are separate from prize tiers. No retailer stock or complete claims history.',
                ),
                for (final game in filtered)
                  ListTile(
                    title: Text('${game['name']} ${identity(game)}'),
                    subtitle: Text(
                      '${priceLabel(game)} · ${unavailable(game) ? 'Inventory unavailable' : 'Bounded remaining counts'}',
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
