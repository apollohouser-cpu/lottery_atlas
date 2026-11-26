import 'package:flutter/material.dart';
import '../../services/map_ranking_service.dart';
import '../../services/trending_service.dart';

class TrendingScreen extends StatefulWidget {
  const TrendingScreen({super.key});
  @override
  State<TrendingScreen> createState() => _TrendingScreenState();
}

class _TrendingScreenState extends State<TrendingScreen> {
  MapRankingLevel _level = MapRankingService.snapshot.value.level;
  static const labels = {
    MapRankingLevel.state: 'States',
    MapRankingLevel.county: 'Counties',
    MapRankingLevel.city: 'Cities',
    MapRankingLevel.game: 'Games',
    MapRankingLevel.retailer: 'Retailers',
  };
  String date(DateTime d) => '${d.month}/${d.day}/${d.year}';

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF071827),
    appBar: AppBar(
      title: const Text('Trending'),
      backgroundColor: const Color(0xFF071827),
      foregroundColor: Colors.white,
    ),
    body: ValueListenableBuilder<MapRankingSnapshot>(
      valueListenable: MapRankingService.snapshot,
      builder: (context, source, _) {
        final result = TrendingService.calculate(source, _level);
        final scope = [
          source.stateName ?? 'United States',
          source.countyName,
          source.cityName,
          source.retailerName,
        ].whereType<String>().join(' • ');
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(
              scope,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${date(source.dateRangeStart)} – ${date(source.dateRangeEnd)}\nUsing your current map filters.',
              style: const TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: labels.entries
                  .map(
                    (e) => ChoiceChip(
                      label: Text(e.value),
                      selected: _level == e.key,
                      onSelected: (_) => setState(() => _level = e.key),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 20),
            const Text(
              'Consistently in the Top 5',
              style: TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Comparing ${result.windows} consecutive, non-overlapping windows of approximately equal calendar-day length. ${result.observedWindows} have matching published activity. Ranked by Top 5 appearances, then average position when present. At least two appearances are required.',
              style: const TextStyle(color: Colors.white70, height: 1.5),
            ),
            const SizedBox(height: 16),
            if (result.entries.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Not enough repeated Top 5 activity in this selection. Try a longer timeline or broader map filters.',
                  style: TextStyle(color: Colors.white, fontSize: 17),
                ),
              ),
            ...result.entries.asMap().entries.map((item) {
              final trend = item.value;
              final entry = trend.entry;
              return Card(
                color: const Color(0xFF102638),
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.key + 1}. ${entry.label}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 19,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Top 5 in ${trend.appearances} of ${result.windows} windows',
                        style: const TextStyle(
                          color: Color(0xFF60A5FA),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Average position when present: ${trend.averageRank.toStringAsFixed(1)}',
                        style: const TextStyle(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: 16),
            const Text(
              'Based on available published map activity, not complete claims coverage or future winning odds. Windows without matching records do not establish zero wins. Change the timeline or filters on the map to update this comparison.',
              style: TextStyle(color: Colors.white70, height: 1.5),
            ),
          ],
        );
      },
    ),
  );
}
