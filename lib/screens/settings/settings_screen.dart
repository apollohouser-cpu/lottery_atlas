import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../services/app_preferences.dart';
import '../../services/lottery_data_status_service.dart';
import '../../models/state_model.dart';
import 'national_draw_results_screen.dart';
import '../../widgets/map/map_detail_mode.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const MethodChannel _magicMouseChannel = MethodChannel(
    'lottery_atlas/magic_mouse',
  );

  MapDetailMode _detailMode = MapDetailMode.standard;
  bool _showTimeZones = false;
  String? _homeState;
  bool _isLoading = true;
  bool _isRefreshingData = false;
  LotteryDataStatus? _dataStatus;

  @override
  void initState() {
    super.initState();
    // Settings has scrollable controls. Release the map's native scroll bridge
    // while this route is on top so scrolling a picker never zooms the map.
    _magicMouseChannel.invokeMethod<void>('setMapActive', false);
    _loadScreenData();
  }

  @override
  void dispose() {
    // Settings is presented from the map, so restore its native scroll bridge
    // when the user returns.
    _magicMouseChannel.invokeMethod<void>('setMapActive', true);
    super.dispose();
  }

  Future<void> _loadScreenData() async {
    final detailMode = await AppPreferences.getMapDetailMode();
    final showTimeZones = await AppPreferences.getShowTimeZones();
    final homeState = await AppPreferences.getHomeState();
    final dataStatus = await LotteryDataStatusService.load();
    if (!mounted) return;
    setState(() {
      _detailMode = detailMode;
      _showTimeZones = showTimeZones;
      _homeState = homeState;
      _dataStatus = dataStatus;
      _isLoading = false;
    });
  }

  Future<void> _refreshDataStatus() async {
    setState(() => _isRefreshingData = true);
    final status = await LotteryDataStatusService.refresh();
    if (!mounted) return;
    setState(() {
      _dataStatus = status;
      _isRefreshingData = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Data-source status refreshed.')),
    );
  }

  Future<void> _setDetailMode(MapDetailMode detailMode) async {
    setState(() => _detailMode = detailMode);
    await AppPreferences.setMapDetailMode(detailMode);
  }

  Future<void> _setShowTimeZones(bool showTimeZones) async {
    setState(() => _showTimeZones = showTimeZones);
    await AppPreferences.setShowTimeZones(showTimeZones);
  }

  Future<void> _setHomeState(String? stateName) async {
    if (stateName == null) return;
    setState(() => _homeState = stateName);
    await AppPreferences.setHomeState(stateName);
  }

  Future<void> _clearHomeState() async {
    await AppPreferences.clearHomeState();
    if (mounted) setState(() => _homeState = null);
  }

  Future<void> _pickHomeState() async {
    final searchController = TextEditingController();
    String searchTerm = '';

    try {
      final stateName = await showDialog<String>(
        context: context,
        builder: (dialogContext) => StatefulBuilder(
          builder: (context, setDialogState) {
            final matchingStates = allStates
                .where((state) {
                  final searchable = '${state.name} ${state.abbreviation}'
                      .toLowerCase();
                  return searchable.contains(searchTerm.toLowerCase());
                })
                .toList(growable: false);

            return Dialog(
              backgroundColor: const Color(0xFF102638),
              insetPadding: const EdgeInsets.all(24),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
                side: const BorderSide(color: Color(0xFF355066)),
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxWidth: 460,
                  maxHeight: 560,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.home_work_outlined,
                            color: Color(0xFF1478FF),
                          ),
                          const SizedBox(width: 10),
                          const Expanded(
                            child: Text(
                              'Choose your home state',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.of(dialogContext).pop(),
                            icon: const Icon(Icons.close_rounded),
                            color: Colors.white70,
                            tooltip: 'Close',
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: searchController,
                        autofocus: true,
                        onChanged: (value) {
                          setDialogState(() => searchTerm = value.trim());
                        },
                        style: const TextStyle(color: Colors.white),
                        decoration: const InputDecoration(
                          prefixIcon: Icon(Icons.search_rounded),
                          hintText: 'Search states',
                          hintStyle: TextStyle(color: Colors.white54),
                          enabledBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF355066)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderSide: BorderSide(color: Color(0xFF1478FF)),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Expanded(
                        child: matchingStates.isEmpty
                            ? const Center(
                                child: Text(
                                  'No states match that search.',
                                  style: TextStyle(color: Colors.white60),
                                ),
                              )
                            : Scrollbar(
                                thumbVisibility: true,
                                child: ListView.separated(
                                  itemCount: matchingStates.length,
                                  separatorBuilder: (_, _) => const Divider(
                                    height: 1,
                                    color: Color(0xFF234154),
                                  ),
                                  itemBuilder: (context, index) {
                                    final state = matchingStates[index];
                                    final isSelected = state.name == _homeState;
                                    return ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                            horizontal: 8,
                                          ),
                                      leading: CircleAvatar(
                                        backgroundColor: isSelected
                                            ? const Color(0xFF1478FF)
                                            : const Color(0xFF19384E),
                                        child: Text(
                                          state.abbreviation,
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ),
                                      title: Text(
                                        state.name,
                                        style: const TextStyle(
                                          color: Colors.white,
                                        ),
                                      ),
                                      trailing: isSelected
                                          ? const Icon(
                                              Icons.check_circle_rounded,
                                              color: Color(0xFF1478FF),
                                            )
                                          : null,
                                      onTap: () => Navigator.of(
                                        dialogContext,
                                      ).pop(state.name),
                                    );
                                  },
                                ),
                              ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      );

      if (stateName != null) {
        await _setHomeState(stateName);
      }
    } finally {
      searchController.dispose();
    }
  }

  Future<void> _resetMapSettings() async {
    await AppPreferences.resetMapPreferences();
    if (!mounted) return;
    setState(() {
      _detailMode = MapDetailMode.standard;
      _showTimeZones = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Map settings restored to their defaults.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF071827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071827),
        foregroundColor: Colors.white,
        title: const Text('Settings'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1478FF)),
            )
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
              children: [
                const _SettingsHeading(
                  title: 'YOUR HOME',
                  subtitle:
                      'Use a preferred state for default drawing times. Your location is never requested.',
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF102638),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF355066)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(
                            Icons.home_work_outlined,
                            color: Color(0xFF1478FF),
                          ),
                          SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Home state',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      OutlinedButton.icon(
                        onPressed: _pickHomeState,
                        icon: const Icon(Icons.search_rounded),
                        label: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            _homeState == null
                                ? 'Choose your state'
                                : _homeState!,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(54),
                          alignment: Alignment.centerLeft,
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Color(0xFF355066)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      if (_homeState != null) ...[
                        const SizedBox(height: 10),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _clearHomeState,
                            icon: const Icon(Icons.close_rounded, size: 16),
                            label: const Text('Clear home state'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white70,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 26),
                const _SettingsHeading(
                  title: 'MAP EXPERIENCE',
                  subtitle: 'Choose how Lottery Atlas appears on your device.',
                ),
                const SizedBox(height: 12),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF102638),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF355066)),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.layers_rounded,
                              color: Color(0xFF1478FF),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: const [
                                  Text(
                                    'Preferred map view',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  SizedBox(height: 2),
                                  Text(
                                    'Applied immediately and saved for next time.',
                                    style: TextStyle(
                                      color: Colors.white54,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      ...MapDetailMode.values.map(
                        (mode) => RadioListTile<MapDetailMode>(
                          value: mode,
                          groupValue: _detailMode,
                          activeColor: const Color(0xFF1478FF),
                          title: Text(
                            mode.label,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: Text(
                            mode.description,
                            style: const TextStyle(
                              color: Colors.white54,
                              fontSize: 12,
                            ),
                          ),
                          onChanged: (value) {
                            if (value != null) _setDetailMode(value);
                          },
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF102638),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF355066)),
                  ),
                  child: SwitchListTile(
                    value: _showTimeZones,
                    activeThumbColor: const Color(0xFF1478FF),
                    secondary: const Icon(
                      Icons.schedule_rounded,
                      color: Color(0xFF1478FF),
                    ),
                    title: const Text(
                      'Time-zone clocks',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    subtitle: const Text(
                      'Show live time-zone boundaries and clocks on the national map.',
                      style: TextStyle(color: Colors.white54, fontSize: 12),
                    ),
                    onChanged: _setShowTimeZones,
                  ),
                ),
                const SizedBox(height: 26),
                const _SettingsHeading(
                  title: 'DATA',
                  subtitle: 'See what is currently powering the app.',
                ),
                const SizedBox(height: 12),
                _DataCenterCard(
                  status: _dataStatus!,
                  isRefreshing: _isRefreshingData,
                  onRefresh: _refreshDataStatus,
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const NationalDrawResultsScreen(),
                    ),
                  ),
                  icon: const Icon(Icons.emoji_events_outlined),
                  label: const Text('National draw results'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: Color(0xFF355066)),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _resetMapSettings,
                  icon: const Icon(Icons.restart_alt_rounded),
                  label: const Text('Restore default map settings'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(48),
                    side: const BorderSide(color: Color(0xFF355066)),
                  ),
                ),
              ],
            ),
    );
  }
}

