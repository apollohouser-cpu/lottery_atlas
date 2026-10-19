import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/iowa_coverage_loader.dart';

class IowaInstantInventorySheet extends StatefulWidget {
  const IowaInstantInventorySheet({
    super.key,
    this.coverageOverride,
    this.initialType = 'Scratch',
  });
  final Map<String, dynamic>? coverageOverride;
  final String initialType;
  @override
  State<IowaInstantInventorySheet> createState() =>
      _IowaInstantInventorySheetState();
}

class _IowaInstantInventorySheetState extends State<IowaInstantInventorySheet> {
  late final data = widget.coverageOverride != null
      ? Future.value(widget.coverageOverride!)
      : IowaCoverageLoader().load();
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

  void detail(Map coverage, Map subset, Map game) {
    final scratch = type == 'Scratch'
        ? (coverage['scratchCatalog']['games'] as List).firstWhere(
            (g) => g['id'] == game['id'],
          )
        : null;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SizedBox(
        height: MediaQuery.sizeOf(context).height * .88,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${game['name']} (${game['id']})',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  tooltip: 'Close game details',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ),
              Expanded(
                child: ListView(
                  children: [
                    Text('${subset['productType']} · \$${game['cost']}'),
                    Text(
                      'Report source date: ${coverage['instantInventories']['sourceDate']}',
                    ),
                    const Text(
                      'Published prizes of \$50 or more. Cumulative claimed/unclaimed counts, not dated claims or store stock.',
                    ),
                    if (scratch != null) ...[
                      Text(scratch['inventoryNote']),
                      for (final entry in {
                        'startDate': 'Game start',
                        'endDistributionDate': 'Distribution ended',
                        'gameEndDate': 'Game ends',
                        'lastDayToRedeem': 'Redeem by',
                      }.entries)
                        if (scratch[entry.key] != null)
                          Text('${entry.value}: ${scratch[entry.key]}'),
                    ] else
                      const Text(
                        'This report does not supply the full prize schedule or a current progressive jackpot. See the official product page for those details.',
                      ),
                    for (final tier in game['prizeTiers'])
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Published prize: \$${tier['prizeAmount']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Cumulative claimed: ${tier['claimed']}'),
                            Text('Unclaimed: ${tier['unclaimed']}'),
                          ],
                        ),
                      ),
                    TextButton(
                      onPressed: () => open(
                        scratch?['sourceUrl'] ?? subset['officialRoute'],
                      ),
                      child: Text(
                        scratch != null
                            ? 'Official game details'
                            : 'Official product page',
                      ),
                    ),
                    TextButton(
                      onPressed: () =>
                          open(coverage['instantInventories']['sourceUrl']),
                      child: const Text('Official dated inventory report'),
                    ),
                  ],
                ),
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
                        'Iowa inventory unavailable. Please try again later.',
                      )
                    : const CircularProgressIndicator(),
              );
            }
            final coverage = snapshot.data!,
                inventory = coverage['instantInventories'];
            final subset = (inventory['inventories'] as List).firstWhere(
              (s) => s['productType'] == type,
            );
            final games = subset['games'] as List;
            final costs = games.map((g) => g['cost'] as int).toSet().toList()
              ..sort();
            final filtered = games
                .where(
                  (g) =>
                      (cost == null || g['cost'] == cost) &&
                      ('${g['name']} ${g['id']}'.toLowerCase().contains(
                        search.text.toLowerCase(),
                      )),
                )
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Iowa instant prize inventories',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    tooltip: 'Close Iowa inventory',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  value: type,
                  items: [
                    for (final t in ['Scratch', 'InstaPlay', 'PullTab'])
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
                Text(
                  'Source date: ${inventory['sourceDate']} · \$50-plus report subset',
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
                            DropdownMenuItem(value: c, child: Text('\$$c')),
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
                  '${filtered.length} of ${games.length} $type games in report',
                ),
                Expanded(
                  child: ListView(
                    children: [
                      const Text(
                        'Cumulative inventory, not dated winners or store availability. Below-\$50 prizes and progressive jackpots are not included.',
                      ),
                      for (final game in filtered)
                        ListTile(
                          title: Text('${game['name']} (${game['id']})'),
                          subtitle: Text(
                            '\$${game['cost']} · ${game['prizeTiers'].length} published tiers',
                          ),
                          onTap: () => detail(coverage, subset, game),
                        ),
                    ],
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
