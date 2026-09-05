import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../models/lottery_activity.dart';
import '../../services/lottery_activity_feed_service.dart';
import '../../services/lottery_activity_repository.dart';
import '../../services/south_carolina_lottery_map_filter_service.dart';
import '../../services/south_carolina_scratch_catalog.dart';
import '../../services/state_lottery_data_registry.dart';
import '../../models/state_lottery_data_profile.dart';

class SouthCarolinaDataCoverageScreen extends StatefulWidget {
  const SouthCarolinaDataCoverageScreen({super.key});

  @override
  State<SouthCarolinaDataCoverageScreen> createState() =>
      _SouthCarolinaDataCoverageScreenState();
}

class _SouthCarolinaDataCoverageScreenState
    extends State<SouthCarolinaDataCoverageScreen> {
  static const MethodChannel _magicMouseChannel = MethodChannel(
    'lottery_atlas/magic_mouse',
  );

  bool _isRefreshing = false;

  @override
  void initState() {
    super.initState();
    _magicMouseChannel.invokeMethod<void>('setMapActive', false);
    _loadCoverage();
  }

  @override
  void dispose() {
    _magicMouseChannel.invokeMethod<void>('setMapActive', true);
    super.dispose();
  }

  Future<void> _loadCoverage() async {
    setState(() => _isRefreshing = true);
    await LotteryActivityFeedService.loadConfiguredFeed();
    if (!mounted) return;
    setState(() => _isRefreshing = false);
  }

  List<_GameCoverage> _coverageFor(
    List<String> expectedGameNames, {
    required bool isScratchOff,
  }) {
    final southCarolinaRecords = LotteryActivityRepository.activity
        .where((activity) => activity.state == 'SC')
        .toList();
    return expectedGameNames.map((gameName) {
      final records =
          southCarolinaRecords
              .where((activity) => activity.gameName == gameName)
              .toList()
            ..sort(
              (first, second) => second.drawDate.compareTo(first.drawDate),
            );

      return _GameCoverage(
        gameName: gameName,
        isScratchOff: isScratchOff,
        records: records,
      );
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final drawCoverage = _coverageFor(
      SouthCarolinaLotteryMapFilter.drawGames
          .map((filter) => filter.gameName!)
          .toList(),
      isScratchOff: false,
    );
    final scratchCoverage = _coverageFor(
      SouthCarolinaScratchCatalog.games.map((game) => game.name).toList(),
      isScratchOff: true,
    );
    final allCoverage = [...drawCoverage, ...scratchCoverage];
    final publishedRecords = allCoverage.fold<int>(
      0,
      (total, coverage) => total + coverage.records.length,
    );
    final coveredGames = allCoverage
        .where((coverage) => coverage.hasRecords)
        .length;
    final updatedAt = LotteryActivityRepository.activityUpdatedAt;
    final southCarolinaRecords = LotteryActivityRepository.activity
        .where((activity) => activity.state == 'SC')
        .toList();
    final pipelineProfile = StateLotteryDataRegistry.forStateName(
      'South Carolina',
    );

    return Scaffold(
      backgroundColor: const Color(0xFF071827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071827),
        foregroundColor: Colors.white,
        title: const Text('South Carolina Data Coverage'),
        actions: [
          IconButton(
            tooltip: 'Check for updates',
            onPressed: _isRefreshing ? null : _loadCoverage,
            icon: _isRefreshing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
        children: [
          _summaryCard(
            coveredGames: coveredGames,
            allGames: allCoverage.length,
            publishedRecords: publishedRecords,
            countyCount: southCarolinaRecords
                .map((activity) => activity.county)
                .toSet()
                .length,
            updatedAt: updatedAt,
            sourceLastUpdated:
                LotteryActivityRepository.activitySourceLastUpdated,
            coverageNote: LotteryActivityRepository.activityCoverageNote,
          ),
          const SizedBox(height: 12),
          _pipelineCard(pipelineProfile),
          const SizedBox(height: 20),
          _sectionTitle('DRAW GAMES', 'All six South Carolina draw games'),
          const SizedBox(height: 8),
          ...drawCoverage.map(_coverageTile),
          const SizedBox(height: 20),
          _sectionTitle(
            'SCRATCH-OFFS',
            'Current catalog titles with qualifying map records',
          ),
          const SizedBox(height: 8),
          ...scratchCoverage.map(_coverageTile),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0x331478FF),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFF355066)),
            ),
            child: const Text(
              'A game without map records is not treated as zero lottery activity. It means the published South Carolina Winners Report currently has no qualifying claim record for that title. The app never invents missing activity.',
              style: TextStyle(color: Color(0xFFBFDBFE), height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryCard({
    required int coveredGames,
    required int allGames,
    required int publishedRecords,
    required int countyCount,
    required DateTime? updatedAt,
    required DateTime? sourceLastUpdated,
    required String? coverageNote,
  }) => Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: const Color(0xFF102638),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF1FAF77)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'PUBLISHED MAP COVERAGE',
          style: TextStyle(
            color: Color(0xFF86EFAC),
            fontSize: 12,
            letterSpacing: 1.1,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '$coveredGames of $allGames games have qualifying map records',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          '$publishedRecords South Carolina location records across $countyCount counties currently support the heat map.',
          style: const TextStyle(color: Colors.white70, height: 1.35),
        ),
        const SizedBox(height: 12),
        Text(
          updatedAt == null
              ? 'No published timestamp is available.'
              : 'App feed refreshed ${_formatDate(updatedAt)}',
          style: const TextStyle(
            color: Color(0xFF93C5FD),
            fontWeight: FontWeight.w700,
          ),
        ),
        if (sourceLastUpdated != null) ...[
          const SizedBox(height: 4),
          Text(
            'Official source report updated ${_formatDate(sourceLastUpdated)}',
            style: const TextStyle(color: Colors.white60),
          ),
        ],
        if (coverageNote != null) ...[
          const SizedBox(height: 12),
          Text(
            coverageNote,
            style: const TextStyle(color: Colors.white60, height: 1.35),
          ),
        ],
      ],
    ),
  );

  Widget _sectionTitle(String title, String subtitle) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Color(0xFF60A5FA),
          fontSize: 12,
          letterSpacing: 1.1,
          fontWeight: FontWeight.w800,
        ),
      ),
      const SizedBox(height: 3),
      Text(subtitle, style: const TextStyle(color: Colors.white60)),
    ],
  );

  Widget _pipelineCard(StateLotteryDataProfile profile) {
    final isReady = profile.readiness == StateLotteryDataReadiness.mapDataReady;
    final statusColor = isReady
        ? const Color(0xFF22C55E)
        : const Color(0xFF60A5FA);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D2233),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.65)),
      ),
      child: Row(
        children: [
          Icon(Icons.hub_rounded, color: statusColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STATE DATA PIPELINE · ${profile.readiness.label.toUpperCase()}',
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 12,
                    letterSpacing: 0.8,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${profile.activityRecordCount} map records · '
                  '${profile.retailerRecordCount} retailer records · '
                  '${profile.countyCount} counties',
                  style: const TextStyle(color: Colors.white70, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverageTile(_GameCoverage coverage) {
    final hasRecords = coverage.hasRecords;
    final statusColor = hasRecords
        ? const Color(0xFF22C55E)
        : const Color(0xFF64748B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFF102638),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: hasRecords
                ? const Color(0xFF1FAF77).withValues(alpha: 0.65)
                : const Color(0xFF355066),
          ),
        ),
        child: Row(
          children: [
            Icon(
              coverage.isScratchOff
                  ? Icons.confirmation_number_rounded
                  : Icons.casino_rounded,
              color: statusColor,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    coverage.gameName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    hasRecords
                        ? '${coverage.records.length} records · ${coverage.countyCount} counties · Latest ${_formatDate(coverage.latestRecord!.drawDate)}'
                        : 'No qualifying published map record yet',
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ),
            Icon(
              hasRecords ? Icons.verified_rounded : Icons.schedule_rounded,
              color: statusColor,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
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
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }
}

class _GameCoverage {
  const _GameCoverage({
    required this.gameName,
    required this.isScratchOff,
    required this.records,
  });

  final String gameName;
  final bool isScratchOff;
  final List<LotteryActivity> records;

  bool get hasRecords => records.isNotEmpty;

  int get countyCount => records.map((record) => record.county).toSet().length;

  LotteryActivity? get latestRecord => records.isEmpty ? null : records.first;
}
