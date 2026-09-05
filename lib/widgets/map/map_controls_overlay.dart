import 'dart:async';

import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';

import '../../models/state_model.dart';
import '../../services/lottery_activity_repository.dart';
import 'horizontal_heat_legend.dart';
import 'map_detail_mode.dart';
import 'map_filter_state.dart';
import 'map_search_result.dart';

enum TimelineGranularity { day, week, month, year }

enum TimelinePlaybackSpeed { slow, normal, fast }

extension on TimelineGranularity {
  String get label {
    switch (this) {
      case TimelineGranularity.day:
        return 'Day';
      case TimelineGranularity.week:
        return 'Week';
      case TimelineGranularity.month:
        return 'Month';
      case TimelineGranularity.year:
        return 'Year';
    }
  }
}

extension on TimelinePlaybackSpeed {
  String get label {
    switch (this) {
      case TimelinePlaybackSpeed.slow:
        return 'Slow';
      case TimelinePlaybackSpeed.normal:
        return 'Normal';
      case TimelinePlaybackSpeed.fast:
        return 'Fast';
    }
  }

  String get compactLabel {
    switch (this) {
      case TimelinePlaybackSpeed.slow:
        return '0.7×';
      case TimelinePlaybackSpeed.normal:
        return '1×';
      case TimelinePlaybackSpeed.fast:
        return '1.7×';
    }
  }

  int get fullRangeMilliseconds {
    switch (this) {
      case TimelinePlaybackSpeed.slow:
        return 18000;
      case TimelinePlaybackSpeed.normal:
        return 12000;
      case TimelinePlaybackSpeed.fast:
        return 7000;
    }
  }
}

class MapControlsOverlay extends StatefulWidget {
  const MapControlsOverlay({
    super.key,
    this.detailMode = MapDetailMode.standard,
    this.onDetailModeChanged,
    this.filterState,
    this.onFilterChanged,
    this.showTimeZones = false,
    this.onTimeZoneVisibilityChanged,
    this.onSearchSelected,
    this.onSearchVisibilityChanged,
    this.onStateSelected,
    this.onActivityRefresh,
    this.showHeaderControls = true,
  });

  final MapDetailMode detailMode;
  final ValueChanged<MapDetailMode>? onDetailModeChanged;
  final MapFilterState? filterState;
  final ValueChanged<MapFilterState>? onFilterChanged;
  final bool showTimeZones;
  final ValueChanged<bool>? onTimeZoneVisibilityChanged;
  final ValueChanged<MapSearchResult>? onSearchSelected;
  final ValueChanged<bool>? onSearchVisibilityChanged;
  final ValueChanged<String>? onStateSelected;
  final Future<void> Function()? onActivityRefresh;
  // State and county views keep the timeline, while their dedicated panel
  // replaces the national header controls.
  final bool showHeaderControls;

  @override
  State<MapControlsOverlay> createState() => _MapControlsOverlayState();
}

class _MapControlsOverlayState extends State<MapControlsOverlay> {
  static final DateTime _firstAvailableDate = DateTime(2015, 1, 1);

  late MapFilterState _filterState;
  // The map opens in a practical "right now" view. Historical scales remain
  // one tap away when the user wants to explore older activity.
  TimelineGranularity _timelineGranularity = TimelineGranularity.day;
  late DateTime _timelineAnchor;
  Timer? _timelinePlaybackTimer;
  Timer? _timelineLoopPauseTimer;
  bool _isTimelinePlaying = false;
  bool _isTimelineLooping = false;
  TimelinePlaybackSpeed _timelinePlaybackSpeed = TimelinePlaybackSpeed.normal;

  @override
  void initState() {
    super.initState();
    _filterState = widget.filterState ?? MapFilterState.initial();
    _timelineAnchor = widget.filterState?.dateRange.end ?? DateTime.now();
  }

