import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/state_model.dart';
import '../../models/lottery_activity.dart';
import '../../services/lottery_activity_repository.dart';
import '../../services/lottery_schedule_service.dart';
import '../../services/musl_draw_service.dart';
import '../../services/state_lottery_source_registry.dart';

class LotteryOverviewScreen extends StatefulWidget {
  const LotteryOverviewScreen({super.key, required this.state});

  final StateModel state;

  @override
  State<LotteryOverviewScreen> createState() => _LotteryOverviewScreenState();
}

class _LotteryOverviewScreenState extends State<LotteryOverviewScreen> {
  static const MethodChannel _magicMouseChannel = MethodChannel(
    'lottery_atlas/magic_mouse',
  );

  late final Timer _clockTimer;
  final MuslDrawService _musl = MuslDrawService();
  late Future<List<NationalDrawResult>> _stateNationalResults;

  @override
  void initState() {
    super.initState();
    _magicMouseChannel.invokeMethod<void>('setMapActive', false);
    LotteryScheduleService.initialize();
    _stateNationalResults = _loadStateNationalResults();
    _clockTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _clockTimer.cancel();
    _musl.dispose();
    _magicMouseChannel.invokeMethod<void>('setMapActive', true);
    super.dispose();
  }

  String _formatTime(DateTime time) {
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final second = time.second.toString().padLeft(2, '0');
    final period = time.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute:$second $period ${time.timeZoneName}';
  }

  String _formatDate(DateTime time) {
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    const months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    return '${weekdays[time.weekday - 1]}, ${months[time.month - 1]} ${time.day}';
  }

  String _countdown(DateTime drawingTime) {
    final remaining = drawingTime.difference(DateTime.now());
    if (remaining.isNegative) return 'Drawing now';

    if (remaining.inHours >= 24) {
      return '${remaining.inDays}d ${remaining.inHours.remainder(24)}h away';
    }

    return '${remaining.inHours}h '
        '${remaining.inMinutes.remainder(60).toString().padLeft(2, '0')}m away';
  }

