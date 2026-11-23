import 'connecticut_coverage_limits.dart';
import 'package:flutter/material.dart';
import 'connecticut_scratch_detail.dart';

class ConnecticutScratchCatalogSheet extends StatelessWidget {
  const ConnecticutScratchCatalogSheet({
    super.key,
    required this.catalog,
    this.openSource,
  });
  final Map<String, dynamic> catalog;
  final Future<bool> Function(Uri)? openSource;

  @override
  Widget build(BuildContext context) {
    final games = (catalog['games'] as List)
        .cast<Map<String, dynamic>>()
        .where((game) => game['id'].toString() != '1725')
        .toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connecticut Scratch'),
        actions: [
          IconButton(
            tooltip: 'Coverage and exclusions',
            icon: const Icon(Icons.info_outline),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute<void>(
                builder: (_) =>
                    ConnecticutCoverageLimits(openSource: openSource),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: games.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: Text(
                  '${catalog['coverage']}\n'
                  'Each detail retains its own inventory date. Remaining prizes are not store stock.\n'
                  'Game 1725 excluded because catalog cash value conflicts with detail rules.',
                ),
              );
            }
            final game = games[index - 1];
            return ListTile(
              title: Text('${game['name']} · ${game['id']}'),
              subtitle: Text(
                'Inventory: ${game['sourceDate']} · '
                '${game['status'] == 'ended' ? 'Sales ended' : 'Source status: ${game['status']}'}',
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute<void>(
                  builder: (_) => ConnecticutScratchDetail(
                    game: game,
                    openSource: openSource,
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