class _DataCenterCard extends StatelessWidget {
  const _DataCenterCard({
    required this.status,
    required this.isRefreshing,
    required this.onRefresh,
  });

  final LotteryDataStatus status;
  final bool isRefreshing;
  final VoidCallback onRefresh;

  String get _lastCheckedLabel {
    final time = status.lastChecked;
    if (time == null) return 'Not refreshed yet';
    final hour = time.hour % 12 == 0 ? 12 : time.hour % 12;
    final minute = time.minute.toString().padLeft(2, '0');
    final suffix = time.hour >= 12 ? 'PM' : 'AM';
    return 'Status refreshed at $hour:$minute $suffix';
  }

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF102638),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF355066)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.layers_rounded, color: Color(0xFF1478FF)),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Mixed data sources active',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    status.sourceLabel,
                    style: const TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
        const Divider(height: 24, color: Colors.white12),
        ...status.sources.map(_SourceStatusRow.new),
        const SizedBox(height: 10),
        Text(
          '${status.recordCount} activity records loaded • $_lastCheckedLabel',
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        if (status.hasSampleSources) ...[
          const SizedBox(height: 8),
          const Text(
            'County activity is sample-only until an official county-level feed is connected.',
            style: TextStyle(color: Colors.white54, height: 1.35, fontSize: 12),
          ),
        ],
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: isRefreshing ? null : onRefresh,
            icon: isRefreshing
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            label: Text(
              isRefreshing ? 'Refreshing status…' : 'Refresh source status',
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: Color(0xFF355066)),
            ),
          ),
        ),
      ],
    ),
  );
}