  @override
  void didUpdateWidget(covariant MapControlsOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.filterState != null &&
        widget.filterState != oldWidget.filterState) {
      _filterState = widget.filterState!;
    }
  }

  @override
  void dispose() {
    _timelinePlaybackTimer?.cancel();
    _timelineLoopPauseTimer?.cancel();
    super.dispose();
  }

  void _updateFilter(MapFilterState filterState) {
    setState(() => _filterState = filterState);
    widget.onFilterChanged?.call(filterState);
  }

  Future<void> _selectGame() async {
    var selectedGame = _filterState.game;
    var selectedActivityScope = _filterState.activityScope;
    final highestPublishedPrize = LotteryActivityRepository.activity.fold<int>(
      1,
      (highest, activity) =>
          activity.prizeAmount > highest ? activity.prizeAmount : highest,
    );
    var selectedPrizeRange = RangeValues(
      _filterState.minimumPrize.clamp(1, highestPublishedPrize).toDouble(),
      (_filterState.maximumPrize ?? highestPublishedPrize)
          .clamp(1, highestPublishedPrize)
          .toDouble(),
    );

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B1D2C),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Game filter',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  ...LotteryGame.values.map((game) {
                    final isSelected = game == selectedGame;
                    return ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      tileColor: isSelected
                          ? const Color(0x331478FF)
                          : Colors.transparent,
                      leading: Icon(
                        game.icon,
                        color: isSelected
                            ? const Color(0xFF1478FF)
                            : Colors.white70,
                      ),
                      title: Text(
                        game.label,
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: isSelected
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle_rounded,
                              color: Color(0xFF1478FF),
                            )
                          : null,
                      onTap: () => setSheetState(() => selectedGame = game),
                    );
                  }),
                  const Divider(color: Colors.white12, height: 28),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'National Map Coverage',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  ...MapActivityScope.values.map(
                    (scope) => RadioListTile<MapActivityScope>(
                      contentPadding: EdgeInsets.zero,
                      value: scope,
                      groupValue: selectedActivityScope,
                      activeColor: const Color(0xFF1478FF),
                      title: Text(
                        scope.label,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        scope.description,
                        style: const TextStyle(color: Colors.white60),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selectedActivityScope = value);
                        }
                      },
                    ),
                  ),
                  const Divider(color: Colors.white12, height: 28),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Prize Amount',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${_formatPrize(selectedPrizeRange.start.round())} – '
                    '${_formatPrize(selectedPrizeRange.end.round())}',
                    style: const TextStyle(
                      color: Color(0xFF60A5FA),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  RangeSlider(
                    values: selectedPrizeRange,
                    min: 1,
                    max: highestPublishedPrize.toDouble(),
                    activeColor: const Color(0xFF1478FF),
                    inactiveColor: Colors.white24,
                    labels: RangeLabels(
                      _formatPrize(selectedPrizeRange.start.round()),
                      _formatPrize(selectedPrizeRange.end.round()),
                    ),
                    onChanged: highestPublishedPrize <= 1
                        ? null
                        : (value) =>
                              setSheetState(() => selectedPrizeRange = value),
                  ),
                  const Text(
                    'Choose the winning-prize range to show on the heat map.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        _updateFilter(
                          _filterState.copyWith(
                            game: selectedGame,
                            activityScope: selectedActivityScope,
                            minimumPrize: selectedPrizeRange.start.round(),
                            maximumPrize:
                                selectedPrizeRange.end.round() >=
                                    highestPublishedPrize
                                ? null
                                : selectedPrizeRange.end.round(),
                            replaceMaximumPrize: true,
                          ),
                        );
                        Navigator.of(sheetContext).pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1478FF),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Apply Game Filter'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showActivitySourceSheet() {
    var isRefreshing = false;
    String? refreshMessage;

    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B1D2C),
      showDragHandle: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (sheetContext, setSheetState) {
          final isSampleData = LotteryActivityRepository.isSampleData;
          final isCached = LotteryActivityRepository.isCachedActivityData;
          final sourceLabel = LotteryActivityRepository.activitySourceLabel;
          final activityCount = LotteryActivityRepository.activity.length;
          final updatedAt = LotteryActivityRepository.activityUpdatedAt;
          final isStale = _isActivityStale(updatedAt, isSampleData);
          final freshnessColor = _freshnessColor(
            isSampleData: isSampleData,
            isCached: isCached,
            isStale: isStale,
          );

          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.dataset_linked_rounded,
                        color: Color(0xFF60A5FA),
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Map activity source',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: freshnessColor.withValues(alpha: 0.13),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: freshnessColor.withValues(alpha: 0.60),
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _freshnessIcon(
                            isSampleData: isSampleData,
                            isCached: isCached,
                            isStale: isStale,
                          ),
                          color: freshnessColor,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _freshnessTitle(
                                  isSampleData: isSampleData,
                                  isCached: isCached,
                                  isStale: isStale,
                                ),
                                style: TextStyle(
                                  color: freshnessColor,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _freshnessDescription(updatedAt),
                                style: const TextStyle(
                                  color: Colors.white70,
                                  fontSize: 12,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    isSampleData
                        ? 'The current heat index and county activity markers are local sample data. They demonstrate the map experience, filters, and timeline, but are not official winning-ticket records.'
                        : 'The current heat index and county activity markers are loaded from: $sourceLabel. This feed contains $activityCount published location records${updatedAt == null ? '' : ', last updated ${_formatActivityDate(updatedAt)}'}. Always verify a ticket with the applicable official lottery.',
                    style: const TextStyle(color: Colors.white70, height: 1.4),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'South Carolina activity and retailer feeds are checked at app launch and every six hours while the app is open. The last valid published data remains available offline. National Powerball and Mega Millions results are supplied separately through MUSL.',
                    style: TextStyle(color: Colors.white54, height: 1.4),
                  ),
                  if (refreshMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      refreshMessage!,
                      style: const TextStyle(
                        color: Color(0xFF93C5FD),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  if (widget.onActivityRefresh != null) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: isRefreshing
                            ? null
                            : () async {
                                setSheetState(() {
                                  isRefreshing = true;
                                  refreshMessage = null;
                                });
                                try {
                                  await widget.onActivityRefresh!.call();
                                  if (!sheetContext.mounted) return;
                                  setSheetState(() {
                                    refreshMessage = 'Last checked just now.';
                                  });
                                } finally {
                                  if (sheetContext.mounted) {
                                    setSheetState(() => isRefreshing = false);
                                  }
                                }
                              },
                        icon: isRefreshing
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded),
                        label: Text(
                          isRefreshing
                              ? 'Checking for updates…'
                              : 'Check for updates',
                        ),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF1478FF),
                          foregroundColor: Colors.white,
                          minimumSize: const Size.fromHeight(46),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                  ],
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(sheetContext).pop(),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Color(0xFF355066)),
                        minimumSize: const Size.fromHeight(46),
                      ),
                      child: const Text('Done'),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  bool _isActivityStale(DateTime? updatedAt, bool isSampleData) {
    if (isSampleData || updatedAt == null) return false;
    return DateTime.now().difference(updatedAt.toLocal()) >
        const Duration(hours: 48);
  }

  Color _freshnessColor({
    required bool isSampleData,
    required bool isCached,
    required bool isStale,
  }) {
    if (isSampleData) return const Color(0xFFFFC107);
    if (isStale) return const Color(0xFFF59E0B);
    if (isCached) return const Color(0xFF60A5FA);
    return const Color(0xFF22C55E);
  }

  IconData _freshnessIcon({
    required bool isSampleData,
    required bool isCached,
    required bool isStale,
  }) {
    if (isSampleData) return Icons.science_outlined;
    if (isStale) return Icons.warning_amber_rounded;
    if (isCached) return Icons.cloud_done_outlined;
    return Icons.verified_rounded;
  }

  String _freshnessTitle({
    required bool isSampleData,
    required bool isCached,
    required bool isStale,
  }) {
    if (isSampleData) return 'Sample map data';
    if (isStale) return 'Published data may be out of date';
    if (isCached) return 'Saved offline copy';
    return 'Published data is current';
  }

  String _freshnessDescription(DateTime? updatedAt) {
    if (updatedAt == null) return 'No published timestamp is available.';
    final age = DateTime.now().difference(updatedAt.toLocal());
    if (age.inMinutes < 1) return 'Published less than a minute ago.';
    if (age.inHours < 1) return 'Published ${age.inMinutes} minutes ago.';
    if (age.inHours < 48) return 'Published ${age.inHours} hours ago.';
    return 'Published ${age.inDays} days ago.';
  }

  String _formatActivityDate(DateTime dateTime) {
    final local = dateTime.toLocal();
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
    return '${months[local.month - 1]} ${local.day}, ${local.year}';
  }

  Future<void> _openSearch() async {
    widget.onSearchVisibilityChanged?.call(true);
    final result = await showSearch<MapSearchResult?>(
      context: context,
      delegate: _MapLocationSearchDelegate(),
    );
    widget.onSearchVisibilityChanged?.call(false);
    if (result != null) {
      widget.onSearchSelected?.call(result);
    }
  }

  Future<void> _selectDateRange() async {
    _stopTimelinePlayback();
    final selectedDate = await showDatePicker(
      context: context,
      firstDate: _firstAvailableDate,
      lastDate: DateTime.now(),
      initialDate: _timelineAnchor,
      helpText: 'CHOOSE TIMELINE DATE',
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: Color(0xFF1478FF),
            onPrimary: Colors.white,
            surface: Color(0xFF0B1D2C),
            onSurface: Colors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (!mounted || selectedDate == null) return;
    setState(() {
      _timelineAnchor = DateTime(
        selectedDate.year,
        selectedDate.month,
        selectedDate.day,
        _timelineAnchor.hour,
      );
    });
    _setTimelineValue(_initialTimelineValue());
  }

  void _returnTimelineToNow() {
    _stopTimelinePlayback();
    final now = DateTime.now();
    setState(() => _timelineAnchor = now);
    _setTimelineValue(_initialTimelineValue());
  }

  Future<void> _openFilters() async {
    var winnersOnly = _filterState.showWinnersOnly;
    var favoritesOnly = _filterState.showFavoritesOnly;
    var timeZonesVisible = widget.showTimeZones;
    var selectedDetailMode = widget.detailMode;

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B1D2C),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) => SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                  const SizedBox(height: 18),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Map Filters',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  _switchTile(
                    title: 'Winning locations only',
                    subtitle:
                        'Show only locations with winning-ticket activity.',
                    value: winnersOnly,
                    onChanged: (value) =>
                        setSheetState(() => winnersOnly = value),
                  ),
                  _switchTile(
                    title: 'Favorites only',
                    subtitle: 'Show only saved lottery locations.',
                    value: favoritesOnly,
                    onChanged: (value) =>
                        setSheetState(() => favoritesOnly = value),
                  ),
                  const Divider(color: Colors.white12, height: 28),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Map Layers',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  _switchTile(
                    title: 'Time-zone lines and clocks',
                    subtitle:
                        'Show live Pacific, Mountain, Central, and Eastern time on the map.',
                    value: timeZonesVisible,
                    onChanged: (value) =>
                        setSheetState(() => timeZonesVisible = value),
                  ),
                  const Divider(color: Colors.white12, height: 28),
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Map Detail',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  ...MapDetailMode.values.map(
                    (mode) => RadioListTile<MapDetailMode>(
                      contentPadding: EdgeInsets.zero,
                      value: mode,
                      groupValue: selectedDetailMode,
                      activeColor: const Color(0xFF1478FF),
                      title: Text(
                        mode.label,
                        style: const TextStyle(color: Colors.white),
                      ),
                      subtitle: Text(
                        mode.description,
                        style: const TextStyle(color: Colors.white60),
                      ),
                      onChanged: (value) {
                        if (value != null) {
                          setSheetState(() => selectedDetailMode = value);
                        }
                      },
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () {
                        _updateFilter(
                          _filterState.copyWith(
                            showWinnersOnly: winnersOnly,
                            showFavoritesOnly: favoritesOnly,
                          ),
                        );
                        widget.onDetailModeChanged?.call(selectedDetailMode);
                        widget.onTimeZoneVisibilityChanged?.call(
                          timeZonesVisible,
                        );
                        Navigator.of(sheetContext).pop();
                      },
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF1478FF),
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: const Text('Apply Filters'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStatePicker() async {
    var stateSearchTerm = '';

    widget.onSearchVisibilityChanged?.call(true);
    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF0B1D2C),
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setSheetState) => SafeArea(
            child: SizedBox(
              height: (MediaQuery.sizeOf(context).height * 0.72)
                  .clamp(420.0, 640.0)
                  .toDouble(),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
                child: Column(
                  children: [
                    Container(
                      width: 42,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(99),
                      ),
                    ),
                    const SizedBox(height: 18),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Find a State',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Type a name or browse the list to open a state map.',
                        style: TextStyle(color: Colors.white60, fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      autofocus: true,
                      onChanged: (value) =>
                          setSheetState(() => stateSearchTerm = value),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: 'Search states',
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF93C5FD),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.06),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(color: Colors.white24),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF60A5FA),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: _statePickerList(stateSearchTerm, sheetContext),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    } finally {
      widget.onSearchVisibilityChanged?.call(false);
    }
  }

  Widget _statePickerList(String query, BuildContext sheetContext) {
    final normalizedQuery = query.trim().toLowerCase();
    final states =
        allStates
            .where(
              (state) =>
                  normalizedQuery.isEmpty ||
                  state.name.toLowerCase().contains(normalizedQuery) ||
                  state.abbreviation.toLowerCase().contains(normalizedQuery),
            )
            .toList()
          ..sort((left, right) => left.name.compareTo(right.name));

    if (states.isEmpty) {
      return const Center(
        child: Text(
          'No state matches that search.',
          style: TextStyle(color: Colors.white60),
        ),
      );
    }

    return Scrollbar(
      child: ListView.separated(
        primary: false,
        padding: EdgeInsets.zero,
        itemCount: states.length,
        separatorBuilder: (_, _) => const Divider(color: Colors.white12),
        itemBuilder: (context, index) {
          final state = states[index];
          return ListTile(
            dense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 6),
            leading: CircleAvatar(
              radius: 15,
              backgroundColor: const Color(0x221478FF),
              child: Text(
                state.abbreviation,
                style: const TextStyle(
                  color: Color(0xFF93C5FD),
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            title: Text(
              state.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            trailing: const Icon(
              Icons.north_east_rounded,
              color: Colors.white54,
              size: 18,
            ),
            onTap: () {
              Navigator.of(sheetContext).pop();
              widget.onStateSelected?.call(state.name);
            },
          );
        },
      ),
    );
  }

  Widget _switchTile({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) => SwitchListTile(
    contentPadding: EdgeInsets.zero,
    title: Text(title, style: const TextStyle(color: Colors.white)),
    subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60)),
    value: value,
    activeTrackColor: const Color(0xFF1478FF),
    onChanged: onChanged,
  );

  String _formatPrize(int amount) {
    if (amount >= 1000000) {
      final millions = amount / 1000000;
      return millions == millions.roundToDouble()
          ? '\$${millions.toStringAsFixed(0)}M'
          : '\$${millions.toStringAsFixed(1)}M';
    }
    if (amount >= 1000) return '\$${(amount / 1000).round()}K';
    return '\$$amount';
  }

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      if (widget.showHeaderControls)
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Column(
            children: [
              _brandHeader(),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(child: _gameButton()),
                  const SizedBox(width: 12),
                  Expanded(child: _filterButton()),
                ],
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) => Align(
                  alignment: Alignment.centerRight,
                  child: SizedBox(
                    width: (constraints.maxWidth - 12) / 2,
                    child: _stateFinderButton(),
                  ),
                ),
              ),
            ],
          ),
        ),
      Positioned(left: 20, right: 20, bottom: 16, child: _timelineDock()),
    ],
  );

  Widget _brandHeader() => Row(
    children: [
      Container(
        width: 42,
        height: 50,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1478FF), Color(0xFF073A8A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: const Icon(Icons.explore_rounded, color: Colors.white, size: 27),
      ),
      const SizedBox(width: 10),
      const Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'LOTTERY ATLAS',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                letterSpacing: 1.2,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(
              'EXPLORE.  ANALYZE.  WIN.',
              style: TextStyle(
                color: Colors.white70,
                fontSize: 10,
                letterSpacing: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
      IconButton(
        tooltip: 'Search',
        onPressed: _openSearch,
        icon: const Icon(Icons.search_rounded, color: Colors.white),
      ),
      IconButton(
        tooltip: 'Menu',
        onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Main menu is coming soon.')),
        ),
        icon: const Icon(Icons.menu_rounded, color: Colors.white),
      ),
    ],
  );

  Widget _gameButton() => _controlButton(
    icon: _filterState.game.icon,
    label: 'Game Filter · ${_filterState.game.label}',
    onPressed: _selectGame,
  );

  Widget _filterButton() {
    final activeFilterCount =
        (_filterState.showWinnersOnly ? 1 : 0) +
        (_filterState.showFavoritesOnly ? 1 : 0) +
        (widget.showTimeZones ? 1 : 0) +
        (_filterState.activityScope == MapActivityScope.allLotteries ? 1 : 0) +
        (_filterState.minimumPrize > 1 || _filterState.maximumPrize != null
            ? 1
            : 0);
    return _controlButton(
      icon: Icons.tune_rounded,
      label: activeFilterCount == 0
          ? 'Filters'
          : 'Filters ($activeFilterCount)',
      showActiveDot: activeFilterCount > 0,
      onPressed: _openFilters,
    );
  }

  Widget _stateFinderButton() => _controlButton(
    icon: Icons.map_outlined,
    label: 'Find a State',
    onPressed: _openStatePicker,
    height: 48,
  );

  Widget _controlButton({
    required IconData icon,
    required String label,
    required VoidCallback onPressed,
    bool showActiveDot = false,
    double height = 58,
  }) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onPressed,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: height,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xE6091826),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF4A6074)),
          boxShadow: const [
            BoxShadow(
              color: Color(0x55000000),
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 25),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            if (showActiveDot)
              const Padding(
                padding: EdgeInsets.only(left: 8),
                child: CircleAvatar(
                  radius: 4,
                  backgroundColor: Color(0xFF1478FF),
                ),
              ),
            const SizedBox(width: 4),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              color: Colors.white70,
            ),
          ],
        ),
      ),
    ),
  );

  void _setGranularity(TimelineGranularity granularity) {
    _stopTimelinePlayback();
    setState(() => _timelineGranularity = granularity);
    _setTimelineValue(_initialTimelineValue());
  }

  Duration _timelinePlaybackStepDuration() {
    // Normal playback takes twelve seconds. Slow and Fast keep the same
    // smooth stepping while giving people a more comfortable viewing pace.
    final stepCount = _maximumPlayableTimelineValue() + 1;
    return Duration(
      milliseconds: (_timelinePlaybackSpeed.fullRangeMilliseconds / stepCount)
          .round(),
    );
  }

  int _maximumPlayableTimelineValue() {
    final now = DateTime.now();
    final isCurrentDay =
        _timelineAnchor.year == now.year &&
        _timelineAnchor.month == now.month &&
        _timelineAnchor.day == now.day;

    switch (_timelineGranularity) {
      case TimelineGranularity.day:
        return isCurrentDay ? now.hour : 23;
      case TimelineGranularity.week:
        final weekStart = _timelineAnchor.subtract(
          Duration(days: _timelineAnchor.weekday - 1),
        );
        final currentWeekStart = now.subtract(Duration(days: now.weekday - 1));
        return DateUtils.isSameDay(weekStart, currentWeekStart)
            ? now.weekday - 1
            : 6;
      case TimelineGranularity.month:
        final isCurrentMonth =
            _timelineAnchor.year == now.year &&
            _timelineAnchor.month == now.month;
        return isCurrentMonth ? now.day - 1 : _daysInMonth(_timelineAnchor) - 1;
      case TimelineGranularity.year:
        return _maximumTimelineValue().round();
    }
  }

  void _toggleTimelinePlayback() {
    if (_isTimelinePlaying) {
      _stopTimelinePlayback();
    } else {
      _startTimelinePlayback();
    }
  }

  void _startTimelinePlayback() {
    final maximum = _maximumPlayableTimelineValue();
    if (maximum <= 0) return;

    _timelinePlaybackTimer?.cancel();
    _timelineLoopPauseTimer?.cancel();
    _setTimelineValue(0);
    setState(() => _isTimelinePlaying = true);

    _scheduleTimelinePlayback();
  }

  void _scheduleTimelinePlayback() {
    _timelinePlaybackTimer?.cancel();

    _timelinePlaybackTimer = Timer.periodic(_timelinePlaybackStepDuration(), (
      _,
    ) {
      if (!mounted) return;

      final current = _initialTimelineValue().round();
      final end = _maximumPlayableTimelineValue();
      if (current >= end) {
        if (_isTimelineLooping) {
          _pauseBeforeTimelineLoop();
        } else {
          _stopTimelinePlayback();
        }
        return;
      }

      _setTimelineValue(current + 1);
    });
  }

  void _pauseBeforeTimelineLoop() {
    _timelinePlaybackTimer?.cancel();
    _timelinePlaybackTimer = null;
    _timelineLoopPauseTimer?.cancel();
    _timelineLoopPauseTimer = Timer(const Duration(milliseconds: 1250), () {
      if (!mounted || !_isTimelinePlaying || !_isTimelineLooping) return;
      _setTimelineValue(0);
      _scheduleTimelinePlayback();
    });
  }

  void _setTimelinePlaybackSpeed(TimelinePlaybackSpeed speed) {
    if (speed == _timelinePlaybackSpeed) return;

    setState(() => _timelinePlaybackSpeed = speed);
    if (_isTimelinePlaying) _scheduleTimelinePlayback();
  }

  void _stopTimelinePlayback() {
    _timelinePlaybackTimer?.cancel();
    _timelineLoopPauseTimer?.cancel();
    _timelinePlaybackTimer = null;
    _timelineLoopPauseTimer = null;
    if (mounted && _isTimelinePlaying) {
      setState(() => _isTimelinePlaying = false);
    }
  }

  double _maximumTimelineValue() {
    switch (_timelineGranularity) {
      case TimelineGranularity.day:
        return 23;
      case TimelineGranularity.week:
        return 6;
      case TimelineGranularity.month:
        return _daysInMonth(_timelineAnchor).toDouble() - 1;
      case TimelineGranularity.year:
        return (DateTime.now().year - _yearWindowStart()).toDouble();
    }
  }

  double _initialTimelineValue() {
    switch (_timelineGranularity) {
      case TimelineGranularity.day:
        return _timelineAnchor.hour.toDouble();
      case TimelineGranularity.week:
        return (_timelineAnchor.weekday - 1).toDouble();
      case TimelineGranularity.month:
        return (_timelineAnchor.day - 1).toDouble();
      case TimelineGranularity.year:
        return (_timelineAnchor.year - _yearWindowStart())
            .clamp(0, _maximumTimelineValue().round())
            .toDouble();
    }
  }

  void _setTimelineValue(double value) {
    final rounded = value.round();
    // Keep an anchor separate from the range start.  A year range begins on
    // January 1, but the next Month/Week/Day view should still open around
    // the date the person was exploring (for example, today in August).
    final previousAnchor = _timelineAnchor;
    late DateTime start;
    late DateTime end;
    late DateTime nextAnchor;

    switch (_timelineGranularity) {
      case TimelineGranularity.day:
        start = DateTime(
          _timelineAnchor.year,
          _timelineAnchor.month,
          _timelineAnchor.day,
          rounded,
        );
        end = start
            .add(const Duration(hours: 1))
            .subtract(const Duration(milliseconds: 1));
        nextAnchor = start;
      case TimelineGranularity.week:
        final weekStart = _timelineAnchor.subtract(
          Duration(days: _timelineAnchor.weekday - 1),
        );
        start = DateTime(
          weekStart.year,
          weekStart.month,
          weekStart.day,
        ).add(Duration(days: rounded));
        end = start
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1));
        nextAnchor = _withTimeFrom(start, previousAnchor);
      case TimelineGranularity.month:
        start = DateTime(
          _timelineAnchor.year,
          _timelineAnchor.month,
          rounded + 1,
        );
        end = start
            .add(const Duration(days: 1))
            .subtract(const Duration(milliseconds: 1));
        nextAnchor = _withTimeFrom(start, previousAnchor);
      case TimelineGranularity.year:
        start = DateTime(_yearWindowStart() + rounded, 1, 1);
        end = DateTime(
          start.year + 1,
          1,
          1,
        ).subtract(const Duration(milliseconds: 1));
        nextAnchor = _anchorInYear(start.year, previousAnchor);
    }

    final now = DateTime.now();

    // Keep the full current month, week, and day visible on the slider, but
    // do not let the user apply a range that has not happened yet.
    if (start.isAfter(now)) return;
    if (end.isAfter(now)) end = now;

    if (nextAnchor.isAfter(now)) nextAnchor = now;

    setState(() => _timelineAnchor = nextAnchor);
    _updateFilter(
      _filterState.copyWith(
        dateRange: DateTimeRange(start: start, end: end),
      ),
    );
  }

  int _yearWindowStart() {
    const verifiedHistoryStartYear = 2024;
    return _firstAvailableDate.year > verifiedHistoryStartYear
        ? _firstAvailableDate.year
        : verifiedHistoryStartYear;
  }

  int _daysInMonth(DateTime date) => DateTime(date.year, date.month + 1, 0).day;

  DateTime _withTimeFrom(DateTime date, DateTime timeSource) => DateTime(
    date.year,
    date.month,
    date.day,
    timeSource.hour,
    timeSource.minute,
    timeSource.second,
    timeSource.millisecond,
    timeSource.microsecond,
  );

  DateTime _anchorInYear(int year, DateTime previousAnchor) {
    final lastDayOfMonth = DateTime(year, previousAnchor.month + 1, 0).day;
    return DateTime(
      year,
      previousAnchor.month,
      previousAnchor.day.clamp(1, lastDayOfMonth),
      previousAnchor.hour,
      previousAnchor.minute,
      previousAnchor.second,
      previousAnchor.millisecond,
      previousAnchor.microsecond,
    );
  }

  String _timelineLabel() {
    final range = _filterState.dateRange;
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
    if (_timelineGranularity == TimelineGranularity.year) {
      return '${range.start.year}';
    }
    if (_timelineGranularity == TimelineGranularity.month) {
      return '${months[range.start.month - 1]} ${range.start.day}';
    }
    if (_timelineGranularity == TimelineGranularity.day) {
      final hour = range.start.hour;
      final displayHour = hour % 12 == 0 ? 12 : hour % 12;
      final period = hour < 12 ? 'AM' : 'PM';
      return '${months[range.start.month - 1]} ${range.start.day} · $displayHour $period';
    }
    const weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    return '${weekdays[range.start.weekday - 1]} · '
        '${months[range.start.month - 1]} ${range.start.day}';
  }

  Widget _timelineDock() => Container(
    padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
    decoration: BoxDecoration(
      color: const Color(0xF0091826),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF4A6074)),
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 620;
            final details = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                HorizontalHeatLegend(
                  isSampleData: LotteryActivityRepository.isSampleData,
                  onSourceTap: _showActivitySourceSheet,
                ),
                const SizedBox(width: 10),
                OutlinedButton.icon(
                  onPressed: _selectDateRange,
                  icon: const Icon(Icons.calendar_month_rounded, size: 18),
                  label: Text(_timelineAnchorLabel()),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    side: const BorderSide(color: Color(0xFF4A6074)),
                    minimumSize: const Size(0, 38),
                  ),
                ),
                const SizedBox(width: 4),
                Tooltip(
                  message: 'Return timeline to now',
                  child: IconButton(
                    onPressed: _returnTimelineToNow,
                    icon: const Icon(Icons.my_location_rounded, size: 19),
                    color: const Color(0xFF93C5FD),
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ],
            );
            return isCompact
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [details, const SizedBox(height: 10)],
                  )
                : Align(alignment: Alignment.centerLeft, child: details);
          },
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            const Text(
              'TIMELINE',
              style: TextStyle(
                color: Colors.white,
                fontSize: 13,
                letterSpacing: 0.8,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(
              Icons.info_outline_rounded,
              color: Colors.white60,
              size: 16,
            ),
            const SizedBox(width: 4),
            Tooltip(
              message: _isTimelinePlaying ? 'Pause timeline' : 'Play timeline',
              child: IconButton(
                onPressed: _toggleTimelinePlayback,
                visualDensity: VisualDensity.compact,
                icon: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 160),
                  child: Icon(
                    _isTimelinePlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    key: ValueKey<bool>(_isTimelinePlaying),
                    color: const Color(0xFF60A5FA),
                  ),
                ),
              ),
            ),
            Tooltip(
              message: _isTimelineLooping
                  ? 'Turn off timeline loop'
                  : 'Loop timeline',
              child: IconButton(
                onPressed: () {
                  setState(() => _isTimelineLooping = !_isTimelineLooping);
                },
                visualDensity: VisualDensity.compact,
                icon: Icon(
                  Icons.repeat_rounded,
                  color: _isTimelineLooping
                      ? const Color(0xFF60A5FA)
                      : Colors.white54,
                ),
              ),
            ),
            PopupMenuButton<TimelinePlaybackSpeed>(
              tooltip: 'Playback speed: ${_timelinePlaybackSpeed.label}',
              onSelected: _setTimelinePlaybackSpeed,
              color: const Color(0xFF122333),
              itemBuilder: (context) => TimelinePlaybackSpeed.values
                  .map(
                    (speed) => PopupMenuItem<TimelinePlaybackSpeed>(
                      value: speed,
                      child: Row(
                        children: [
                          Icon(
                            speed == _timelinePlaybackSpeed
                                ? Icons.check_rounded
                                : Icons.speed_rounded,
                            color: speed == _timelinePlaybackSpeed
                                ? const Color(0xFF60A5FA)
                                : Colors.white54,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text('${speed.label}  ${speed.compactLabel}'),
                        ],
                      ),
                    ),
                  )
                  .toList(growable: false),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.speed_rounded,
                      color: Colors.white54,
                      size: 17,
                    ),
                    const SizedBox(width: 3),
                    Text(
                      _timelinePlaybackSpeed.compactLabel,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const Spacer(),
            for (final mode in TimelineGranularity.values)
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: ChoiceChip(
                  label: Text(mode.label),
                  selected: mode == _timelineGranularity,
                  selectedColor: const Color(0xFF1478FF),
                  backgroundColor: const Color(0xFF122333),
                  side: BorderSide(
                    color: mode == _timelineGranularity
                        ? const Color(0xFF60A5FA)
                        : const Color(0xFF355066),
                  ),
                  labelStyle: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: mode == _timelineGranularity
                        ? FontWeight.w700
                        : FontWeight.w500,
                  ),
                  onSelected: (_) => _setGranularity(mode),
                ),
              ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 2, top: 2),
          child: Text(
            'Now showing: ${_timelineLabel()}',
            style: const TextStyle(
              color: Color(0xFF93C5FD),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        const SizedBox(height: 4),
        SliderTheme(
          data: SliderTheme.of(context).copyWith(
            activeTrackColor: const Color(0xFF1478FF),
            inactiveTrackColor: Colors.white24,
            thumbColor: Colors.white,
            overlayColor: const Color(0x331478FF),
            trackHeight: 3,
          ),
          child: Slider(
            value: _initialTimelineValue(),
            min: 0,
            max: _maximumTimelineValue(),
            // Each slider step is a year, calendar day, weekday, or hour,
            // depending on the selected timeline scale.
            divisions: _maximumTimelineValue().round().clamp(1, 10000).toInt(),
            label: _timelineLabel(),
            onChanged: (value) {
              _stopTimelinePlayback();
              _setTimelineValue(value);
            },
          ),
        ),
        _timelineAxis(),
      ],
    ),
  );

  String _timelineAnchorLabel() {
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
    return '${months[_timelineAnchor.month - 1]} ${_timelineAnchor.day}, ${_timelineAnchor.year}';
  }

  Widget _timelineAxis() {
    final labels = switch (_timelineGranularity) {
      TimelineGranularity.year => [
        '${_yearWindowStart()}',
        '${_yearWindowStart() + 4}',
        '${DateTime.now().year}',
      ],
      TimelineGranularity.month => [
        '1',
        '${(_daysInMonth(_timelineAnchor) + 1) ~/ 2}',
        '${_daysInMonth(_timelineAnchor)}',
      ],
      TimelineGranularity.week => const ['Mon', 'Wed', 'Sun'],
      TimelineGranularity.day => const ['12 AM', '12 PM', '11 PM'],
    };
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: labels
          .map(
            (label) => Text(
              label,
              style: TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _MapLocationSearchDelegate extends SearchDelegate<MapSearchResult?> {
  static final Map<String, LatLng> _stateCenters = {
    'AL': LatLng(32.8, -86.8),
    'AK': LatLng(64.5, -151.5),
    'AZ': LatLng(34.2, -111.7),
    'AR': LatLng(34.9, -92.4),
    'CA': LatLng(37.2, -119.7),
    'CO': LatLng(39.0, -105.5),
    'CT': LatLng(41.6, -72.7),
    'DE': LatLng(39.0, -75.5),
    'FL': LatLng(27.8, -81.7),
    'GA': LatLng(32.7, -83.4),
    'HI': LatLng(20.8, -156.3),
    'ID': LatLng(44.2, -114.4),
    'IL': LatLng(40.0, -89.2),
    'IN': LatLng(39.9, -86.3),
    'IA': LatLng(42.0, -93.5),
    'KS': LatLng(38.5, -98.0),
    'KY': LatLng(37.7, -85.0),
    'LA': LatLng(31.0, -92.0),
    'ME': LatLng(45.2, -69.0),
    'MD': LatLng(39.0, -76.7),
    'MA': LatLng(42.3, -71.8),
    'MI': LatLng(44.3, -85.6),
    'MN': LatLng(46.4, -94.6),
    'MS': LatLng(32.7, -89.7),
    'MO': LatLng(38.5, -92.5),
    'MT': LatLng(47.0, -109.6),
    'NE': LatLng(41.5, -99.8),
    'NV': LatLng(39.3, -116.6),
    'NH': LatLng(43.7, -71.6),
    'NJ': LatLng(40.1, -74.7),
    'NM': LatLng(34.4, -106.1),
    'NY': LatLng(42.9, -75.5),
    'NC': LatLng(35.5, -79.4),
    'ND': LatLng(47.5, -100.5),
    'OH': LatLng(40.4, -82.8),
    'OK': LatLng(35.6, -97.5),
    'OR': LatLng(43.9, -120.6),
    'PA': LatLng(40.9, -77.8),
    'RI': LatLng(41.7, -71.5),
    'SC': LatLng(33.8, -80.9),
    'SD': LatLng(44.4, -100.2),
    'TN': LatLng(35.9, -86.5),
    'TX': LatLng(31.0, -99.3),
    'UT': LatLng(39.3, -111.7),
    'VT': LatLng(44.0, -72.7),
    'VA': LatLng(37.5, -78.7),
    'WA': LatLng(47.4, -120.7),
    'WV': LatLng(38.6, -80.6),
    'WI': LatLng(44.6, -89.7),
    'WY': LatLng(43.0, -107.6),
  };

  _MapLocationSearchDelegate()
    : super(
        searchFieldLabel: 'Search states, counties, or winning cities',
        searchFieldStyle: const TextStyle(color: Colors.white),
      );

  @override
  ThemeData appBarTheme(BuildContext context) {
    final base = Theme.of(context);
    return base.copyWith(
      scaffoldBackgroundColor: const Color(0xFF071827),
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF071827),
        foregroundColor: Colors.white,
      ),
      inputDecorationTheme: const InputDecorationTheme(
        hintStyle: TextStyle(color: Colors.white54),
      ),
    );
  }

  List<MapSearchResult> get _results {
    final states = allStates
        .where((state) => _stateCenters.containsKey(state.abbreviation))
        .map(
          (state) => MapSearchResult(
            label: state.name,
            subtitle: '${state.abbreviation} • State',
            location: _stateCenters[state.abbreviation]!,
            zoom: state.abbreviation == 'AK' || state.abbreviation == 'HI'
                ? 4.6
                : 5.4,
            stateName: state.name,
          ),
        );
    final locations = LotteryActivityRepository.activity.map(
      (activity) => MapSearchResult(
        label: '${activity.city}, ${activity.state}',
        subtitle: '${activity.county} • ${activity.game.label}',
        location: activity.location,
        zoom: 8.5,
        stateName: null,
      ),
    );
    return [...states, ...locations];
  }

  List<MapSearchResult> get _filteredResults {
    final text = query.trim().toLowerCase();
    if (text.isEmpty) return _results;
    return _results
        .where(
          (result) =>
              '${result.label} ${result.subtitle}'.toLowerCase().contains(text),
        )
        .toList();
  }

  @override
  List<Widget>? buildActions(BuildContext context) => [
    if (query.isNotEmpty)
      IconButton(
        tooltip: 'Clear',
        onPressed: () => query = '',
        icon: const Icon(Icons.clear_rounded),
      ),
  ];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(
    tooltip: 'Back',
    onPressed: () => close(context, null),
    icon: const Icon(Icons.arrow_back_rounded),
  );

  @override
  Widget buildResults(BuildContext context) => _resultList(context);

  @override
  Widget buildSuggestions(BuildContext context) => _resultList(context);

  Widget _resultList(BuildContext context) {
    final results = _filteredResults;
    return Container(
      color: const Color(0xFF071827),
      child: results.isEmpty
          ? const Center(
              child: Text(
                'No matching locations found.',
                style: TextStyle(color: Colors.white60),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              itemCount: results.length,
              separatorBuilder: (_, _) => const SizedBox(height: 8),
              itemBuilder: (context, index) {
                final result = results[index];
                return Material(
                  color: const Color(0xFF102638),
                  borderRadius: BorderRadius.circular(14),
                  child: ListTile(
                    onTap: () => close(context, result),
                    leading: CircleAvatar(
                      backgroundColor: const Color(0x331478FF),
                      child: Icon(
                        result.stateName == null
                            ? Icons.location_on_rounded
                            : Icons.map_outlined,
                        color: const Color(0xFF60A5FA),
                      ),
                    ),
                    title: Text(
                      result.label,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: Text(
                      result.subtitle,
                      style: const TextStyle(color: Colors.white60),
                    ),
                    trailing: const Icon(
                      Icons.north_east_rounded,
                      color: Colors.white54,
                    ),
                  ),
                );
              },
            ),
    );
  }
}
