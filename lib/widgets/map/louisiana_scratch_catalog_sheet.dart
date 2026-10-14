import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/louisiana_scratch_catalog_loader.dart';

class LouisianaScratchCatalogSheet extends StatefulWidget {
  const LouisianaScratchCatalogSheet({
    super.key,
    this.catalogOverride,
    this.loader,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? catalogOverride;
  final LouisianaScratchCatalogLoader? loader;
  final int initialIndex;
  @override
  State<LouisianaScratchCatalogSheet> createState() =>
      _LouisianaScratchCatalogSheetState();
}

class _LouisianaScratchCatalogSheetState
    extends State<LouisianaScratchCatalogSheet> {
  late final _data = widget.catalogOverride != null
      ? Future.value(widget.catalogOverride!)
      : (widget.loader ?? LouisianaScratchCatalogLoader()).load();
  String _query = '';
  int? _price;
  String? _id;
  final _scroll = ScrollController();
  final _search = TextEditingController();
  @override
  void dispose() {
    _scroll.dispose();
    _search.dispose();
    super.dispose();
  }

  void _reset() {
    _id = null;
    if (_scroll.hasClients) {
      _scroll.jumpTo(0);
    }
  }

  Future<void> _open(String url) async {
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

  @override
  Widget build(BuildContext context) => SafeArea(
    child: SizedBox(
      height: MediaQuery.sizeOf(context).height * .9,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: FutureBuilder<Map<String, dynamic>>(
          future: _data,
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return Center(
                child: snapshot.hasError
                    ? const Text(
                        'Scratch inventory unavailable. Please try again later.',
                      )
                    : const CircularProgressIndicator(),
              );
            }
            final root = snapshot.data!,
                d = root['catalogs'][0] as Map,
                all = d['games'] as List;
            final prices = all.map((g) => g['cost'] as int).toSet().toList()
              ..sort();
            final games = all
                .where(
                  (g) =>
                      (_price == null || g['cost'] == _price) &&
                      '${g['id']} ${g['name']}'.toLowerCase().contains(_query),
                )
                .toList();
            final initial = all[widget.initialIndex]['id'];
            final selected = games.isEmpty
                ? null
                : games.firstWhere(
                    (g) =>
                        g['id'] ==
                        (_id ??
                            (_query.isEmpty && _price == null
                                ? initial
                                : null)),
                    orElse: () => games.first,
                  );
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Louisiana Scratch inventory',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close inventory',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final search = TextField(
                      controller: _search,
                      decoration: const InputDecoration(
                        labelText: 'Search game name or number',
                      ),
                      onChanged: (v) => setState(() {
                        _query = v.trim().toLowerCase();
                        _reset();
                      }),
                    );
                    final price = DropdownButton<int>(
                      isExpanded: true,
                      value: _price,
                      hint: const Text('All ticket prices'),
                      items: [
                        const DropdownMenuItem<int>(
                          value: null,
                          child: Text('All ticket prices'),
                        ),
                        for (final p in prices)
                          DropdownMenuItem(
                            value: p,
                            child: Text('Ticket price: \$$p'),
                          ),
                      ],
                      onChanged: (v) => setState(() {
                        _price = v;
                        _reset();
                      }),
                    );
                    if (constraints.maxWidth >= 560 &&
                        MediaQuery.textScalerOf(context).scale(14) <= 21) {
                      return Row(
                        children: [
                          Expanded(flex: 3, child: search),
                          const SizedBox(width: 16),
                          Expanded(flex: 2, child: price),
                        ],
                      );
                    }
                    return Column(children: [search, price]);
                  },
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        '${games.length} of ${all.length} listed games',
                      ),
                    ),
                    TextButton(
                      onPressed: () => setState(() {
                        _search.clear();
                        _query = '';
                        _price = null;
                        _reset();
                      }),
                      child: const Text('Reset filters'),
                    ),
                  ],
                ),
                if (selected != null)
                  DropdownButton<String>(
                    isExpanded: true,
                    value: selected['id'],
                    items: [
                      for (final g in games)
                        DropdownMenuItem(
                          value: g['id'] as String,
                          child: Text(
                            '#${g['id']} ${g['name']}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    onChanged: (v) => setState(() {
                      _reset();
                      _id = v;
                    }),
                  ),
                Expanded(
                  child: selected == null
                      ? const Center(child: Text('No matching games.'))
                      : ListView(
                          key: ValueKey(selected['id']),
                          controller: _scroll,
                          children: [
                            Text(
                              '#${selected['id']} ${selected['name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text('Ticket price: \$${selected['cost']}'),
                            Text('Start date: ${selected['startDate']}'),
                            Text(
                              'Game inventory timestamp: ${selected['sourceTimestamp']}',
                            ),
                            Text(selected['inventoryNote']),
                            const Text(
                              'Literal TICKET prizes are not converted into cash. Inventory is not store stock or dated winning-ticket activity.',
                            ),
                            for (final t in selected['prizeTiers'])
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      t['prizeLabel'],
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      'Total: ${t['total']} · Claimed: ${t['claimed']} · Remaining: ${t['remaining']}',
                                    ),
                                    Text(
                                      'Published odds: ${t['publishedOdds']}',
                                    ),
                                  ],
                                ),
                              ),
                            const Divider(),
                            Text(
                              'Candidate report timestamp: ${d['reportTimestamp']}',
                            ),
                            Text('Retrieved: ${root['updatedAt']}'),
                            Text(d['updateCadence']),
                            Text(d['coverage']),
                            TextButton.icon(
                              onPressed: () => _open(selected['sourceUrl']),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open official game detail'),
                            ),
                            TextButton(
                              onPressed: () => _open(d['source']),
                              child: const Text('Open official Scratch list'),
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