class _SourceStatusRow extends StatelessWidget {
  const _SourceStatusRow(this.source);

  final LotteryDataSource source;

  ({Color color, String label, IconData icon}) get _appearance =>
      switch (source.kind) {
        LotteryDataSourceKind.live => (
          color: const Color(0xFF2CC36B),
          label: 'LIVE',
          icon: Icons.wifi_tethering_rounded,
        ),
        LotteryDataSourceKind.cached => (
          color: const Color(0xFF60A5FA),
          label: 'SAVED',
          icon: Icons.save_outlined,
        ),
        LotteryDataSourceKind.ready => (
          color: const Color(0xFF60A5FA),
          label: 'READY',
          icon: Icons.key_outlined,
        ),
        LotteryDataSourceKind.official => (
          color: const Color(0xFF1478FF),
          label: 'OFFICIAL',
          icon: Icons.verified_rounded,
        ),
        LotteryDataSourceKind.sample => (
          color: const Color(0xFFFFC107),
          label: 'SAMPLE',
          icon: Icons.science_outlined,
        ),
        LotteryDataSourceKind.setupRequired => (
          color: const Color(0xFFFFC107),
          label: 'SETUP',
          icon: Icons.key_outlined,
        ),
        LotteryDataSourceKind.unavailable => (
          color: const Color(0xFFFF6B6B),
          label: 'OFFLINE',
          icon: Icons.cloud_off_rounded,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final appearance = _appearance;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(appearance.icon, color: appearance.color, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        source.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: appearance.color.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Text(
                        appearance.label,
                        style: TextStyle(
                          color: appearance.color,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  source.detail,
                  style: const TextStyle(color: Colors.white54, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsHeading extends StatelessWidget {
  const _SettingsHeading({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          color: Color(0xFF60A5FA),
          fontSize: 12,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
        ),
      ),
      const SizedBox(height: 4),
      Text(
        subtitle,
        style: const TextStyle(color: Colors.white54, fontSize: 13),
      ),
    ],
  );
}