  Future<void> _openOfficialSource() async {
    final source = StateLotterySourceRegistry.forState(widget.state.name);
    if (source == null || source.resources.isEmpty) return;

    final launched = await launchUrl(
      Uri.parse(source.resources.first.url),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the official lottery site.'),
        ),
      );
    }
  }

  Future<List<NationalDrawResult>> _loadStateNationalResults() {
    if (!_musl.isConfigured) return Future.value(<NationalDrawResult>[]);
    return Future.wait([
      _musl.latestCachedOrRefresh(
        'powerball',
        organizationCode: widget.state.abbreviation,
      ),
      _musl.latestCachedOrRefresh(
        'mega-millions',
        organizationCode: widget.state.abbreviation,
      ),
    ]);
  }

  void _refreshStateNationalResults() {
    setState(() => _stateNationalResults = _loadStateNationalResults());
  }

  @override
  Widget build(BuildContext context) {
    final localTime = LotteryScheduleService.currentTimeInState(
      widget.state.name,
    );
    final stateActivity =
        LotteryActivityRepository.activity
            .where((activity) => activity.state == widget.state.abbreviation)
            .toList()
          ..sort((a, b) => b.drawDate.compareTo(a.drawDate));
    final winningTickets = stateActivity.fold<int>(
      0,
      (total, activity) => total + activity.winningTickets,
    );
    final prizeTotal = stateActivity.fold<int>(
      0,
      (total, activity) => total + activity.prizeAmount,
    );
    final leadingCounty = _leadingCounty(stateActivity);
    final hasOfficialStateSchedule = widget.state.name == 'South Carolina';
    final officialSource = StateLotterySourceRegistry.forState(
      widget.state.name,
    );

    return Scaffold(
      backgroundColor: const Color(0xFF071827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071827),
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text('${widget.state.name} Lottery'),
        actions: [
          if (officialSource != null)
            IconButton(
              tooltip: 'Open official lottery source',
              onPressed: _openOfficialSource,
              icon: const Icon(Icons.open_in_new_rounded),
            ),
        ],
      ),
      body: SafeArea(
        top: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 36),
          children: [
            Text(
              widget.state.abbreviation,
              style: const TextStyle(
                color: Color(0xFF60A5FA),
                fontSize: 14,
                fontWeight: FontWeight.w800,
                letterSpacing: 2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Lottery Overview',
              style: TextStyle(
                color: Colors.white,
                fontSize: 30,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 18),
            _LocalTimeCard(
              dateLabel: _formatDate(localTime),
              timeLabel: _formatTime(localTime),
            ),
            const SizedBox(height: 24),
            Text(
              widget.state.name == 'South Carolina'
                  ? 'COUNTY ACTIVITY · SAMPLE DATA'
                  : 'STATE ACTIVITY',
              style: const TextStyle(
                color: Color(0xFF93C5FD),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            _StateActivityCard(
              stateActivity: stateActivity,
              winningTickets: winningTickets,
              prizeTotal: prizeTotal,
              leadingCounty: leadingCounty,
            ),
            const SizedBox(height: 8),
            Text(
              widget.state.name == 'South Carolina'
                  ? 'South Carolina drawing schedules are verified. County activity is not yet supplied by an official data feed.'
                  : 'Sample activity data — official lottery results will replace these records when sources are connected.',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 26),
            _buildOfficialNationalResults(),
            const SizedBox(height: 26),
            const Text(
              'NEXT NATIONAL DRAWINGS',
              style: TextStyle(
                color: Color(0xFF93C5FD),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            for (final schedule in LotteryScheduleService.nationalDraws) ...[
              _DrawingCard(
                schedule: schedule,
                drawingTime: LotteryScheduleService.nextDrawing(
                  schedule,
                  stateName: widget.state.name,
                ),
                formatDate: _formatDate,
                formatTime: _formatTime,
                countdown: _countdown,
              ),
              const SizedBox(height: 12),
            ],
            const SizedBox(height: 14),
            Text(
              hasOfficialStateSchedule
                  ? 'SOUTH CAROLINA DRAWINGS'
                  : 'STATE GAMES',
              style: const TextStyle(
                color: Color(0xFF93C5FD),
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.1,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              hasOfficialStateSchedule
                  ? 'Official South Carolina drawing schedule. Verify results and ticket details with the state lottery.'
                  : 'Sample local schedules — verify with the official state lottery before purchasing a ticket.',
              style: const TextStyle(color: Colors.white54, fontSize: 12),
            ),
            const SizedBox(height: 10),
            for (final schedule in LotteryScheduleService.stateDrawsFor(
              widget.state.name,
            )) ...[
              _StateDrawingCard(
                schedule: schedule,
                drawingTime: LotteryScheduleService.nextStateDrawing(
                  schedule,
                  stateName: widget.state.name,
                ),
                formatDate: _formatDate,
                formatTime: _formatTime,
                countdown: _countdown,
              ),
              const SizedBox(height: 12),
            ],
          ],
        ),
      ),
    );
  }

  String? _leadingCounty(List<LotteryActivity> activity) {
    if (activity.isEmpty) return null;
    final countyTotals = <String, int>{};
    for (final item in activity) {
      countyTotals.update(
        item.county,
        (total) => total + item.winningTickets,
        ifAbsent: () => item.winningTickets,
      );
    }
    return (countyTotals.entries.toList()
          ..sort((a, b) => b.value.compareTo(a.value)))
        .first
        .key;
  }

  Widget _buildOfficialNationalResults() {
    if (!_musl.isConfigured) {
      return const _OfficialNationalResultsNotice(
        message:
            'Connect your MUSL key to show official Powerball and Mega Millions state results here.',
      );
    }

    return FutureBuilder<List<NationalDrawResult>>(
      future: _stateNationalResults,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _OfficialNationalResultsNotice(
            message: 'Loading official national draw results for this state…',
            isLoading: true,
          );
        }
        if (snapshot.hasError) {
          return _OfficialNationalResultsNotice(
            message: 'Could not load official state winner totals right now.',
            onRetry: _refreshStateNationalResults,
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Expanded(
                  child: Text(
                    'OFFICIAL NATIONAL WINNERS',
                    style: TextStyle(
                      color: Color(0xFF86EFAC),
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.1,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Refresh official results',
                  onPressed: _refreshStateNationalResults,
                  icon: const Icon(
                    Icons.refresh_rounded,
                    color: Colors.white70,
                  ),
                ),
              ],
            ),
            const Text(
              'Latest MUSL winner-tier totals for this state. These are not county or retailer locations, and do not verify a ticket.',
              style: TextStyle(
                color: Colors.white54,
                fontSize: 12,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 10),
            for (final result in snapshot.data!) ...[
              _StateNationalWinnerCard(result: result),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _OfficialNationalResultsNotice extends StatelessWidget {
  const _OfficialNationalResultsNotice({
    required this.message,
    this.isLoading = false,
    this.onRetry,
  });

  final String message;
  final bool isLoading;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF102431),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF24475D)),
    ),
    child: Row(
      children: [
        if (isLoading)
          const SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Color(0xFF60A5FA),
            ),
          )
        else
          const Icon(Icons.cloud_outlined, color: Color(0xFF93C5FD)),
        const SizedBox(width: 12),
        Expanded(
          child: Text(message, style: const TextStyle(color: Colors.white60)),
        ),
        if (onRetry != null)
          IconButton(
            tooltip: 'Try again',
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded, color: Colors.white70),
          ),
      ],
    ),
  );
}

class _StateNationalWinnerCard extends StatelessWidget {
  const _StateNationalWinnerCard({required this.result});

  final NationalDrawResult result;

  @override
  Widget build(BuildContext context) {
    final winnerCount = result.reportedWinnerCount;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF102431),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF24475D)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0x1F2CC36B),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.emoji_events_outlined,
              color: Color(0xFF86EFAC),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  result.gameName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Completed draw: ${result.drawDate}',
                  style: const TextStyle(color: Colors.white54, fontSize: 12),
                ),
                const SizedBox(height: 7),
                Text(
                  winnerCount == null
                      ? 'Winner-tier total not supplied for this state.'
                      : '$winnerCount reported winner-tier ${winnerCount == 1 ? 'entry' : 'entries'}',
                  style: const TextStyle(
                    color: Color(0xFF86EFAC),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          if (result.isCached)
            const Icon(Icons.history_rounded, color: Colors.white38, size: 18),
        ],
      ),
    );
  }
}

