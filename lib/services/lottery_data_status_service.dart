import 'package:shared_preferences/shared_preferences.dart';

import 'lottery_activity_repository.dart';
import 'musl_draw_service.dart';

/// Reports the sources currently powering Lottery Atlas.
///
/// The app deliberately identifies each source separately so live national
/// results, verified state schedules, and local sample map activity are never
/// presented as the same kind of data.
class LotteryDataStatusService {
  LotteryDataStatusService._();

  static const _lastCheckedKey = 'lottery_atlas.data_last_checked';
  static final SharedPreferencesAsync _store = SharedPreferencesAsync();

  static Future<LotteryDataStatus> _status({
    DateTime? lastChecked,
    bool checkNationalResults = false,
  }) async {
    final sources = await _sources(checkNationalResults: checkNationalResults);
    return LotteryDataStatus(
      isSampleData: LotteryActivityRepository.isSampleData,
      sourceLabel:
          'National results, verified state schedules, and ${LotteryActivityRepository.activitySourceLabel.toLowerCase()}',
      recordCount: LotteryActivityRepository.activity.length,
      lastChecked: lastChecked,
      sources: sources,
    );
  }

  static Future<List<LotteryDataSource>> _sources({
    required bool checkNationalResults,
  }) async {
    final musl = MuslDrawService();
    LotteryDataSource nationalSource;

    if (!musl.isConfigured) {
      nationalSource = const LotteryDataSource(
        label: 'National draw results',
        detail: 'MUSL API key is not configured for this build.',
        kind: LotteryDataSourceKind.setupRequired,
      );
    } else {
      try {
        final result = checkNationalResults
            ? await musl.latest('powerball')
            : await musl.cachedLatest('powerball');
        nationalSource = _nationalSourceFromResult(result);
      } catch (_) {
        nationalSource = const LotteryDataSource(
          label: 'National draw results',
          detail:
              'MUSL could not be reached. Check your connection, then refresh.',
          kind: LotteryDataSourceKind.unavailable,
        );
      } finally {
        musl.dispose();
      }
    }

    return [
      nationalSource,
      const LotteryDataSource(
        label: 'South Carolina draw schedule',
        detail: 'Official SC Education Lottery schedule and game links.',
        kind: LotteryDataSourceKind.official,
      ),
      LotteryDataSource(
        label: 'Map activity and county data',
        detail:
            '${LotteryActivityRepository.activitySourceLabel} • ${LotteryActivityRepository.activity.length} records • ${_activityUpdateLabel(LotteryActivityRepository.activityUpdatedAt)}.',
        kind: LotteryActivityRepository.isSampleData
            ? LotteryDataSourceKind.sample
            : LotteryActivityRepository.isCachedActivityData
            ? LotteryDataSourceKind.cached
            : LotteryDataSourceKind.live,
      ),
    ];
  }

  static LotteryDataSource _nationalSourceFromResult(
    NationalDrawResult? result,
  ) {
    if (result == null) {
      return const LotteryDataSource(
        label: 'National draw results',
        detail:
            'MUSL API key is ready. Open National Draw Results to load the first result.',
        kind: LotteryDataSourceKind.ready,
      );
    }

    final updated = result.lastUpdated;
    final timeLabel = updated == null ? '' : ' • saved ${_formatTime(updated)}';
    return LotteryDataSource(
      label: 'National draw results',
      detail: result.isCached
          ? 'MUSL result is available from this device cache$timeLabel.'
          : 'MUSL returned a live Powerball result$timeLabel.',
      kind: result.isCached
          ? LotteryDataSourceKind.cached
          : LotteryDataSourceKind.live,
    );
  }

  static String _formatTime(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final suffix = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $suffix';
  }

  static String _activityUpdateLabel(DateTime? updatedAt) {
    if (updatedAt == null) return 'no source date supplied';

    final local = updatedAt.toLocal();
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return 'source updated ${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  static Future<LotteryDataStatus> load() async {
    final timestamp = await _store.getString(_lastCheckedKey);
    return _status(
      lastChecked: timestamp == null ? null : DateTime.tryParse(timestamp),
    );
  }

  /// Performs a safe UI status refresh. It does not imply a county-data
  /// download occurred; those records remain clearly marked as samples.
  static Future<LotteryDataStatus> refresh() async {
    final checkedAt = DateTime.now();
    await _store.setString(_lastCheckedKey, checkedAt.toIso8601String());
    return _status(lastChecked: checkedAt, checkNationalResults: true);
  }
}

enum LotteryDataSourceKind {
  live,
  cached,
  ready,
  official,
  sample,
  setupRequired,
  unavailable,
}

class LotteryDataSource {
  const LotteryDataSource({
    required this.label,
    required this.detail,
    required this.kind,
  });

  final String label;
  final String detail;
  final LotteryDataSourceKind kind;
}

class LotteryDataStatus {
  const LotteryDataStatus({
    required this.isSampleData,
    required this.sourceLabel,
    required this.recordCount,
    required this.lastChecked,
    required this.sources,
  });

  final bool isSampleData;
  final String sourceLabel;
  final int recordCount;
  final DateTime? lastChecked;
  final List<LotteryDataSource> sources;

  bool get hasSampleSources =>
      sources.any((source) => source.kind == LotteryDataSourceKind.sample);
}
