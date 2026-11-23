import 'package:flutter/material.dart';
import '../../services/connecticut_coverage_loader.dart';
import 'connecticut_draw_collection_sheet.dart';
import 'connecticut_scratch_catalog_sheet.dart';

/// Integration boundary. Caller must provide an explicitly reviewed release.
class ConnecticutCoverageView extends StatefulWidget {
  const ConnecticutCoverageView({
    super.key,
    required this.loader,
    this.scratch = false,
    this.openSource,
  });
  final ConnecticutCoverageLoader loader;
  final bool scratch;
  final Future<bool> Function(Uri)? openSource;

  @override
  State<ConnecticutCoverageView> createState() =>
      _ConnecticutCoverageViewState();
}

class _ConnecticutCoverageViewState extends State<ConnecticutCoverageView> {
  late Future<ConnecticutCoverageLoad> loading = widget.loader.load();

  @override
  Widget build(BuildContext context) => FutureBuilder<ConnecticutCoverageLoad>(
    future: loading,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return Scaffold(
          appBar: AppBar(title: const Text('Connecticut coverage')),
          body: SafeArea(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const Text(
                  'Connecticut coverage is unavailable. No reviewed saved data was found.',
                ),
                TextButton(
                  onPressed: () => setState(() {
                    loading = widget.loader.load();
                  }),
                  child: const Text('Retry'),
                ),
                TextButton(
                  onPressed: () => Navigator.maybePop(context),
                  child: const Text('Close'),
                ),
              ],
            ),
          ),
        );
      }
      if (!snapshot.hasData) {
        return Scaffold(
          appBar: AppBar(title: const Text('Connecticut coverage')),
          body: const Center(child: CircularProgressIndicator()),
        );
      }
      final result = snapshot.data!;
      return Column(
        children: [
          if (result.refreshFailed || result.persistenceFailed)
            Material(
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    result.refreshFailed
                        ? 'Refresh unavailable. Showing reviewed saved observations with original source dates.'
                        : 'These observations could not be saved on this device.',
                  ),
                ),
              ),
            ),
          Expanded(
            child: widget.scratch
                ? ConnecticutScratchCatalogSheet(
                    catalog:
                        result.data['scratchCatalog'] as Map<String, dynamic>,
                    openSource: widget.openSource,
                  )
                : ConnecticutDrawCollectionSheet(
                    coverage: result.data,
                    openSource: widget.openSource,
                  ),
          ),
        ],
      );
    },
  );
}
