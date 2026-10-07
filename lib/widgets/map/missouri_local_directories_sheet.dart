import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../services/missouri_local_directories_loader.dart';

class MissouriLocalDirectoriesSheet extends StatefulWidget {
  const MissouriLocalDirectoriesSheet({super.key, this.dataOverride});
  final Map<String, dynamic>? dataOverride;
  @override
  State<MissouriLocalDirectoriesSheet> createState() =>
      _MissouriLocalDirectoriesSheetState();
}

class _MissouriLocalDirectoriesSheetState
    extends State<MissouriLocalDirectoriesSheet> {
  late final _data = widget.dataOverride != null
      ? Future.value(widget.dataOverride!)
      : MissouriLocalDirectoriesLoader.load();
  int _city = 0;
  String _search = '';
  String? _product;
  Future<void> _official() async {
    try {
      if (await launchUrl(
        Uri.parse('https://www.molottery.com/where-to-play/where-to-play.do'),
        mode: LaunchMode.externalApplication,
      )) {
        return;
      }
    } catch (_) {}
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the official locator.')),
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
                child: Text(
                  snapshot.hasError
                      ? 'Local directory unavailable.'
                      : 'Loading local directory…',
                ),
              );
            }
            final queries = snapshot.data!['queries'] as List,
                q = queries[_city],
                all = q['retailers'] as List;
            final rows = all
                .where(
                  (r) =>
                      (_product == null ||
                          (r['products'] as List).contains(_product)) &&
                      '${r['name']} ${r['address']} ${r['zip']}'
                          .toLowerCase()
                          .contains(_search),
                )
                .toList();
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Missouri local directories',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close directory',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const Text(
                  'Bundled results cover Jefferson City and Columbia only. For other Missouri cities or ZIP codes, use the official locator.',
                ),
                TextButton(
                  onPressed: _official,
                  child: const Text(
                    'Search anywhere in Missouri — official locator',
                  ),
                ),
                DropdownButton<int>(
                  isExpanded: true,
                  value: _city,
                  items: [
                    for (var i = 0; i < queries.length; i++)
                      DropdownMenuItem(
                        value: i,
                        child: Text(queries[i]['query']['city']),
                      ),
                  ],
                  onChanged: (v) => setState(() => _city = v!),
                ),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Filter name, address or ZIP',
                  ),
                  onChanged: (v) =>
                      setState(() => _search = v.trim().toLowerCase()),
                ),
                DropdownButton<String>(
                  isExpanded: true,
                  value: _product,
                  hint: const Text('All products'),
                  items: [
                    const DropdownMenuItem<String>(
                      value: null,
                      child: Text('All products'),
                    ),
                    for (final p in [
                      'Draw Games',
                      'Scratchers',
                      'Keno 2 Go',
                      'Club Keno',
                    ])
                      DropdownMenuItem(value: p, child: Text(p)),
                  ],
                  onChanged: (v) => setState(() => _product = v),
                ),
                Text('${rows.length} of ${all.length} local query records'),
                Expanded(
                  child: ListView(
                    children: [
                      Text('Retrieved: ${q['updatedAt']}'),
                      const Text(
                        'Coordinates unavailable: these records are not map pins or retailer wins. Product labels do not verify ticket stock. Agency, mobile and subscription entries may not be ordinary stores. Source verification date unavailable.',
                      ),
                      if (rows.isEmpty)
                        const Text('No matching local records.'),
                      for (final r in rows)
                        Card(
                          child: ListTile(
                            title: Text(r['name']),
                            subtitle: Text(
                              '${r['address']}\n${r['city']}, MO ${r['zip']}\n${(r['products'] as List).join(' • ')}',
                            ),
                          ),
                        ),
                      Text(q['coverage']),
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
