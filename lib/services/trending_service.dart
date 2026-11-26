import 'map_ranking_service.dart';

class TrendingEntry {
  TrendingEntry(this.entry);
  final MapRankingEntry entry;
  int appearances = 0;
  int rankTotal = 0;
  double get averageRank => rankTotal / appearances;
}

class TrendingResult {
  const TrendingResult(this.entries, this.windows, this.observedWindows);
  final List<TrendingEntry> entries;
  final int windows;
  final int observedWindows;
}

/// Compares disjoint calendar-day windows, never the user's interaction history.
class TrendingService {
  static TrendingResult calculate(
    MapRankingSnapshot source,
    MapRankingLevel level,
  ) {
    final start = source.dateRangeStart;
    final end = source.dateRangeEnd;
    if (end.isBefore(start)) return const TrendingResult([], 0, 0);
    // UTC calendar arithmetic avoids daylight-saving days changing window sizes.
    final firstDay = DateTime.utc(start.year, start.month, start.day);
    final days =
        DateTime.utc(end.year, end.month, end.day).difference(firstDay).inDays +
        1;
    final windows = days < 10 ? days : 10;
    final totals = <String, TrendingEntry>{};
    var observed = 0;
    for (var i = 0; i < windows; i++) {
      final a = firstDay.add(Duration(days: (i * days) ~/ windows));
      final b = firstDay.add(Duration(days: ((i + 1) * days) ~/ windows));
      DateTime calendar(DateTime d) => start.isUtc
          ? DateTime.utc(d.year, d.month, d.day)
          : DateTime(d.year, d.month, d.day);
      final window = MapRankingSnapshot(
        records: source.records,
        dateRangeStart: i == 0 ? start : calendar(a),
        dateRangeEnd: i == windows - 1
            ? end
            : calendar(b).subtract(const Duration(microseconds: 1)),
        countyIds: source.countyIds,
        rankingLevel: level,
        stateName: source.stateName,
        stateAbbreviation: source.stateAbbreviation,
        countyName: source.countyName,
        countyId: source.countyId,
        cityName: source.cityName,
        retailerName: source.retailerName,
        retailerAddress: source.retailerAddress,
      );
      final leaders = MapRankingService.rankings(
        window,
        qualifyLocations: true,
      );
      if (leaders.isNotEmpty) observed++;
      for (var rank = 0; rank < leaders.length; rank++) {
        final leader = leaders[rank];
        final trend = totals.putIfAbsent(
          leader.key,
          () => TrendingEntry(leader),
        );
        trend.appearances++;
        trend.rankTotal += rank + 1;
      }
    }
    final entries = totals.values.where((e) => e.appearances >= 2).toList()
      ..sort((a, b) {
        final frequency = b.appearances.compareTo(a.appearances);
        if (frequency != 0) return frequency;
        final rank = a.averageRank.compareTo(b.averageRank);
        if (rank != 0) return rank;
        return a.entry.key.compareTo(b.entry.key);
      });
    return TrendingResult(entries.take(5).toList(), windows, observed);
  }
}
