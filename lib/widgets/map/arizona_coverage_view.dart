import 'package:flutter/material.dart';
import '../../services/arizona_coverage_loader.dart';
import 'arizona_draw_collection_sheet.dart';
import 'arizona_product_sheet.dart';

/// Integration boundary; no production endpoint or map entry is enabled yet.
class ArizonaCoverageView extends StatefulWidget {
  const ArizonaCoverageView({
    super.key,
    required this.loader,
    this.products = false,
  });
  final ArizonaCoverageLoader loader;
  final bool products;
  @override
  State<ArizonaCoverageView> createState() => _ArizonaCoverageViewState();
}

class _ArizonaCoverageViewState extends State<ArizonaCoverageView> {
  late Future<ArizonaCoverageLoad> loading = widget.loader.load();
  @override
  Widget build(BuildContext context) => FutureBuilder<ArizonaCoverageLoad>(
    future: loading,
    builder: (context, snapshot) {
      if (snapshot.hasError) {
        return SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'Arizona coverage is unavailable. No validated saved data was found.',
              ),
              TextButton(
                onPressed: () => setState(() => loading = widget.loader.load()),
                child: const Text('Retry'),
              ),
              TextButton(
                onPressed: () => Navigator.maybePop(context),
                child: const Text('Close'),
              ),
            ],
          ),
        );
      }
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }
      final result = snapshot.data!;
      return Column(
        children: [
          if (result.refreshFailed)
            const SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'Refresh unavailable. Showing validated saved observations with their original source dates.',
                ),
              ),
            ),
          if (result.persistenceFailed)
            const SafeArea(
              bottom: false,
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Text(
                  'These observations could not be saved on this device.',
                ),
              ),
            ),
          Expanded(
            child: widget.products
                ? ArizonaProductSheet(coverage: result.data)
                : ArizonaDrawCollectionSheet(coverage: result.data),
          ),
        ],
      );
    },
  );
}
