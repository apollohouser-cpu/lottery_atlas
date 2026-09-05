import '../models/state_lottery_data_profile.dart';
import '../models/state_model.dart';
import 'lottery_activity_repository.dart';
import 'south_carolina_retailer_repository.dart';
import 'lottery_schedule_service.dart';
import 'state_scratch_catalog_registry.dart';
import 'state_lottery_source_registry.dart';
import 'state_retailer_directory_repository.dart';

/// One shared data-readiness layer for the nationwide map.
///
/// A state becomes map-ready once its official source is registered and its
/// normalized activity records are present in the common activity feed. This
/// keeps the expansion process consistent instead of creating a separate map
/// implementation for every lottery.
class StateLotteryDataRegistry {
  StateLotteryDataRegistry._();

  /// These jurisdictions do not operate a state lottery. They are explicit so
  /// the nationwide map never portrays a missing data adapter as pending
  /// lottery activity.
  static const Set<String> _statesWithoutLotteries = <String>{
    'Alabama',
    'Alaska',
    'Hawaii',
    'Nevada',
    'Utah',
  };

  static StateLotteryDataProfile forStateName(String stateName) {
    final state = allStates.firstWhere(
      (candidate) => candidate.name == stateName,
      orElse: () => StateModel(name: stateName, abbreviation: ''),
    );
    final source = StateLotterySourceRegistry.forState(stateName);
    final abbreviation = state.abbreviation.toUpperCase();
    final activity = LotteryActivityRepository.activity
        .where((record) => record.state == abbreviation)
        .toList(growable: false);
    // South Carolina has its dedicated official retailer feed. Every other
    // state can still report real retailer coverage when its verified map
    // activity names the selling location.
    final retailerCount = abbreviation == 'SC'
        ? SouthCarolinaRetailerRepository.retailers.length
        : StateRetailerDirectoryRepository.countFor(stateName) > 0
        ? StateRetailerDirectoryRepository.countFor(stateName)
        : activity.where((record) => record.retailerName != null).length;
    final dates = [
      ...activity.map((record) => record.drawDate),
      if (abbreviation == 'SC')
        ...SouthCarolinaRetailerRepository.retailers.map(
          (retailer) => retailer.claimDate,
        ),
    ];
    dates.sort();
    final activityYears = activity
        .map((record) => record.drawDate.year)
        .toSet();
    final currentYear = DateTime.now().year;
    final hasVerifiedRecordsEachYearSince2024 =
        !LotteryActivityRepository.isSampleData &&
        activityYears.isNotEmpty &&
        List<int>.generate(
          currentYear - StateLotteryDataProfile.verifiedHistoryStartYear + 1,
          (index) => StateLotteryDataProfile.verifiedHistoryStartYear + index,
        ).every(activityYears.contains);

    final readiness = _statesWithoutLotteries.contains(stateName)
        ? StateLotteryDataReadiness.noStateLottery
        : activity.isNotEmpty && !LotteryActivityRepository.isSampleData
        ? StateLotteryDataReadiness.mapDataReady
        : source != null
        ? StateLotteryDataReadiness.sourceLinked
        : StateLotteryDataReadiness.notStarted;

    return StateLotteryDataProfile(
      stateName: stateName,
      abbreviation: abbreviation,
      providerName: source?.providerName,
      officialSourceUrl: source == null || source.resources.isEmpty
          ? null
          : source.resources.first.url,
      activityRecordCount: activity.length,
      retailerRecordCount: retailerCount,
      countyCount: activity.map((record) => record.county).toSet().length,
      scratchCatalogGameCount: StateScratchCatalogRegistry.gamesFor(
        stateName,
      ).length,
      hasVerifiedSchedule: LotteryScheduleService.hasVerifiedStateDraws(
        stateName,
      ),
      firstRecordAt: dates.isEmpty ? null : dates.first,
      latestRecordAt: dates.isEmpty ? null : dates.last,
      hasVerifiedRecordsEachYearSince2024: hasVerifiedRecordsEachYearSince2024,
      isSampleMapData: LotteryActivityRepository.isSampleData,
      readiness: readiness,
    );
  }

  static List<StateLotteryDataProfile> allProfiles() => allStates
      .map((state) => forStateName(state.name))
      .toList(growable: false);
}
