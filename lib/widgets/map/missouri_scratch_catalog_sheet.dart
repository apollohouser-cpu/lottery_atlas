import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/missouri_scratch_catalog_loader.dart';

class MissouriScratchCatalogSheet extends StatefulWidget {
  const MissouriScratchCatalogSheet({
    super.key,
    this.catalogOverride,
    this.loader,
    this.initialIndex = 0,
  });
  final Map<String, dynamic>? catalogOverride;
  final MissouriScratchCatalogLoader? loader;
  final int initialIndex;
  @override
  State<MissouriScratchCatalogSheet> createState() =>
      _MissouriScratchCatalogSheetState();
}

class _MissouriScratchCatalogSheetState
    extends State<MissouriScratchCatalogSheet> {
  late final _data = widget.catalogOverride != null
      ? Future.value(widget.catalogOverride!)
      : (widget.loader ?? MissouriScratchCatalogLoader()).load();
  String _query = '';
  int? _price;
  String? _id;
  final _scroll = ScrollController();
  @override
  void dispose() {
    _scroll.dispose();
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
                        'Scratchers inventory unavailable. Please try again later.',
                      )
                    : const CircularProgressIndicator(),
              );
            }
            final d = snapshot.data!, all = d['games'] as List;
            final prices =
                all.map((g) => g['ticketPrice'] as int).toSet().toList()
                  ..sort();
            final games = all
                .where(
                  (g) =>
                      (_price == null || g['ticketPrice'] == _price) &&
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
                        'Missouri Scratchers inventory',
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
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Search game name or number',
                  ),
                  onChanged: (v) => setState(() {
                    _query = v.trim().toLowerCase();
                    _reset();
                  }),
                ),
                DropdownButton<int>(
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
                ),
                Text(
                  '${games.length} of ${all.length} listed games • Includes listed ended games',
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
                          controller: _scroll,
                          children: [
                            Text(
                              '#${selected['id']} ${selected['name']}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              'Ticket price: \$${selected['ticketPrice']} • Advertised top prize: ${selected['advertisedTopPrize']}',
                            ),
                            Text('Start date: ${selected['startDate']}'),
                            Text(
                              'Listed end date: ${selected['endDate'] ?? 'Not supplied (TBD)'}',
                            ),
                            const Text(
                              'Source verification date unavailable. Estimated unclaimed inventory is not store stock or dated claims. Advertised prizes are not verified immediate cash values.',
                            ),
                            const SizedBox(height: 12),
                            const Row(
                              children: [
                                Expanded(
                                  flex: 2,
                                  child: Text('Advertised prize'),
                                ),
                                Expanded(child: Text('Total prizes')),
                                Expanded(child: Text('Unclaimed prizes')),
                              ],
                            ),
                            for (final t in selected['prizeTiers'])
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8,
                                ),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      flex: 2,
                                      child: Text(t['prizeLabel']),
                                    ),
                                    Expanded(
                                      child: Text('${t['totalPrizes']}'),
                                    ),
                                    Expanded(
                                      child: Text('${t['unclaimedPrizes']}'),
                                    ),
                                  ],
                                ),
                              ),
                            const Divider(),
                            Text(selected['coverage']),
                            Text('Retrieved: ${d['updatedAt']}'),
                            Text(d['updateCadence']),
                            Text(d['coverage']),
                            TextButton.icon(
                              onPressed: () => _open(selected['sourceUrl']),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Open official game detail'),
                            ),
                            TextButton(
                              onPressed: () => _open(d['sourceUrl']),
                              child: const Text(
                                'Open official Scratchers list',
                              ),
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
