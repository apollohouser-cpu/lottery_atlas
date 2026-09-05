/// A concise readiness snapshot for one state's Lottery Atlas data.
///
/// Every future state uses the same profile, regardless of whether its
/// official lottery publishes a CSV, JSON API, PDF report, or web table.
enum StateLotteryDataReadiness {
  noStateLottery,
  notStarted,
  sourceLinked,
  mapDataReady,
}

extension StateLotteryDataReadinessDetails on StateLotteryDataReadiness {
  String get label {
    switch (this) {
      case StateLotteryDataReadiness.noStateLottery:
        return 'No state lottery';
      case StateLotteryDataReadiness.notStarted:
        return 'Not started';
      case StateLotteryDataReadiness.sourceLinked:
        return 'Official source linked';
      case StateLotteryDataReadiness.mapDataReady:
        return 'Map data ready';
    }
  }
}

class StateLotteryDataProfile {
  /// Lottery Atlas’ current verified-history target. Earlier records remain
  /// available when an official source publishes them, but state readiness and
  /// the map timeline use this common nationwide window.
  static const int verifiedHistoryStartYear = 2024;

  const StateLotteryDataProfile({
    required this.stateName,
    required this.abbreviation,
    required this.providerName,
    required this.officialSourceUrl,
    required this.activityRecordCount,
    required this.retailerRecordCount,
    required this.countyCount,
    required this.scratchCatalogGameCount,
    required this.hasVerifiedSchedule,
    required this.firstRecordAt,
    required this.latestRecordAt,
    required this.hasVerifiedRecordsEachYearSince2024,
    required this.isSampleMapData,
    required this.readiness,
  });

  final String stateName;
  final String abbreviation;
  final String? providerName;
  final String? officialSourceUrl;
  final int activityRecordCount;
  final int retailerRecordCount;
  final int countyCount;
  final int scratchCatalogGameCount;
  final bool hasVerifiedSchedule;
  final DateTime? firstRecordAt;
  final DateTime? latestRecordAt;
  final bool hasVerifiedRecordsEachYearSince2024;
  final bool isSampleMapData;
  final StateLotteryDataReadiness readiness;

  bool get hasOfficialSource => officialSourceUrl != null;
  bool get hasMapActivity => activityRecordCount > 0;
  bool get hasRetailerActivity => retailerRecordCount > 0;
  bool get hasScratchCatalog => scratchCatalogGameCount > 0;

  /// This measures continuity of the records currently loaded in the app.
  /// It deliberately does not claim that a state lottery's entire claim
  /// archive has been imported.
  String get historicalCoverageLabel {
    if (!hasMapActivity || firstRecordAt == null || latestRecordAt == null) {
      return 'Historical activity not yet published';
    }
    if (hasVerifiedRecordsEachYearSince2024) {
      return 'Live coverage: 2024–${latestRecordAt!.year}';
    }
    return 'Verified records span ${firstRecordAt!.year}–${latestRecordAt!.year}';
  }
}