class _StateActivityCard extends StatelessWidget {
  const _StateActivityCard({
    required this.stateActivity,
    required this.winningTickets,
    required this.prizeTotal,
    required this.leadingCounty,
  });

  final List<LotteryActivity> stateActivity;
  final int winningTickets;
  final int prizeTotal;
  final String? leadingCounty;

  String get _prizeLabel {
    if (prizeTotal >= 1000000) {
      return '\$${(prizeTotal / 1000000).toStringAsFixed(1)}M';
    }
    if (prizeTotal >= 1000) {
      return '\$${(prizeTotal / 1000).toStringAsFixed(0)}K';
    }
    return '\$$prizeTotal';
  }

  @override
  Widget build(BuildContext context) {
    if (stateActivity.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: const Color(0xFF102431),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF24475D)),
        ),
        child: const Row(
          children: [
            Icon(Icons.travel_explore_rounded, color: Color(0xFF60A5FA)),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No sample activity is listed for this state yet. Select counties on the map to continue exploring.',
                style: TextStyle(color: Colors.white70, height: 1.35),
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF102431),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF24475D)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _ActivityMetric(
                  label: 'WINNING TICKETS',
                  value: '$winningTickets',
                  icon: Icons.confirmation_number_rounded,
                ),
              ),
              Container(width: 1, height: 48, color: Colors.white12),
              Expanded(
                child: _ActivityMetric(
                  label: 'TOP PRIZE TOTAL',
                  value: _prizeLabel,
                  icon: Icons.workspace_premium_rounded,
                ),
              ),
            ],
          ),
          if (leadingCounty != null) ...[
            const Divider(height: 28, color: Colors.white12),
            Row(
              children: [
                const Icon(
                  Icons.location_city_rounded,
                  color: Color(0xFF2CC36B),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Leading county: $leadingCounty',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _ActivityMetric extends StatelessWidget {
  const _ActivityMetric({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: const Color(0xFF60A5FA), size: 19),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white54, fontSize: 9),
        ),
      ],
    );
  }
}

class _LocalTimeCard extends StatelessWidget {
  const _LocalTimeCard({required this.dateLabel, required this.timeLabel});

  final String dateLabel;
  final String timeLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF102431),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFF24475D)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 23,
            backgroundColor: Color(0xFF173B5A),
            child: Icon(Icons.schedule_rounded, color: Color(0xFF93C5FD)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'LOCAL LOTTERY TIME',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  timeLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(dateLabel, style: const TextStyle(color: Colors.white60)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DrawingCard extends StatelessWidget {
  const _DrawingCard({
    required this.schedule,
    required this.drawingTime,
    required this.formatDate,
    required this.formatTime,
    required this.countdown,
  });

  final LotteryDrawSchedule schedule;
  final DateTime drawingTime;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;
  final String Function(DateTime) countdown;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF102431),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 64,
            decoration: BoxDecoration(
              color: schedule.accentColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${formatDate(drawingTime)} · ${formatTime(drawingTime)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 5),
                Text(
                  countdown(drawingTime),
                  style: const TextStyle(
                    color: Color(0xFF93C5FD),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateDrawingCard extends StatelessWidget {
  const _StateDrawingCard({
    required this.schedule,
    required this.drawingTime,
    required this.formatDate,
    required this.formatTime,
    required this.countdown,
  });

  final StateLotteryDrawSchedule schedule;
  final DateTime drawingTime;
  final String Function(DateTime) formatDate;
  final String Function(DateTime) formatTime;
  final String Function(DateTime) countdown;

  @override
  Widget build(BuildContext context) {
    final cutoffTime = schedule.salesCutoffMinutes == null
        ? null
        : drawingTime.subtract(Duration(minutes: schedule.salesCutoffMinutes!));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF102431),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12),
      ),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 76,
            decoration: BoxDecoration(
              color: schedule.accentColor,
              borderRadius: BorderRadius.circular(99),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  schedule.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${formatDate(drawingTime)} · ${formatTime(drawingTime)}',
                  style: const TextStyle(color: Colors.white70, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  cutoffTime == null
                      ? countdown(drawingTime)
                      : 'Sales cutoff ${formatTime(cutoffTime)} · ${countdown(drawingTime)}',
                  style: const TextStyle(
                    color: Color(0xFF93C5FD),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
