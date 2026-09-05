import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/state_model.dart';
import '../../models/lottery_activity.dart';
import '../../models/favorite_lottery_game.dart';
import '../../models/favorite_place.dart';
import '../../models/south_carolina_retailer.dart';
import '../../models/state_scratch_game.dart';
import '../../models/state_lottery_data_profile.dart';
import '../../app/app_route_observer.dart';
import '../../services/app_preferences.dart';
import '../../services/favorite_places_service.dart';
import '../../services/favorite_games_service.dart';
import '../../services/lottery_activity_feed_service.dart';
import '../../services/lottery_activity_repository.dart';
import '../../services/map_focus_service.dart';
import '../../services/north_carolina_scratch_catalog.dart';
import '../../services/south_carolina_lottery_map_filter_service.dart';
import '../../services/south_carolina_scratch_catalog.dart';
import '../../services/south_carolina_scratch_map_filter_service.dart';
import '../../services/south_carolina_retailer_map_service.dart';
import '../../services/south_carolina_retailer_feed_service.dart';
import '../../services/south_carolina_retailer_repository.dart';
import '../../services/state_retailer_directory_feed_service.dart';
import '../../services/state_retailer_directory_repository.dart';
import '../../services/state_scratch_catalog_registry.dart';
import '../../services/state_scratch_catalog_feed_service.dart';
import '../../screens/county/county_details_screen.dart';
import '../../screens/settings/national_draw_results_screen.dart';
import '../../screens/state/south_carolina_lottery_screen.dart';
import '../../screens/state/south_carolina_scratch_offs_screen.dart';
import '../../screens/state/south_carolina_retailers_screen.dart';
import '../../screens/state/state_lottery_source_screen.dart';
import '../../screens/state/lottery_overview_screen.dart';
import '../../services/state_navigation_service.dart';
import '../../services/state_lottery_data_registry.dart';
import '../../services/state_lottery_source_registry.dart';
import 'map_controls_overlay.dart';
import 'map_detail_mode.dart';
import 'map_filter_state.dart';
import 'map_search_result.dart';
import 'map_visual_overlays.dart';
import 'next_drawings_panel.dart';
import 'map_time_zone_overlays.dart';

class LiveLotteryMap extends StatefulWidget {
  const LiveLotteryMap({super.key});

  @override
  State<LiveLotteryMap> createState() => _LiveLotteryMapState();
}

class _LiveLotteryMapState extends State<LiveLotteryMap>
    with TickerProviderStateMixin, RouteAware {
  static const MethodChannel _magicMouseChannel = MethodChannel(
    'lottery_atlas/magic_mouse',
  );

  static final LatLng _usCenter = LatLng(36.0, -95.0);
  static final LatLng _alaskaCenter = LatLng(64.5, -151.5);
  static final LatLng _southCarolinaCenter = LatLng(33.84, -80.9);

  static const double _initialZoom = 4.1;
  static const double _minZoom = 3.0;
  static const double _maxZoom = 18.0;
  static const String _favoriteActivityStorageKey =
      'lottery_atlas.favorite_activity_keys';

  final MapController _mapController = MapController();
  ModalRoute<dynamic>? _hostingRoute;
  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  late final AnimationController _cameraAnimationController;
  late final AnimationController _heatBubbleAnimationController;
  late final AnimationController _countyFocusAnimationController;
  late final AnimationController _retailerFocusAnimationController;
  final Map<String, Color> _previousCountyHeatColors = <String, Color>{};

  LatLng? _cameraAnimationStart;
  LatLng? _cameraAnimationEnd;
  double _cameraAnimationStartZoom = _initialZoom;
  double _cameraAnimationEndZoom = _initialZoom;

  final LayerHitNotifier<String> _stateHitNotifier =
      ValueNotifier<LayerHitResult<String>?>(null);

  final LayerHitNotifier<String> _countyHitNotifier =
      ValueNotifier<LayerHitResult<String>?>(null);

  late final Future<_MapGeometry> _mapGeometryFuture;

  List<_StateShape> _stateShapes = [];
  List<_CountyShape> _countyShapes = [];

  MapDetailMode _mapDetailMode = MapDetailMode.standard;
  late MapFilterState _filterState;
  final Set<String> _favoriteActivityKeys = <String>{};
  Timer? _publishedDataRefreshTimer;
  Future<void>? _publishedDataRefreshInProgress;
  double _currentZoom = _initialZoom;
  bool _showTimeZones = false;
  bool _showNextDrawings = false;
  bool _showScratchOffs = false;
  bool _showStateGames = false;
  String? _selectedStateActivityGameName;
  String? _homeStateName;

  String? _hoveredStateName;
  String? _selectedStateName;

  String? _hoveredCountyId;
  String? _selectedCountyId;
  String? _focusedHeatCountyKey;
  String? _focusedRetailerId;

  static const Map<String, String> _stateFipsByName = {
    'Alabama': '01',
    'Alaska': '02',
    'Arizona': '04',
    'Arkansas': '05',
    'California': '06',
    'Colorado': '08',
    'Connecticut': '09',
    'Delaware': '10',
    'District of Columbia': '11',
    'Florida': '12',
    'Georgia': '13',
    'Hawaii': '15',
    'Idaho': '16',
    'Illinois': '17',
    'Indiana': '18',
    'Iowa': '19',
    'Kansas': '20',
    'Kentucky': '21',
    'Louisiana': '22',
    'Maine': '23',
    'Maryland': '24',
    'Massachusetts': '25',
    'Michigan': '26',
    'Minnesota': '27',
    'Mississippi': '28',
    'Missouri': '29',
    'Montana': '30',
    'Nebraska': '31',
    'Nevada': '32',
    'New Hampshire': '33',
    'New Jersey': '34',
    'New Mexico': '35',
    'New York': '36',
    'North Carolina': '37',
    'North Dakota': '38',
    'Ohio': '39',
    'Oklahoma': '40',
    'Oregon': '41',
    'Pennsylvania': '42',
    'Rhode Island': '44',
    'South Carolina': '45',
    'South Dakota': '46',
    'Tennessee': '47',
    'Texas': '48',
    'Utah': '49',
    'Vermont': '50',
    'Virginia': '51',
    'Washington': '53',
    'West Virginia': '54',
    'Wisconsin': '55',
    'Wyoming': '56',
  };

  @override
  void initState() {
    super.initState();

    _filterState = _todayFilter();
    _cameraAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 560),
    )..addListener(_advanceCameraAnimation);
    _heatBubbleAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1300),
    )..addListener(_advanceHeatBubbleAnimation);
    _countyFocusAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 780),
    )..addListener(_advanceCountyFocusAnimation);
    _retailerFocusAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 680),
    )..addListener(_advanceRetailerFocusAnimation);

    _magicMouseChannel.setMethodCallHandler(_handleNativeMouseEvent);
    _magicMouseChannel.invokeMethod<void>('setMapActive', true);

    _stateHitNotifier.addListener(_updateHoveredState);
    _countyHitNotifier.addListener(_updateHoveredCounty);
    LotteryActivityRepository.changes.addListener(_onActivityFeedChanged);
    StateScratchCatalogRegistry.changes.addListener(_onScratchCatalogChanged);
    SouthCarolinaScratchMapFilterService.selection.addListener(
      _onSouthCarolinaScratchFilterChanged,
    );
    SouthCarolinaLotteryMapFilterService.selection.addListener(
      _onSouthCarolinaLotteryFilterChanged,
    );
    SouthCarolinaRetailerMapService.isVisible.addListener(
      _onSouthCarolinaRetailerVisibilityChanged,
    );
    SouthCarolinaRetailerRepository.changes.addListener(_onRetailerFeedChanged);
    StateRetailerDirectoryRepository.changes.addListener(
      _onRetailerFeedChanged,
    );
    MapFocusService.requestedFocus.addListener(_onMapFocusRequested);
    FavoritePlacesService.load();

    _favoriteActivityKeys.addAll(
      LotteryActivityRepository.activity
          .where((activity) => activity.isFavorite)
          .map(_activityKey),
    );
    _mapGeometryFuture = _loadMapGeometry().then((geometry) {
      _stateShapes = geometry.states;
      _countyShapes = geometry.counties;
      if (mounted) _restartHeatBubbleAnimation();
      return geometry;
    });

    _loadFavorites();
    _loadMapPreferences(openHomeOnLaunch: true);
    // Restore cached data and then check the public feeds as soon as the map
    // opens. While the app stays open, repeat the safe update check so all
    // published state activity stays current throughout the day.
    unawaited(_refreshPublishedLotteryData());
    _publishedDataRefreshTimer = Timer.periodic(
      const Duration(hours: 6),
      (_) => unawaited(_refreshPublishedLotteryData()),
    );
    AppPreferences.changes.addListener(_loadMapPreferences);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _restartHeatBubbleAnimation();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final route = ModalRoute.of(context);
    if (route == null || identical(route, _hostingRoute)) return;

    if (_hostingRoute != null) {
      appRouteObserver.unsubscribe(this);
    }
    _hostingRoute = route;
    appRouteObserver.subscribe(this, route);
  }

  @override
  void didPushNext() {
    _magicMouseChannel.invokeMethod<void>('setMapActive', false);
  }

  @override
  void didPopNext() {
    if (mounted) {
      _magicMouseChannel.invokeMethod<void>('setMapActive', true);
    }
  }

  MapFilterState _todayFilter() {
    final now = DateTime.now();
    return MapFilterState(
      dateRange: DateTimeRange(
        start: DateTime(now.year, now.month, now.day),
        end: now,
      ),
    );
  }

  @override
  void dispose() {
    appRouteObserver.unsubscribe(this);
    _publishedDataRefreshTimer?.cancel();
    _cameraAnimationController
      ..removeListener(_advanceCameraAnimation)
      ..dispose();
    _heatBubbleAnimationController
      ..removeListener(_advanceHeatBubbleAnimation)
      ..dispose();
    _countyFocusAnimationController
      ..removeListener(_advanceCountyFocusAnimation)
      ..dispose();
    _retailerFocusAnimationController
      ..removeListener(_advanceRetailerFocusAnimation)
      ..dispose();
    _magicMouseChannel.invokeMethod<void>('setMapActive', false);
    _magicMouseChannel.setMethodCallHandler(null);

    _stateHitNotifier.removeListener(_updateHoveredState);
    _countyHitNotifier.removeListener(_updateHoveredCounty);

    _stateHitNotifier.dispose();
    _countyHitNotifier.dispose();
    LotteryActivityRepository.changes.removeListener(_onActivityFeedChanged);
    StateScratchCatalogRegistry.changes.removeListener(
      _onScratchCatalogChanged,
    );
    SouthCarolinaScratchMapFilterService.selection.removeListener(
      _onSouthCarolinaScratchFilterChanged,
    );
    SouthCarolinaLotteryMapFilterService.selection.removeListener(
      _onSouthCarolinaLotteryFilterChanged,
    );
    SouthCarolinaRetailerMapService.isVisible.removeListener(
      _onSouthCarolinaRetailerVisibilityChanged,
    );
    SouthCarolinaRetailerRepository.changes.removeListener(
      _onRetailerFeedChanged,
    );
    StateRetailerDirectoryRepository.changes.removeListener(
      _onRetailerFeedChanged,
    );
    MapFocusService.requestedFocus.removeListener(_onMapFocusRequested);
    AppPreferences.changes.removeListener(_loadMapPreferences);

    super.dispose();
  }

  Future<void> _loadMapPreferences({bool openHomeOnLaunch = false}) async {
    final detailMode = await AppPreferences.getMapDetailMode();
    final showTimeZones = await AppPreferences.getShowTimeZones();
    final homeStateName = await AppPreferences.getHomeState();
    if (!mounted) return;
    final didChangeHomeState = homeStateName != _homeStateName;
    setState(() {
      _mapDetailMode = detailMode;
      _showTimeZones = showTimeZones;
      _homeStateName = homeStateName;
    });

    if ((!openHomeOnLaunch && !didChangeHomeState) || homeStateName == null) {
      return;
    }

    await _mapGeometryFuture;
    if (!mounted) return;
    _goToHomeState();
  }

  Future<void> _loadPublishedActivityFeed() async {
    await LotteryActivityFeedService.loadConfiguredFeed();
  }

  Future<void> _loadPublishedRetailerFeed() async {
    await SouthCarolinaRetailerFeedService.loadConfiguredFeed();
  }

  Future<void> _loadPublishedScratchCatalogFeed() async {
    await StateScratchCatalogFeedService.loadConfiguredFeed();
  }

  Future<void> _loadBundledRetailerDirectories() async {
    await StateRetailerDirectoryFeedService.loadBundledDirectories();
  }

  Future<void> _refreshPublishedLotteryData({
    bool showConfirmation = false,
  }) async {
    final existingRefresh = _publishedDataRefreshInProgress;
    if (existingRefresh != null) {
      await existingRefresh;
      return;
    }

    final refresh = Future.wait([
      _loadPublishedActivityFeed(),
      _loadPublishedRetailerFeed(),
      _loadPublishedScratchCatalogFeed(),
      _loadBundledRetailerDirectories(),
    ]);
    _publishedDataRefreshInProgress = refresh;

    try {
      await refresh;
      if (!mounted || !showConfirmation) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Lottery data update check finished.')),
      );
    } finally {
      if (identical(_publishedDataRefreshInProgress, refresh)) {
        _publishedDataRefreshInProgress = null;
      }
    }
  }

  Future<void> _refreshPublishedActivityFeed() =>
      _refreshPublishedLotteryData(showConfirmation: true);

  void _onActivityFeedChanged() {
    if (!mounted) return;
    setState(() {});
    _restartHeatBubbleAnimation();
  }

  void _onScratchCatalogChanged() {
    if (mounted) setState(() {});
  }

  void _onRetailerFeedChanged() {
    if (mounted) setState(() {});
  }

  void _onMapFocusRequested() {
    final request = MapFocusService.requestedFocus.value;
    if (request == null) return;
    MapFocusService.clear();
    if (!mounted) return;

    switch (request.kind) {
      case MapFocusKind.state:
        _focusStateByName(request.stateName);
      case MapFocusKind.county:
        final countyId = request.countyId;
        if (countyId == null) return;
        setState(() {
          _selectedStateName = request.stateName;
          _selectedCountyId = null;
          _hoveredCountyId = null;
        });
        _focusCountyById(countyId);
      case MapFocusKind.city:
        final location = request.location;
        if (location == null) return;
        setState(() {
          _selectedStateName = request.stateName;
          _selectedCountyId = null;
          _hoveredCountyId = null;
          _focusedHeatCountyKey = null;
        });
        _animateMapTo(location, 10.8);
      case MapFocusKind.retailer:
        final retailerId = request.retailerId;
        if (retailerId == null) return;
        final activityMatches = LotteryActivityRepository.activity.where(
          (activity) => activity.id == retailerId,
        );
        if (activityMatches.isNotEmpty) {
          _focusActivityRetailer(activityMatches.first);
          return;
        }
        final matches = SouthCarolinaRetailerRepository.retailers.where(
          (retailer) => retailer.id == retailerId,
        );
        if (matches.isNotEmpty) {
          _focusRetailer(matches.first);
        } else {
          _focusStateByName(request.stateName);
        }
    }
  }

  void _onSouthCarolinaScratchFilterChanged() {
    if (!mounted) return;
    final selection = SouthCarolinaScratchMapFilterService.selection.value;
    if (selection == null) {
      setState(() {});
      return;
    }
    setState(() {
      _filterState = _filterState.copyWith(game: LotteryGame.scratchOff);
      _selectedStateName = 'South Carolina';
      _selectedCountyId = null;
      _hoveredCountyId = null;
    });
    _restartHeatBubbleAnimation();
    _mapController.move(_southCarolinaCenter, 6.4);
  }

  void _onSouthCarolinaLotteryFilterChanged() {
    if (!mounted) return;
    final selection = SouthCarolinaLotteryMapFilterService.selection.value;
    if (selection == null) {
      setState(() {});
      return;
    }
    setState(() {
      // The selected draw is now the only data source for the South Carolina
      // heat map, while the state view and its dropdown stay available.
      _filterState = _filterState.copyWith(game: selection.game);
      _selectedStateName = 'South Carolina';
      _selectedCountyId = null;
      _hoveredCountyId = null;
    });
    _restartHeatBubbleAnimation();
    _mapController.move(_southCarolinaCenter, 6.4);
  }

  void _onSouthCarolinaRetailerVisibilityChanged() {
    if (!mounted) return;

    if (!SouthCarolinaRetailerMapService.isVisible.value) {
      setState(() {});
      return;
    }

    setState(() {
      _selectedStateName = null;
      _selectedCountyId = null;
      _hoveredCountyId = null;
    });
    _mapController.move(_southCarolinaCenter, 6.4);
  }

  Future<void> _openSouthCarolinaGamePicker() async {
    final activeDrawFilter =
        SouthCarolinaLotteryMapFilterService.selection.value;
    final activeScratchFilter =
        SouthCarolinaScratchMapFilterService.selection.value;

    // The native Magic Mouse bridge otherwise sees wheel movement even while
    // a Flutter sheet is in front of the map. Temporarily hand scrolling to
    // the picker so its game list can be browsed normally.
    await _magicMouseChannel.invokeMethod<void>('setMapActive', false);
    if (!mounted) return;

    String? selection;
    try {
      selection = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: const Color(0xFF0B1D2C),
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => SafeArea(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 620),
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Change South Carolina game',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Choose another game without leaving the map.',
                  style: TextStyle(color: Colors.white60),
                ),
                const SizedBox(height: 12),
                _southCarolinaGamePickerTile(
                  sheetContext: sheetContext,
                  value: 'all',
                  title: 'All South Carolina activity',
                  subtitle: 'Show every published South Carolina record',
                  icon: Icons.map_rounded,
                  isSelected:
                      activeDrawFilter?.gameName == null &&
                      activeScratchFilter == null,
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 16, 4, 6),
                  child: Text(
                    'DRAW GAMES',
                    style: TextStyle(
                      color: Color(0xFF93C5FD),
                      fontSize: 12,
                      letterSpacing: 0.9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                ...SouthCarolinaLotteryMapFilter.drawGames.map(
                  (filter) => _southCarolinaGamePickerTile(
                    sheetContext: sheetContext,
                    value: filter.gameName!,
                    title: filter.gameName!,
                    subtitle: filter.label,
                    icon: filter.game.icon,
                    isSelected: activeDrawFilter?.gameName == filter.gameName,
                  ),
                ),
                const Padding(
                  padding: EdgeInsets.fromLTRB(4, 16, 4, 6),
                  child: Text(
                    'SCRATCH-OFFS',
                    style: TextStyle(
                      color: Color(0xFF93C5FD),
                      fontSize: 12,
                      letterSpacing: 0.9,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                _southCarolinaGamePickerTile(
                  sheetContext: sheetContext,
                  value: 'scratch-all',
                  title: 'All Scratch-Off activity',
                  subtitle: 'Show published Scratch-Off claim activity',
                  icon: Icons.confirmation_number_rounded,
                  isSelected:
                      activeScratchFilter != null &&
                      activeScratchFilter.gameId == 'all',
                ),
                _southCarolinaGamePickerTile(
                  sheetContext: sheetContext,
                  value: 'scratch-finder',
                  title: 'Open Scratch-Off prize finder',
                  subtitle: 'Choose a specific ticket and prize range',
                  icon: Icons.tune_rounded,
                  isSelected: false,
                ),
              ],
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        await _magicMouseChannel.invokeMethod<void>('setMapActive', true);
      }
    }

    if (!mounted || selection == null) return;

    if (selection == 'scratch-finder') {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const SouthCarolinaScratchOffsScreen(),
        ),
      );
      return;
    }

    if (selection == 'scratch-all') {
      SouthCarolinaLotteryMapFilterService.clear();
      SouthCarolinaScratchMapFilterService.apply(
        const SouthCarolinaScratchMapFilter(
          gameId: 'all',
          minimumPrize: 1,
          maximumPrize: 2500000,
        ),
      );
      return;
    }

    SouthCarolinaScratchMapFilterService.clear();
    if (selection == 'all') {
      SouthCarolinaLotteryMapFilterService.apply(
        const SouthCarolinaLotteryMapFilter.all(),
      );
      return;
    }

    final selectedDrawFilter = SouthCarolinaLotteryMapFilter.drawGames
        .firstWhere((filter) => filter.gameName == selection);
    SouthCarolinaLotteryMapFilterService.apply(selectedDrawFilter);
  }

  Future<void> _openSouthCarolinaScratchOffPicker() =>
      Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => const SouthCarolinaScratchOffsScreen(),
        ),
      );

  void _showSouthCarolinaScratchGameOnMap(String gameId) {
    SouthCarolinaLotteryMapFilterService.clear();

    if (gameId == 'all') {
      SouthCarolinaScratchMapFilterService.apply(
        const SouthCarolinaScratchMapFilter(
          gameId: 'all',
          minimumPrize: 1,
          maximumPrize: 2500000,
        ),
      );
    } else {
      final game = SouthCarolinaScratchCatalog.games.firstWhere(
        (item) => item.id == gameId,
      );
      SouthCarolinaScratchMapFilterService.apply(
        SouthCarolinaScratchMapFilter(
          gameId: game.id,
          minimumPrize: 1,
          maximumPrize: game.topPrize,
        ),
      );
    }

    setState(() => _showScratchOffs = false);
  }

  void _showSouthCarolinaDrawGameOnMap(String gameName) {
    final selectedFilter = SouthCarolinaLotteryMapFilter.drawGames.firstWhere(
      (filter) => filter.gameName == gameName,
    );
    SouthCarolinaScratchMapFilterService.clear();
    SouthCarolinaLotteryMapFilterService.apply(selectedFilter);
    setState(() => _showNextDrawings = false);
  }

  void _showStateDrawGameOnMap(String gameName) {
    if (_selectedStateName == 'South Carolina') {
      _showSouthCarolinaDrawGameOnMap(gameName);
      return;
    }

    final game = switch (gameName) {
      'Powerball' => LotteryGame.powerball,
      'Mega Millions' => LotteryGame.megaMillions,
      _ => LotteryGame.stateDraw,
    };
    SouthCarolinaScratchMapFilterService.clear();
    SouthCarolinaLotteryMapFilterService.clear();
    setState(() {
      _filterState = _filterState.copyWith(game: game);
      _selectedStateActivityGameName = gameName;
      _showNextDrawings = false;
    });
  }

  void _showNorthCarolinaScratchGameOnMap(String? gameName) {
    _showStateScratchGameOnMap(gameName);
  }

  void _showStateScratchGameOnMap(String? gameName) {
    final selectedStateName = _selectedStateName;
    if (selectedStateName == null) return;
    SouthCarolinaScratchMapFilterService.clear();
    SouthCarolinaLotteryMapFilterService.clear();
    setState(() {
      _selectedStateActivityGameName = gameName;
      _filterState = _filterState.copyWith(game: LotteryGame.scratchOff);
      _showStateGames = false;
    });
    _restartHeatBubbleAnimation();
  }

  Widget _southCarolinaGamePickerTile({
    required BuildContext sheetContext,
    required String value,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
  }) => ListTile(
    contentPadding: const EdgeInsets.symmetric(horizontal: 4),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    tileColor: isSelected ? const Color(0x331478FF) : Colors.transparent,
    leading: Icon(
      icon,
      color: isSelected ? const Color(0xFF60A5FA) : Colors.white70,
    ),
    title: Text(
      title,
      style: TextStyle(
        color: Colors.white,
        fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
      ),
    ),
    subtitle: Text(subtitle, style: const TextStyle(color: Colors.white60)),
    trailing: isSelected
        ? const Icon(Icons.check_circle_rounded, color: Color(0xFF1478FF))
        : const Icon(Icons.chevron_right_rounded, color: Colors.white38),
    onTap: () => Navigator.of(sheetContext).pop(value),
  );

  Future<void> _handleNativeMouseEvent(MethodCall call) async {
    if (!mounted ||
        call.method != 'scroll' ||
        !(ModalRoute.of(context)?.isCurrent ?? false)) {
      return;
    }

    final arguments = call.arguments as Map<Object?, Object?>?;
    final deltaY = (arguments?['deltaY'] as num?)?.toDouble() ?? 0.0;
    final zoomAmount = (-deltaY * 0.02).clamp(-0.35, 0.35).toDouble();

    if (zoomAmount.abs() >= 0.01) {
      _zoomBy(zoomAmount);
    }
  }

  Future<_MapGeometry> _loadMapGeometry() async {
    final stateShapes = await _loadStateShapes();
    final countyShapes = await _loadCountyShapes();

    return _MapGeometry(states: stateShapes, counties: countyShapes);
  }

  Future<List<_StateShape>> _loadStateShapes() async {
    final rawGeoJson = await rootBundle.loadString(
      'assets/maps/us_states.geojson',
    );

    final collection = jsonDecode(rawGeoJson) as Map<String, dynamic>;
    final features = collection['features'] as List<dynamic>;
    final shapes = <_StateShape>[];

    for (final rawFeature in features) {
      final feature = rawFeature as Map<String, dynamic>;
      final properties = feature['properties'] as Map<String, dynamic>?;
      final geometry = feature['geometry'] as Map<String, dynamic>?;

      final name = properties?['name'] as String?;
      final geometryType = geometry?['type'] as String?;
      final coordinates = geometry?['coordinates'] as List<dynamic>?;

      if (name == null || geometryType == null || coordinates == null) {
        continue;
      }

      if (geometryType == 'Polygon') {
        shapes.add(_stateShapeFromPolygon(name, coordinates));
      }

      if (geometryType == 'MultiPolygon') {
        for (final polygon in coordinates) {
          shapes.add(_stateShapeFromPolygon(name, polygon as List<dynamic>));
        }
      }
    }

    return shapes;
  }

  Future<List<_CountyShape>> _loadCountyShapes() async {
    final rawGeoJson = await rootBundle.loadString(
      'assets/maps/us_counties.geojson',
    );

    final collection = jsonDecode(rawGeoJson) as Map<String, dynamic>;
    final features = collection['features'] as List<dynamic>;
    final shapes = <_CountyShape>[];

    for (final rawFeature in features) {
      final feature = rawFeature as Map<String, dynamic>;
      final properties = feature['properties'] as Map<String, dynamic>?;
      final geometry = feature['geometry'] as Map<String, dynamic>?;

      final countyName = properties?['NAME']?.toString();
      final stateFips =
          properties?['STATEFP']?.toString() ??
          properties?['STATE']?.toString();
      final countyId =
          properties?['GEOID']?.toString() ??
          properties?['AFFGEOID']?.toString();

      final geometryType = geometry?['type'] as String?;
      final coordinates = geometry?['coordinates'] as List<dynamic>?;

      if (countyName == null ||
          stateFips == null ||
          countyId == null ||
          geometryType == null ||
          coordinates == null) {
        continue;
      }

      if (geometryType == 'Polygon') {
        shapes.add(
          _countyShapeFromPolygon(
            countyId: countyId,
            countyName: countyName,
            stateFips: stateFips,
            rings: coordinates,
          ),
        );
      }

      if (geometryType == 'MultiPolygon') {
        for (final polygon in coordinates) {
          shapes.add(
            _countyShapeFromPolygon(
              countyId: countyId,
              countyName: countyName,
              stateFips: stateFips,
              rings: polygon as List<dynamic>,
            ),
          );
        }
      }
    }

    return shapes;
  }

  _StateShape _stateShapeFromPolygon(String name, List<dynamic> rings) {
    return _StateShape(
      name: name,
      points: _coordinatesToLatLng(rings.first as List<dynamic>),
      holePoints: rings
          .skip(1)
          .map((ring) => _coordinatesToLatLng(ring as List<dynamic>))
          .toList(),
    );
  }

  _CountyShape _countyShapeFromPolygon({
    required String countyId,
    required String countyName,
    required String stateFips,
    required List<dynamic> rings,
  }) {
    return _CountyShape(
      id: countyId,
      name: countyName,
      stateFips: stateFips,
      points: _coordinatesToLatLng(rings.first as List<dynamic>),
      holePoints: rings
          .skip(1)
          .map((ring) => _coordinatesToLatLng(ring as List<dynamic>))
          .toList(),
    );
  }

  List<LatLng> _coordinatesToLatLng(List<dynamic> coordinates) {
    return coordinates.map((coordinate) {
      final pair = coordinate as List<dynamic>;

      var longitude = (pair[0] as num).toDouble();

      while (longitude > 180) {
        longitude -= 360;
      }

      while (longitude < -180) {
        longitude += 360;
      }

      return LatLng((pair[1] as num).toDouble(), longitude);
    }).toList();
  }

  List<LotteryActivity> _visibleActivity() {
    return LotteryActivityRepository.activity.where((activity) {
      final scratchFilter =
          SouthCarolinaScratchMapFilterService.selection.value;
      final southCarolinaFilter =
          SouthCarolinaLotteryMapFilterService.selection.value;
      final selectedStateAbbreviation = _selectedStateName == null
          ? null
          : StateNavigationService.getStateByName(
              _selectedStateName!,
            )?.abbreviation.toUpperCase();
      // Keep the national map readable by showing Powerball and Mega Millions
      // until the user explicitly chooses "All lotteries". This rule always
      // applies in the U.S. view, even if a previous South Carolina picker is
      // still open or remembered.
      final nationalScopeIsActive =
          _selectedStateName == null &&
          _filterState.activityScope == MapActivityScope.nationalOnly;
      final matchesNationalScope =
          !nationalScopeIsActive ||
          activity.game == LotteryGame.powerball ||
          activity.game == LotteryGame.megaMillions;
      // A state map must never inherit heat points from another state. Without
      // this guard, multi-state history can place NC bubbles over an open SC
      // map, making South Carolina's own animated points appear missing.
      final matchesSelectedState =
          selectedStateAbbreviation == null ||
          activity.state.toUpperCase() == selectedStateAbbreviation;
      final matchesGame =
          _filterState.game == LotteryGame.allGames ||
          activity.game == _filterState.game;
      final matchesDate =
          !activity.drawDate.isBefore(_filterState.dateRange.start) &&
          !activity.drawDate.isAfter(_filterState.dateRange.end);
      final matchesWinners =
          !_filterState.showWinnersOnly || activity.hasWinningActivity;
      final matchesFavorites =
          !_filterState.showFavoritesOnly || _isFavorite(activity);
      final matchesPrize =
          activity.prizeAmount >= _filterState.minimumPrize &&
          (_filterState.maximumPrize == null ||
              activity.prizeAmount <= _filterState.maximumPrize!);
      final matchesSouthCarolinaScratch =
          scratchFilter == null || scratchFilter.matches(activity);
      final matchesSouthCarolinaGame =
          southCarolinaFilter == null || southCarolinaFilter.matches(activity);
      final matchesSelectedStateGame =
          _selectedStateActivityGameName == null ||
          (activity.state == selectedStateAbbreviation &&
              _sameGameName(
                activity.gameName ?? activity.game.name,
                _selectedStateActivityGameName!,
              ));
      return matchesNationalScope &&
          matchesSelectedState &&
          matchesGame &&
          matchesDate &&
          matchesWinners &&
          matchesFavorites &&
          matchesPrize &&
          matchesSouthCarolinaScratch &&
          matchesSouthCarolinaGame &&
          matchesSelectedStateGame;
    }).toList();
  }

  /// Combines the visible records into one heat point per county. Because this
  /// happens after every map filter, prize range, game selection, and timeline
  /// position immediately produce a new county heat map.
  List<_CountyActivitySummary> _countyActivitySummaries(
    List<LotteryActivity> activity,
  ) {
    final grouped = <String, List<LotteryActivity>>{};

    for (final record in activity) {
      final countyKey = _normalizedCountyName(record.county);
      final key = '${record.state}|$countyKey';
      grouped.putIfAbsent(key, () => <LotteryActivity>[]).add(record);
    }

    return grouped.values
        .map(_CountyActivitySummary.fromActivity)
        .toList(growable: false);
  }

  String _normalizedCountyName(String county) => county
      .toLowerCase()
      .replaceFirst(RegExp(r'\s+county$'), '')
      .replaceAll(RegExp(r'[^a-z0-9]'), '');

  Color _countyHeatColor(int totalTickets, int highestCountyTotal) {
    if (highestCountyTotal <= 0) return const Color(0xFF1478FF);

    final intensity = totalTickets / highestCountyTotal;
    if (intensity >= 0.80) return const Color(0xFFEF4444);
    if (intensity >= 0.60) return const Color(0xFFF97316);
    if (intensity >= 0.40) return const Color(0xFFFACC15);
    if (intensity >= 0.20) return const Color(0xFF22C55E);
    return const Color(0xFF1478FF);
  }

  double _countyHeatRadius(int totalTickets, int highestCountyTotal) {
    // A 9-pixel starting radius made lower-volume state feeds look like tiny
    // colored dots beside NC's denser history. Use one shared, readable floor
    // for every state so the same heat styling is visible everywhere.
    if (highestCountyTotal <= 0) return 15;
    final intensity = totalTickets / highestCountyTotal;
    return 15 + 21 * math.sqrt(intensity.clamp(0.0, 1.0));
  }

  String _countyHeatKey(_CountyActivitySummary county) =>
      '${county.state.toUpperCase()}|${_normalizedCountyName(county.county)}';

  Map<String, int> _highestCountyTotalsByState(
    List<_CountyActivitySummary> countyActivity,
  ) {
    final totals = <String, int>{};
    for (final county in countyActivity) {
      final state = county.state.toUpperCase();
      totals[state] = math.max(totals[state] ?? 0, county.totalWinningTickets);
    }
    return totals;
  }

  int _highestCountyTotalFor(
    _CountyActivitySummary county,
    Map<String, int> totalsByState,
  ) => totalsByState[county.state.toUpperCase()] ?? 0;

  Map<String, Color> _countyHeatColorsFor(
    List<_CountyActivitySummary> countyActivity,
  ) {
    final totalsByState = _highestCountyTotalsByState(countyActivity);

    return <String, Color>{
      for (final county in countyActivity)
        _countyHeatKey(county): _countyHeatColor(
          county.totalWinningTickets,
          _highestCountyTotalFor(county, totalsByState),
        ),
    };
  }

  void _onMapFilterChanged(MapFilterState filterState) {
    final currentColors = _countyHeatColorsFor(
      _countyActivitySummaries(_visibleActivity()),
    );

    setState(() {
      _previousCountyHeatColors
        ..clear()
        ..addAll(currentColors);
      _filterState = filterState;
    });
    _restartHeatBubbleAnimation();
  }

  Color _animatedCountyHeatColor(
    _CountyActivitySummary county,
    Color currentColor,
  ) {
    final previousColor =
        _previousCountyHeatColors[_countyHeatKey(county)] ??
        currentColor.withValues(alpha: 0);
    final progress = Curves.easeOutCubic.transform(
      _heatBubbleAnimationController.value,
    );
    return Color.lerp(previousColor, currentColor, progress) ?? currentColor;
  }

  double _heatBubbleScale(int index) {
    // County entries are collected nationwide. Using their raw list index as
    // an animation delay meant entries after NC's large history (including SC
    // and GA) never progressed beyond their tiny starting dot. Recycle a
    // short stagger sequence so every bubble reaches its full bloom.
    final staggerDelay = (index % 12) * 0.025;
    final staggeredProgress =
        ((_heatBubbleAnimationController.value - staggerDelay) /
                (1 - staggerDelay))
            .clamp(0.0, 1.0);
    final bloom = Curves.easeOutBack.transform(staggeredProgress);
    final wiggle = staggeredProgress > 0.68
        ? math.sin((staggeredProgress - 0.68) * math.pi * 10) *
              (1 - staggeredProgress) *
              0.12
        : 0.0;
    return (0.05 + bloom * 0.95 + wiggle).clamp(0.05, 1.18);
  }

  void _restartHeatBubbleAnimation() {
    _heatBubbleAnimationController
      ..stop()
      ..forward(from: 0);
  }

  /// Replays heat bubbles once the state zoom settles. Starting the animation
  /// a second time here makes the bloom visible instead of letting it finish
  /// while the camera is still traveling into the selected state.
  void _replayHeatBubblesAfterStateZoom() {
    _restartHeatBubbleAnimation();
    Future<void>.delayed(const Duration(milliseconds: 620), () {
      if (mounted) _restartHeatBubbleAnimation();
    });
  }

  void _advanceHeatBubbleAnimation() {
    if (mounted) setState(() {});
  }

  void _focusCountyHeatBubble(_CountyActivitySummary countyActivity) {
    setState(() => _focusedHeatCountyKey = _countyHeatKey(countyActivity));
    _countyFocusAnimationController.forward(from: 0);
    unawaited(_showCountyActivityDetails(countyActivity));
  }

  void _advanceCountyFocusAnimation() {
    if (mounted) setState(() {});
  }

  double _countyFocusProgress() =>
      Curves.easeOutCubic.transform(_countyFocusAnimationController.value);

  void _advanceRetailerFocusAnimation() {
    if (mounted) setState(() {});
  }

  double _retailerFocusScale(SouthCarolinaRetailer retailer) {
    if (_focusedRetailerId != retailer.id) return 1;
    final progress = Curves.easeOutCubic.transform(
      _retailerFocusAnimationController.value,
    );
    return 1 + math.sin(progress * math.pi) * 0.22;
  }

  List<SouthCarolinaRetailer> _retailersForCounty(
    _CountyActivitySummary countyActivity,
  ) {
    final normalizedState = countyActivity.state.toLowerCase().replaceAll(
      RegExp(r'[^a-z]'),
      '',
    );
    if (normalizedState != 'southcarolina' && normalizedState != 'sc') {
      return const [];
    }

    final normalizedCounty = _normalizedCountyName(countyActivity.county);
    return _visibleSouthCarolinaRetailers()
        .where(
          (retailer) =>
              _normalizedCountyName(retailer.county) == normalizedCounty,
        )
        .toList(growable: false);
  }

  List<SouthCarolinaRetailer> _visibleSouthCarolinaRetailers() {
    final scratchFilter = SouthCarolinaScratchMapFilterService.selection.value;
    final drawFilter = SouthCarolinaLotteryMapFilterService.selection.value;

    return SouthCarolinaRetailerRepository.retailers
        .where((retailer) {
          final matchesTimeline =
              !retailer.claimDate.isBefore(_filterState.dateRange.start) &&
              !retailer.claimDate.isAfter(_filterState.dateRange.end);
          final retailerGame = _retailerGameType(retailer);
          final matchesMapGame =
              _filterState.game == LotteryGame.allGames ||
              retailerGame == _filterState.game;
          final matchesPrize =
              retailer.reportedPrizeAmount >= _filterState.minimumPrize &&
              (_filterState.maximumPrize == null ||
                  retailer.reportedPrizeAmount <= _filterState.maximumPrize!);
          final matchesScratch =
              scratchFilter == null ||
              ((scratchFilter.gameName == null ||
                      _sameGameName(
                        retailer.gameName,
                        scratchFilter.gameName!,
                      )) &&
                  retailer.reportedPrizeAmount >= scratchFilter.minimumPrize &&
                  retailer.reportedPrizeAmount <= scratchFilter.maximumPrize);
          final matchesDraw =
              drawFilter == null ||
              drawFilter.gameName == null ||
              _sameGameName(retailer.gameName, drawFilter.gameName!);

          return matchesTimeline &&
              matchesMapGame &&
              matchesPrize &&
              matchesScratch &&
              matchesDraw;
        })
        .toList(growable: false);
  }

  LotteryGame _retailerGameType(SouthCarolinaRetailer retailer) {
    final name = _normalizedGameName(retailer.gameName);
    if (name.contains('powerball')) return LotteryGame.powerball;
    if (name.contains('megamillions')) return LotteryGame.megaMillions;
    if (SouthCarolinaScratchCatalog.games.any(
      (game) => _sameGameName(game.name, retailer.gameName),
    )) {
      return LotteryGame.scratchOff;
    }
    if (name.contains('pick') ||
        name.contains('cashpop') ||
        name.contains('palmettocash')) {
      return LotteryGame.stateDraw;
    }
    // Retailer reports are dominated by Scratch-Off claims. Treat an
    // unfamiliar title as Scratch-Off so it cannot bypass a selected ticket
    // or the "All Scratch-Offs" view while new games are being added.
    return LotteryGame.scratchOff;
  }

  bool _sameGameName(String left, String right) =>
      _normalizedGameName(left) == _normalizedGameName(right);

  String _normalizedGameName(String value) =>
      value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '');

  String _activityKey(LotteryActivity activity) {
    return activity.id;
  }

  bool _isFavorite(LotteryActivity activity) {
    return _favoriteActivityKeys.contains(_activityKey(activity));
  }

  void _toggleFavorite(LotteryActivity activity) {
    final activityKey = _activityKey(activity);

    setState(() {
      if (_favoriteActivityKeys.contains(activityKey)) {
        _favoriteActivityKeys.remove(activityKey);
      } else {
        _favoriteActivityKeys.add(activityKey);
      }
    });

    _saveFavorites();
  }

  Future<void> _loadFavorites() async {
    final savedKeys = await _preferences.getStringList(
      _favoriteActivityStorageKey,
    );

    if (!mounted || savedKeys == null) {
      return;
    }

    setState(() {
      _favoriteActivityKeys
        ..clear()
        ..addAll(savedKeys);
    });
  }

  Future<void> _saveFavorites() async {
    await _preferences.setStringList(
      _favoriteActivityStorageKey,
      _favoriteActivityKeys.toList(),
    );
  }

  Color _activityColor(int winningTickets) {
    if (winningTickets >= 100) return const Color(0xFFE53935);
    if (winningTickets >= 50) return const Color(0xFFFF9800);
    if (winningTickets >= 20) return const Color(0xFFFFD600);
    if (winningTickets >= 5) return const Color(0xFF2CC36B);
    return const Color(0xFF1478FF);
  }

  LatLng _labelPosition(List<LatLng> points) {
    var minLatitude = points.first.latitude;
    var maxLatitude = points.first.latitude;
    var minLongitude = points.first.longitude;
    var maxLongitude = points.first.longitude;

    for (final point in points.skip(1)) {
      minLatitude = point.latitude < minLatitude ? point.latitude : minLatitude;
      maxLatitude = point.latitude > maxLatitude ? point.latitude : maxLatitude;
      minLongitude = point.longitude < minLongitude
          ? point.longitude
          : minLongitude;
      maxLongitude = point.longitude > maxLongitude
          ? point.longitude
          : maxLongitude;
    }

    return LatLng(
      (minLatitude + maxLatitude) / 2,
      (minLongitude + maxLongitude) / 2,
    );
  }

  List<Marker> _buildStateLabels(List<_StateShape> stateShapes) {
    final labeledStates = <String>{};
    final labels = <Marker>[];

    for (final shape in stateShapes) {
      if (!labeledStates.add(shape.name) || shape.points.isEmpty) {
        continue;
      }

      final state = StateNavigationService.getStateByName(shape.name);

      if (state == null) {
        continue;
      }

      labels.add(
        Marker(
          point: shape.name == 'Alaska'
              ? _alaskaCenter
              : _labelPosition(shape.points),
          width: 34,
          height: 22,
          alignment: Alignment.center,
          child: IgnorePointer(
            child: Text(
              state.abbreviation,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                shadows: [Shadow(color: Colors.black, blurRadius: 5)],
              ),
            ),
          ),
        ),
      );
    }

    return labels;
  }

  Marker _buildRetailerMarker(SouthCarolinaRetailer retailer) {
    final isFocused = _focusedRetailerId == retailer.id;
    final focusScale = _retailerFocusScale(retailer);

    return Marker(
      point: retailer.location,
      width: 62,
      height: 62,
      alignment: Alignment.center,
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: GestureDetector(
          onTap: () => _showRetailerDetails(retailer),
          child: Tooltip(
            message: '${retailer.name}\n${retailer.city}, SC',
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (isFocused)
                  Transform.scale(
                    scale: 1 + focusScale * 0.55,
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: const Color(0xFF38BDF8).withValues(
                            alpha:
                                0.72 *
                                (1 - _retailerFocusAnimationController.value),
                          ),
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                Transform.scale(
                  scale: focusScale,
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF102638),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: const Color(0xFF38BDF8),
                        width: 2,
                      ),
                      boxShadow: const [
                        BoxShadow(color: Colors.black54, blurRadius: 8),
                      ],
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFF93C5FD),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<Marker> _buildCountyLabels(List<_CountyShape> counties) {
    final labeledCountyIds = <String>{};
    final labels = <Marker>[];

    for (final county in counties) {
      final isHighlighted =
          county.id == _hoveredCountyId || county.id == _selectedCountyId;

      if (!labeledCountyIds.add(county.id) || county.points.isEmpty) {
        continue;
      }

      labels.add(
        Marker(
          point: _labelPosition(county.points),
          width: 130,
          height: 22,
          alignment: Alignment.center,
          child: IgnorePointer(
            child: Text(
              county.name,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: isHighlighted ? const Color(0xFFFFD600) : Colors.white,
                fontSize: isHighlighted ? 12 : 10,
                fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w600,
                shadows: const [Shadow(color: Colors.black, blurRadius: 5)],
              ),
            ),
          ),
        ),
      );
    }

    return labels;
  }

  Future<void> _showRetailerDetails(SouthCarolinaRetailer retailer) async {
    _focusRetailer(retailer);
    final retailerFavorite = FavoritePlace(
      key: 'retailer:${retailer.id}',
      title: retailer.name,
      subtitle: '${retailer.city}, SC · ${retailer.county} County',
      kind: FavoritePlaceKind.retailer,
      stateName: 'South Carolina',
      retailerId: retailer.id,
    );
    final formattedDate = MaterialLocalizations.of(
      context,
    ).formatMediumDate(retailer.claimDate);
    final placementNote = retailer.cityLevelPlacement
        ? 'City-level placement: this pin represents the retailer city until the exact store address is verified and geocoded.'
        : 'County heat-point placement: this pin is centered on the matching heat-map county while exact store-address geocoding is added.';

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B1D2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  IconButton(
                    tooltip: 'Back to county map',
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      _returnToCountyFromRetailer();
                    },
                    icon: const Icon(Icons.arrow_back_rounded),
                    color: const Color(0xFF93C5FD),
                  ),
                  const SizedBox(width: 4),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: const Color(0x261478FF),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: const Color(0xFF38BDF8)),
                    ),
                    child: const Icon(
                      Icons.storefront_rounded,
                      color: Color(0xFF93C5FD),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          retailer.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          '${retailer.city}, SC · ${retailer.county} County',
                          style: const TextStyle(color: Color(0xFF93C5FD)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                retailer.address,
                style: const TextStyle(color: Colors.white70, height: 1.35),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _activityInfoCard(
                      label: 'REPORTED CLAIM',
                      value: retailer.formattedPrize,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _activityInfoCard(
                      label: 'CLAIM DATE',
                      value: formattedDate,
                      color: const Color(0xFF1478FF),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _activityInfoCard(
                label: 'GAME',
                value: retailer.gameName,
                color: const Color(0xFFFACC15),
              ),
              const SizedBox(height: 12),
              _dataSourceCard(
                heading: 'RETAILER CLAIM SOURCE',
                source: SouthCarolinaRetailerRepository.sourceLabel,
                updatedAt: SouthCarolinaRetailerRepository.updatedAt,
                color: const Color(0xFF22C55E),
              ),
              const SizedBox(height: 12),
              ValueListenableBuilder<List<FavoritePlace>>(
                valueListenable: FavoritePlacesService.places,
                builder: (context, favorites, _) {
                  final isFavorite = favorites.any(
                    (place) => place.key == retailerFavorite.key,
                  );
                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final saved = await FavoritePlacesService.toggle(
                          retailerFavorite,
                        );
                        if (!sheetContext.mounted) return;
                        ScaffoldMessenger.of(sheetContext).showSnackBar(
                          SnackBar(
                            content: Text(
                              saved
                                  ? '${retailer.name} saved to Favorites.'
                                  : '${retailer.name} removed from Favorites.',
                            ),
                          ),
                        );
                      },
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                      label: Text(
                        isFavorite
                            ? 'Remove retailer from Favorites'
                            : 'Save retailer to Favorites',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isFavorite
                            ? const Color(0xFFE94B6A)
                            : const Color(0xFF93C5FD),
                        side: BorderSide(
                          color: isFavorite
                              ? const Color(0xFFE94B6A)
                              : const Color(0xFF355066),
                        ),
                        minimumSize: const Size.fromHeight(46),
                      ),
                    ),
                  );
                },
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: _openSouthCarolinaWinnersReport,
                  icon: const Icon(Icons.open_in_new_rounded, size: 17),
                  label: const Text('Open official SC Winners Report'),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF93C5FD),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _openRetailerDirections(retailer),
                  icon: const Icon(Icons.directions_rounded),
                  label: const Text('Get directions'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF1478FF),
                    foregroundColor: Colors.white,
                    minimumSize: const Size.fromHeight(50),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0x331478FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFF355066)),
                ),
                child: Text(
                  '$placementNote It is separate from the county heat index.',
                  style: const TextStyle(
                    color: Color(0xFFBFDBFE),
                    fontSize: 12,
                    height: 1.35,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _focusRetailer(SouthCarolinaRetailer retailer) {
    if (!SouthCarolinaRetailerMapService.isVisible.value) {
      SouthCarolinaRetailerMapService.show();
    }

    final matchingCounties = _countyShapes
        .where(
          (county) =>
              county.stateFips == '45' &&
              _normalizedCountyName(county.name) ==
                  _normalizedCountyName(retailer.county),
        )
        .toList(growable: false);

    setState(() {
      _focusedRetailerId = retailer.id;
      _selectedStateName = 'South Carolina';
      _selectedCountyId = matchingCounties.isEmpty
          ? null
          : matchingCounties.first.id;
      _hoveredCountyId = null;
    });
    _retailerFocusAnimationController.forward(from: 0);
    _animateMapTo(retailer.location, 14.5);
  }

  /// Centers a verified activity record that names its ticket retailer. This
  /// lets retailer favorites work for every state without representing a city
  /// centroid as an exact retailer pin.
  void _focusActivityRetailer(LotteryActivity activity) {
    final state = allStates.where(
      (candidate) => candidate.abbreviation == activity.state,
    );
    final stateName = state.isEmpty ? null : state.first.name;
    if (stateName == null) return;
    final stateFips = _stateFipsByName[stateName];
    final matchingCounties = _countyShapes.where(
      (county) =>
          county.stateFips == stateFips &&
          _normalizedCountyName(county.name) ==
              _normalizedCountyName(activity.county),
    );
    setState(() {
      _selectedStateName = stateName;
      _selectedCountyId = matchingCounties.isEmpty
          ? null
          : matchingCounties.first.id;
      _hoveredCountyId = null;
      _focusedHeatCountyKey = null;
      _focusedRetailerId = null;
    });
    _animateMapTo(activity.location, 14.5);
  }

  void _returnToCountyFromRetailer() {
    final countyId = _selectedCountyId;
    setState(() {
      _focusedRetailerId = null;
      _focusedHeatCountyKey = null;
    });

    if (countyId != null) {
      _focusCountyById(countyId);
      return;
    }

    _focusStateByName('South Carolina');
  }

  Future<void> _openRetailerDirections(SouthCarolinaRetailer retailer) async {
    final destination = '${retailer.address}, ${retailer.city}, SC';
    final useAppleMaps =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final directionsUri = useAppleMaps
        ? Uri.https('maps.apple.com', '/', {
            'daddr': destination,
            'dirflg': 'd',
          })
        : Uri.https('www.google.com', '/maps/dir/', {
            'api': '1',
            'destination': destination,
          });
    final opened = await launchUrl(
      directionsUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open directions.')),
      );
    }
  }

  Future<void> _openActivityRetailerDirections(LotteryActivity activity) async {
    final destination =
        activity.retailerAddress ??
        '${activity.location.latitude},${activity.location.longitude}';
    final useAppleMaps =
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
    final directionsUri = useAppleMaps
        ? Uri.https('maps.apple.com', '/', {
            'daddr': destination,
            'dirflg': 'd',
          })
        : Uri.https('www.google.com', '/maps/dir/', {
            'api': '1',
            'destination': destination,
          });
    final opened = await launchUrl(
      directionsUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open directions.')),
      );
    }
  }

  Future<void> _openSouthCarolinaWinnersReport() async {
    final opened = await launchUrl(
      Uri.parse(SouthCarolinaRetailerRepository.winnersReportUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the official SC report.')),
      );
    }
  }

  Future<void> _openOfficialScratchCatalog(StateLotterySource? source) async {
    if (source == null || source.resources.isEmpty) return;

    final resource = source.resources.firstWhere((candidate) {
      final label = '${candidate.title} ${candidate.subtitle}'.toLowerCase();
      return label.contains('scratch') || label.contains('instant');
    }, orElse: () => source.resources.first);
    final opened = await launchUrl(
      Uri.parse(resource.url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not open the ${source.stateName} catalog.'),
        ),
      );
    }
  }

  Future<void> _openActivitySource(String url) async {
    final opened = await launchUrl(
      Uri.parse(url),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the official source.')),
      );
    }
  }

  String _formattedDataUpdatedAt(DateTime? updatedAt) {
    if (updatedAt == null) return 'Timestamp not supplied by this data source.';

    const months = <String>[
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
    final local = updatedAt.toLocal();
    final hour = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour < 12 ? 'AM' : 'PM';
    return 'Last updated ${months[local.month - 1]} ${local.day}, '
        '${local.year} · $hour:$minute $period';
  }

  Widget _dataSourceCard({
    required String heading,
    required String source,
    required DateTime? updatedAt,
    required Color color,
  }) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: color.withValues(alpha: 0.09),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color.withValues(alpha: 0.55)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          heading,
          style: TextStyle(
            color: color,
            fontSize: 11,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.7,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          source,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            height: 1.25,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          _formattedDataUpdatedAt(updatedAt),
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
      ],
    ),
  );

  Future<void> _showActivityDetails(LotteryActivity activity) async {
    final activityColor = _activityColor(activity.winningTickets);
    final isFavorite = _isFavorite(activity);
    final retailerFavorite = activity.retailerName == null
        ? null
        : FavoritePlace(
            key: 'retailer:${activity.id}',
            title: activity.retailerName!,
            subtitle:
                '${activity.retailerAddress ?? activity.city} · ${activity.state}',
            kind: FavoritePlaceKind.retailer,
            stateName:
                StateNavigationService.getStateByAbbreviation(
                  activity.state,
                )?.name ??
                activity.state,
            retailerId: activity.id,
          );
    final formattedDate = MaterialLocalizations.of(
      context,
    ).formatMediumDate(activity.drawDate);

    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF0B1D2C),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (sheetContext) {
        return SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 16, 22, 30),
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
                const SizedBox(height: 20),
                Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: activityColor.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(color: activityColor, width: 2),
                      ),
                      child: Icon(
                        Icons.location_on_rounded,
                        color: activityColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${activity.city}, ${activity.state}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          Text(
                            activity.gameName ?? activity.game.label,
                            style: const TextStyle(
                              color: Color(0xFF1478FF),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (isFavorite)
                      const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFFE94B6A),
                      ),
                  ],
                ),
                const SizedBox(height: 12),
                if (LotteryActivityRepository.isSampleData)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0x332196F3),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFF60A5FA).withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Text(
                      'Sample activity record — official lottery data will be added by state.',
                      style: TextStyle(
                        color: Color(0xFFBFDBFE),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                if (activity.isHistorical) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0x33FACC15),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: const Color(0xFFFACC15).withValues(alpha: 0.45),
                      ),
                    ),
                    child: const Text(
                      'Historical archive record — coverage is partial and this individual entry links to its supporting official source.',
                      style: TextStyle(
                        color: Color(0xFFFEF3C7),
                        fontSize: 12,
                        height: 1.3,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                Row(
                  children: [
                    Expanded(
                      child: _activityInfoCard(
                        label: 'WINNING TICKETS',
                        value: '${activity.winningTickets}',
                        color: activityColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _activityInfoCard(
                        label: 'DRAW DATE',
                        value: formattedDate,
                        color: const Color(0xFF1478FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _activityInfoCard(
                  label: 'TOP PRIZE AT THIS LOCATION',
                  value: activity.formattedPrizeAmount,
                  color: const Color(0xFF22C55E),
                ),
                if (activity.retailerName != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFF102638),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: const Color(0xFF355066)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.storefront_rounded,
                          color: Color(0xFF93C5FD),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'REPORTED TICKET RETAILER',
                                style: TextStyle(
                                  color: Color(0xFF93C5FD),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.7,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                activity.retailerName!,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              if (activity.retailerAddress != null) ...[
                                const SizedBox(height: 2),
                                Text(
                                  activity.retailerAddress!,
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    height: 1.3,
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (activity.retailerAddress != null)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () =>
                            _openActivityRetailerDirections(activity),
                        icon: const Icon(Icons.directions_rounded, size: 17),
                        label: const Text('Get directions to retailer'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF93C5FD),
                        ),
                      ),
                    ),
                  if (retailerFavorite != null)
                    ValueListenableBuilder<List<FavoritePlace>>(
                      valueListenable: FavoritePlacesService.places,
                      builder: (context, favorites, _) {
                        final saved = favorites.any(
                          (place) => place.key == retailerFavorite.key,
                        );
                        return Align(
                          alignment: Alignment.centerLeft,
                          child: TextButton.icon(
                            onPressed: () async {
                              final isSaved =
                                  await FavoritePlacesService.toggle(
                                    retailerFavorite,
                                  );
                              if (!sheetContext.mounted) return;
                              ScaffoldMessenger.of(sheetContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    isSaved
                                        ? '${retailerFavorite.title} saved to favorite retailers.'
                                        : '${retailerFavorite.title} removed from favorite retailers.',
                                  ),
                                ),
                              );
                            },
                            icon: Icon(
                              saved
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              size: 17,
                            ),
                            label: Text(
                              saved
                                  ? 'Remove retailer from Favorites'
                                  : 'Save retailer to Favorites',
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: saved
                                  ? const Color(0xFFE94B6A)
                                  : const Color(0xFF93C5FD),
                            ),
                          ),
                        );
                      },
                    ),
                ],
                const SizedBox(height: 12),
                _dataSourceCard(
                  heading: activity.isHistorical
                      ? 'HISTORICAL RECORD SOURCE'
                      : 'ACTIVITY DATA SOURCE',
                  source:
                      activity.sourceLabel ??
                      LotteryActivityRepository.activitySourceLabel,
                  updatedAt: LotteryActivityRepository.activityUpdatedAt,
                  color: const Color(0xFF60A5FA),
                ),
                if (activity.sourceUrl != null)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: () => _openActivitySource(activity.sourceUrl!),
                      icon: const Icon(Icons.open_in_new_rounded, size: 17),
                      label: Text(
                        activity.sourceLabel ??
                            'Open supporting official source',
                      ),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF93C5FD),
                      ),
                    ),
                  )
                else if (activity.state == 'SC')
                  Align(
                    alignment: Alignment.centerLeft,
                    child: TextButton.icon(
                      onPressed: _openSouthCarolinaWinnersReport,
                      icon: const Icon(Icons.open_in_new_rounded, size: 17),
                      label: const Text('Open official SC Winners Report'),
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF93C5FD),
                      ),
                    ),
                  ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _toggleFavorite(activity);
                      Navigator.of(sheetContext).pop();

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            isFavorite
                                ? '${activity.city} removed from favorites.'
                                : '${activity.city} added to favorites.',
                          ),
                        ),
                      );
                    },
                    icon: Icon(
                      isFavorite
                          ? Icons.favorite_rounded
                          : Icons.favorite_border_rounded,
                    ),
                    label: Text(
                      isFavorite ? 'Remove from Favorites' : 'Add to Favorites',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFE94B6A),
                      side: const BorderSide(color: Color(0xFFE94B6A)),
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () {
                      Navigator.of(sheetContext).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            '${activity.city} lottery details are coming soon.',
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.analytics_outlined),
                    label: const Text('View Lottery Details'),
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF1478FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(50),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showCountyActivityDetails(
    _CountyActivitySummary countyActivity,
  ) async {
    _animateMapTo(countyActivity.location, 9.4);
    final color = _countyHeatColor(
      countyActivity.totalWinningTickets,
      countyActivity.totalWinningTickets,
    );
    final retailers = _retailersForCounty(countyActivity);

    // The macOS bridge must release scroll handling while a long county sheet
    // is open; otherwise Magic Mouse wheel movement is routed to the map.
    await _magicMouseChannel.invokeMethod<void>('setMapActive', false);
    if (!mounted) return;
    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF0B1D2C),
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.62,
            minChildSize: 0.36,
            maxChildSize: 0.90,
            builder: (context, scrollController) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Container(
                      width: 46,
                      height: 46,
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.16),
                        shape: BoxShape.circle,
                        border: Border.all(color: color, width: 2),
                      ),
                      child: Icon(
                        Icons.local_fire_department_rounded,
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${countyActivity.county}, ${countyActivity.state}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const Text(
                            'Filtered county heat activity',
                            style: TextStyle(color: Color(0xFF93C5FD)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: _activityInfoCard(
                        label: 'QUALIFYING RECORDS',
                        value: '${countyActivity.records.length}',
                        color: color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _activityInfoCard(
                        label: 'WINNING TICKETS',
                        value: '${countyActivity.totalWinningTickets}',
                        color: const Color(0xFF1478FF),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                _activityInfoCard(
                  label: 'HIGHEST QUALIFYING PRIZE',
                  value: countyActivity.highestPrize.formattedPrizeAmount,
                  color: const Color(0xFF22C55E),
                ),
                const SizedBox(height: 12),
                _dataSourceCard(
                  heading: 'HEAT-POINT ACTIVITY SOURCE',
                  source: LotteryActivityRepository.activitySourceLabel,
                  updatedAt: LotteryActivityRepository.activityUpdatedAt,
                  color: const Color(0xFF60A5FA),
                ),
                if (retailers.isNotEmpty) ...[
                  const SizedBox(height: 22),
                  Text(
                    'RETAILER CLAIM LOCATIONS (${retailers.length})',
                    style: const TextStyle(
                      color: Color(0xFF93C5FD),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Recent official retailer claims in this county. Heat-linked pins stay county-centered until exact store geocoding is added.',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  ...retailers
                      .take(2)
                      .map(
                        (retailer) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          leading: const Icon(
                            Icons.storefront_rounded,
                            color: Color(0xFF93C5FD),
                          ),
                          title: Text(
                            retailer.name,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${retailer.city} · ${retailer.gameName} · ${retailer.formattedPrize}',
                            style: const TextStyle(color: Colors.white60),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right_rounded,
                            color: Colors.white38,
                          ),
                          onTap: () {
                            Navigator.of(sheetContext).pop();
                            _showRetailerDetails(retailer);
                          },
                        ),
                      ),
                  if (retailers.length > 2)
                    _expandableCountyList(
                      label: 'View all ${retailers.length} retailer locations',
                      children: retailers
                          .skip(2)
                          .map(
                            (retailer) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const Icon(
                                Icons.storefront_rounded,
                                color: Color(0xFF93C5FD),
                              ),
                              title: Text(
                                retailer.name,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              subtitle: Text(
                                '${retailer.city} · ${retailer.gameName} · ${retailer.formattedPrize}',
                                style: const TextStyle(color: Colors.white60),
                              ),
                              trailing: const Icon(
                                Icons.chevron_right_rounded,
                                color: Colors.white38,
                              ),
                              onTap: () {
                                Navigator.of(sheetContext).pop();
                                _showRetailerDetails(retailer);
                              },
                            ),
                          )
                          .toList(),
                    ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.of(sheetContext).pop();
                        SouthCarolinaRetailerMapService.show();
                      },
                      icon: const Icon(Icons.storefront_outlined),
                      label: const Text('Show retailer pins on map'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFF93C5FD),
                        side: const BorderSide(color: Color(0xFF355066)),
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 22),
                const Text(
                  'RECORDS IN THIS HEAT POINT',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                ...countyActivity.records
                    .take(2)
                    .map(
                      (activity) => ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          activity.game.icon,
                          color: const Color(0xFF60A5FA),
                        ),
                        title: Text(
                          activity.gameName ?? activity.game.label,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          '${activity.city} · ${activity.formattedPrizeAmount}',
                          style: const TextStyle(color: Colors.white60),
                        ),
                        trailing: Text(
                          '${activity.winningTickets}',
                          style: const TextStyle(
                            color: Color(0xFF93C5FD),
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onTap: () {
                          Navigator.of(sheetContext).pop();
                          _showActivityDetails(activity);
                        },
                      ),
                    ),
                if (countyActivity.records.length > 2)
                  _expandableCountyList(
                    label:
                        'View all ${countyActivity.records.length} qualifying records',
                    children: countyActivity.records
                        .skip(2)
                        .map(
                          (activity) => ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              activity.game.icon,
                              color: const Color(0xFF60A5FA),
                            ),
                            title: Text(
                              activity.gameName ?? activity.game.label,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${activity.city} · ${activity.formattedPrizeAmount}',
                              style: const TextStyle(color: Colors.white60),
                            ),
                            trailing: Text(
                              '${activity.winningTickets}',
                              style: const TextStyle(
                                color: Color(0xFF93C5FD),
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            onTap: () {
                              Navigator.of(sheetContext).pop();
                              _showActivityDetails(activity);
                            },
                          ),
                        )
                        .toList(),
                  ),
              ],
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        await _magicMouseChannel.invokeMethod<void>('setMapActive', true);
      }
    }
  }

  Widget _expandableCountyList({
    required String label,
    required List<Widget> children,
  }) {
    return Container(
      margin: const EdgeInsets.only(top: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF102638),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF355066)),
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
          iconColor: const Color(0xFF93C5FD),
          collapsedIconColor: const Color(0xFF93C5FD),
          title: Text(
            label,
            style: const TextStyle(
              color: Color(0xFFBFDBFE),
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          children: children,
        ),
      ),
    );
  }

  Widget _activityInfoCard({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF102638),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.45)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Colors.white60,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: color,
              fontSize: 17,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  void _updateHoveredState() {
    final hitResult = _stateHitNotifier.value;

    final nextHoveredState = hitResult == null || hitResult.hitValues.isEmpty
        ? null
        : hitResult.hitValues.last;

    if (_hoveredStateName == nextHoveredState) {
      return;
    }

    setState(() {
      _hoveredStateName = nextHoveredState;
    });
  }

  /// Keeps the national-map hover effect reliable even when map overlays such
  /// as heat bubbles or labels are above the polygon paint layer. FlutterMap's
  /// layer hit notifier still drives taps; this direct pointer check is only
  /// responsible for the visual hover state.
  void _updateHoveredStateFromMapPoint(LatLng point) {
    if (_selectedStateName != null) return;

    String? nextHoveredState;
    for (final shape in _stateShapes.reversed) {
      if (_pointIsInsideStateShape(point, shape)) {
        nextHoveredState = shape.name;
        break;
      }
    }

    if (_hoveredStateName == nextHoveredState) return;
    setState(() => _hoveredStateName = nextHoveredState);
  }

  bool _pointIsInsideStateShape(LatLng point, _StateShape shape) {
    if (!_pointIsInsideRing(point, shape.points)) return false;
    return !shape.holePoints.any((ring) => _pointIsInsideRing(point, ring));
  }

  bool _pointIsInsideRing(LatLng point, List<LatLng> ring) {
    if (ring.length < 3) return false;

    final latitude = point.latitude;
    final longitude = point.longitude;
    var isInside = false;

    for (
      var current = 0, previous = ring.length - 1;
      current < ring.length;
      previous = current++
    ) {
      final currentPoint = ring[current];
      final previousPoint = ring[previous];
      final crossesLatitude =
          (currentPoint.latitude > latitude) !=
          (previousPoint.latitude > latitude);
      if (!crossesLatitude) continue;

      final longitudeAtLatitude =
          (previousPoint.longitude - currentPoint.longitude) *
              (latitude - currentPoint.latitude) /
              (previousPoint.latitude - currentPoint.latitude) +
          currentPoint.longitude;
      if (longitude < longitudeAtLatitude) isInside = !isInside;
    }

    return isInside;
  }

  void _updateHoveredCounty() {
    final hitResult = _countyHitNotifier.value;

    final nextHoveredCounty = hitResult == null || hitResult.hitValues.isEmpty
        ? null
        : hitResult.hitValues.last;

    if (_hoveredCountyId == nextHoveredCounty) {
      return;
    }

    setState(() {
      _hoveredCountyId = nextHoveredCounty;
    });
  }

  void _selectState() {
    final hitResult = _stateHitNotifier.value;

    if (hitResult == null || hitResult.hitValues.isEmpty) {
      return;
    }

    _focusStateByName(hitResult.hitValues.last);
  }

  EdgeInsets _stateCameraPadding(String? stateName) {
    if (stateName == 'South Carolina' || stateName == 'North Carolina') {
      // These state views use the compact top toolbar instead of the wide
      // right-side panel, so their maps can remain centered and closer.
      return const EdgeInsets.symmetric(horizontal: 36, vertical: 96);
    }

    return const EdgeInsets.fromLTRB(48, 48, 360, 48);
  }

  void _focusStateByName(String stateName) {
    // South Carolina's ticket-specific pickers must not suppress unrelated
    // state activity after the person leaves SC.
    if (stateName != 'South Carolina') {
      SouthCarolinaScratchMapFilterService.clear();
      SouthCarolinaLotteryMapFilterService.clear();
    }

    if (stateName == 'Alaska') {
      setState(() {
        _selectedStateName = stateName;
        _selectedCountyId = null;
        _hoveredCountyId = null;
        _selectedStateActivityGameName = null;
        _showStateGames = false;
      });
      _replayHeatBubblesAfterStateZoom();

      _animateMapTo(_alaskaCenter, 4.4);
      return;
    }

    final statePoints = _stateShapes
        .where((shape) => shape.name == stateName)
        .expand((shape) => shape.points)
        .toList();

    if (statePoints.isEmpty) {
      return;
    }

    setState(() {
      _selectedStateName = stateName;
      _selectedCountyId = null;
      _hoveredCountyId = null;
      _selectedStateActivityGameName = null;
      _showStateGames = false;
    });
    _replayHeatBubblesAfterStateZoom();

    _animateCameraFit(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(statePoints),
        padding: _stateCameraPadding(stateName),
      ),
    );
  }

  void _selectCounty() {
    final hitResult = _countyHitNotifier.value;

    if (hitResult == null || hitResult.hitValues.isEmpty) {
      return;
    }

    _focusCountyById(hitResult.hitValues.last);
  }

  void _focusCountyById(String countyId) {
    final countyPoints = _countyShapes
        .where((county) => county.id == countyId)
        .expand((county) => county.points)
        .toList();

    if (countyPoints.isEmpty) {
      return;
    }

    setState(() {
      _selectedCountyId = countyId;
    });

    _animateCameraFit(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(countyPoints),
        padding: _stateCameraPadding(_selectedStateName),
      ),
    );
  }

  Future<void> _openCountyPicker() async {
    final stateName = _selectedStateName;
    final stateFips = stateName == null ? null : _stateFipsByName[stateName];
    if (stateName == null || stateFips == null) return;

    final counties =
        _countyShapes.where((county) => county.stateFips == stateFips).toList()
          ..sort((left, right) => left.name.compareTo(right.name));

    if (counties.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'County boundaries are not available for $stateName yet.',
          ),
        ),
      );
      return;
    }

    final stateAbbreviation = StateNavigationService.getStateByName(
      stateName,
    )?.abbreviation.toUpperCase();
    final filteredRecordsByCounty = <String, int>{};
    for (final activity in _visibleActivity()) {
      if (activity.state != stateAbbreviation) continue;
      final countyKey = _normalizedCountyName(activity.county);
      filteredRecordsByCounty.update(
        countyKey,
        (count) => count + 1,
        ifAbsent: () => 1,
      );
    }

    final retailersByCounty = <String, int>{};
    if (stateName == 'South Carolina') {
      for (final retailer in _visibleSouthCarolinaRetailers()) {
        final countyKey = _normalizedCountyName(retailer.county);
        retailersByCounty.update(
          countyKey,
          (count) => count + 1,
          ifAbsent: () => 1,
        );
      }
    }

    await _magicMouseChannel.invokeMethod<void>('setMapActive', false);
    if (!mounted) return;

    String? selectedCountyId;
    var countyQuery = '';
    try {
      selectedCountyId = await showModalBottomSheet<String>(
        context: context,
        backgroundColor: const Color(0xFF0B1D2C),
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => StatefulBuilder(
          builder: (context, setSheetState) {
            final normalizedQuery = countyQuery.trim().toLowerCase();
            final matchingCounties = normalizedQuery.isEmpty
                ? counties
                : counties
                      .where(
                        (county) =>
                            county.name.toLowerCase().contains(normalizedQuery),
                      )
                      .toList(growable: false);

            return SafeArea(
              child: DraggableScrollableSheet(
                expand: false,
                initialChildSize: 0.58,
                minChildSize: 0.35,
                maxChildSize: 0.92,
                builder: (context, scrollController) => ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.fromLTRB(20, 10, 20, 30),
                  children: [
                    Center(
                      child: Container(
                        width: 42,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.white24,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Text(
                      '$stateName Counties',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${counties.length} county boundaries · Record totals reflect the current map filters.',
                      style: const TextStyle(color: Colors.white60),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      autofocus: false,
                      onChanged: (value) =>
                          setSheetState(() => countyQuery = value),
                      style: const TextStyle(color: Colors.white),
                      cursorColor: const Color(0xFF60A5FA),
                      decoration: InputDecoration(
                        hintText: 'Search counties',
                        hintStyle: const TextStyle(color: Colors.white54),
                        prefixIcon: const Icon(
                          Icons.search_rounded,
                          color: Color(0xFF93C5FD),
                        ),
                        suffixIcon: countyQuery.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear county search',
                                onPressed: () =>
                                    setSheetState(() => countyQuery = ''),
                                icon: const Icon(
                                  Icons.close_rounded,
                                  color: Colors.white70,
                                ),
                              ),
                        filled: true,
                        fillColor: const Color(0xFF102638),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF355066),
                          ),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF355066),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFF60A5FA),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (normalizedQuery.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 4),
                        child: Text(
                          '${matchingCounties.length} matching ${matchingCounties.length == 1 ? 'county' : 'counties'}',
                          style: const TextStyle(
                            color: Color(0xFF93C5FD),
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    if (matchingCounties.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 28),
                        child: Center(
                          child: Text(
                            'No counties match that search.',
                            style: TextStyle(color: Colors.white60),
                          ),
                        ),
                      ),
                    ...matchingCounties.map((county) {
                      final countyKey = _normalizedCountyName(county.name);
                      final recordCount =
                          filteredRecordsByCounty[countyKey] ?? 0;
                      final retailerCount = retailersByCounty[countyKey] ?? 0;
                      final hasActivity = recordCount > 0;
                      final retailerText = retailerCount == 0
                          ? null
                          : '$retailerCount ${retailerCount == 1 ? 'reported retailer' : 'reported retailers'}';
                      final subtitle = hasActivity
                          ? '$recordCount ${recordCount == 1 ? 'qualifying record' : 'qualifying records'}${retailerText == null ? '' : ' · $retailerText'}'
                          : retailerText == null
                          ? 'No qualifying records with the current filters'
                          : '$retailerText · no qualifying records with the current filters';

                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 4,
                        ),
                        leading: Icon(
                          hasActivity
                              ? Icons.local_fire_department_rounded
                              : Icons.map_outlined,
                          color: hasActivity
                              ? const Color(0xFFFBBF24)
                              : const Color(0xFF60A5FA),
                        ),
                        title: Text(
                          county.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        subtitle: Text(
                          subtitle,
                          style: const TextStyle(color: Colors.white60),
                        ),
                        trailing: const Icon(
                          Icons.chevron_right_rounded,
                          color: Colors.white38,
                        ),
                        onTap: () => Navigator.of(sheetContext).pop(county.id),
                      );
                    }),
                  ],
                ),
              ),
            );
          },
        ),
      );
    } finally {
      if (mounted) {
        await _magicMouseChannel.invokeMethod<void>('setMapActive', true);
      }
    }

    if (mounted && selectedCountyId != null) {
      _focusCountyById(selectedCountyId);
    }
  }

  void _navigateToSearchResult(MapSearchResult result) {
    final stateName = result.stateName;

    if (stateName == null) {
      setState(() {
        _selectedStateName = null;
        _selectedCountyId = null;
        _hoveredStateName = null;
        _hoveredCountyId = null;
      });
      _mapController.move(result.location, result.zoom);
      return;
    }

    setState(() {
      _selectedStateName = stateName;
      _selectedCountyId = null;
      _hoveredCountyId = null;
    });

    if (stateName == 'Alaska') {
      _mapController.move(_alaskaCenter, 4.4);
      return;
    }

    final points = _stateShapes
        .where((shape) => shape.name == stateName)
        .expand((shape) => shape.points)
        .toList();

    if (points.isEmpty) {
      _mapController.move(result.location, result.zoom);
      return;
    }

    _mapController.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: _stateCameraPadding(stateName),
      ),
    );
  }

  void _animateCameraFit(CameraFit fit) {
    final targetCamera = fit.fit(_mapController.camera);
    _animateMapTo(targetCamera.center, targetCamera.zoom);
  }

  void _animateMapTo(
    LatLng targetCenter,
    double targetZoom, {
    Duration duration = const Duration(milliseconds: 560),
  }) {
    final camera = _mapController.camera;
    _cameraAnimationStart = camera.center;
    _cameraAnimationEnd = targetCenter;
    _cameraAnimationStartZoom = camera.zoom;
    _cameraAnimationEndZoom = targetZoom.clamp(_minZoom, _maxZoom).toDouble();

    _cameraAnimationController
      ..stop()
      ..duration = duration
      ..forward(from: 0);
  }

  void _advanceCameraAnimation() {
    final start = _cameraAnimationStart;
    final end = _cameraAnimationEnd;
    if (start == null || end == null) return;

    final progress = Curves.easeInOutCubic.transform(
      _cameraAnimationController.value,
    );
    final center = LatLng(
      start.latitude + (end.latitude - start.latitude) * progress,
      start.longitude + (end.longitude - start.longitude) * progress,
    );
    final zoom =
        _cameraAnimationStartZoom +
        (_cameraAnimationEndZoom - _cameraAnimationStartZoom) * progress;
    _mapController.move(center, zoom);
  }

  void _zoomBy(double amount) {
    final camera = _mapController.camera;

    final nextZoom = (camera.zoom + amount)
        .clamp(_minZoom, _maxZoom)
        .toDouble();

    _mapController.move(camera.center, nextZoom);
  }

  Future<void> _openCountyHeatInsights() async {
    final counties = _countyActivitySummaries(_visibleActivity())
      ..sort(
        (first, second) =>
            second.totalWinningTickets.compareTo(first.totalWinningTickets),
      );
    final totalRecords = counties.fold<int>(
      0,
      (total, county) => total + county.records.length,
    );
    final totalTickets = counties.fold<int>(
      0,
      (total, county) => total + county.totalWinningTickets,
    );
    final highestCountyTotal = counties.isEmpty
        ? 0
        : counties.first.totalWinningTickets;

    await _magicMouseChannel.invokeMethod<void>('setMapActive', false);
    if (!mounted) return;
    try {
      await showModalBottomSheet<void>(
        context: context,
        backgroundColor: const Color(0xFF0B1D2C),
        isScrollControlled: true,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        builder: (sheetContext) => SafeArea(
          child: DraggableScrollableSheet(
            expand: false,
            initialChildSize: 0.66,
            minChildSize: 0.38,
            maxChildSize: 0.90,
            builder: (context, scrollController) => ListView(
              controller: scrollController,
              padding: const EdgeInsets.fromLTRB(22, 10, 22, 30),
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white24,
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                const Row(
                  children: [
                    Icon(Icons.insights_rounded, color: Color(0xFF60A5FA)),
                    SizedBox(width: 10),
                    Text(
                      'South Carolina Heat Insights',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  'Based on the game, prize, and timeline filters currently on the map.',
                  style: const TextStyle(color: Colors.white60, height: 1.35),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Expanded(
                      child: _countyInsightStat(
                        label: 'COUNTIES',
                        value: '${counties.length}',
                        icon: Icons.location_city_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _countyInsightStat(
                        label: 'RECORDS',
                        value: '$totalRecords',
                        icon: Icons.receipt_long_rounded,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _countyInsightStat(
                        label: 'TICKETS',
                        value: '$totalTickets',
                        icon: Icons.confirmation_number_rounded,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'MOST ACTIVE COUNTIES',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
                const SizedBox(height: 8),
                if (counties.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 28),
                    child: Center(
                      child: Text(
                        'No records match this combination yet. Try another date, game, or prize range.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white60, height: 1.4),
                      ),
                    ),
                  )
                else
                  ...counties.take(10).map((county) {
                    final color = _countyHeatColor(
                      county.totalWinningTickets,
                      highestCountyTotal,
                    );
                    return ListTile(
                      contentPadding: const EdgeInsets.symmetric(horizontal: 2),
                      leading: CircleAvatar(
                        backgroundColor: color.withValues(alpha: 0.18),
                        child: Text(
                          '${counties.indexOf(county) + 1}',
                          style: TextStyle(
                            color: color,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      title: Text(
                        '${county.county}, ${county.state}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      subtitle: Text(
                        '${county.records.length} qualifying records · Highest ${county.highestPrize.formattedPrizeAmount}',
                        style: const TextStyle(color: Colors.white60),
                      ),
                      trailing: Text(
                        '${county.totalWinningTickets}',
                        style: TextStyle(
                          color: color,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      onTap: () {
                        Navigator.of(sheetContext).pop();
                        _showCountyActivityDetails(county);
                      },
                    );
                  }),
              ],
            ),
          ),
        ),
      );
    } finally {
      if (mounted) {
        await _magicMouseChannel.invokeMethod<void>('setMapActive', true);
      }
    }
  }

  Widget _countyInsightStat({
    required String label,
    required String value,
    required IconData icon,
  }) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
    decoration: BoxDecoration(
      color: const Color(0xFF102638),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: const Color(0xFF355066)),
    ),
    child: Column(
      children: [
        Icon(icon, color: const Color(0xFF60A5FA), size: 18),
        const SizedBox(height: 6),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white60,
            fontSize: 9,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ],
    ),
  );

  void _resetMap() {
    SouthCarolinaScratchMapFilterService.clear();
    SouthCarolinaLotteryMapFilterService.clear();
    SouthCarolinaRetailerMapService.hide();
    setState(() {
      _selectedStateName = null;
      _selectedCountyId = null;
      _hoveredStateName = null;
      _hoveredCountyId = null;
      _focusedRetailerId = null;
      _focusedHeatCountyKey = null;
      _selectedStateActivityGameName = null;
      _showStateGames = false;
    });

    _animateMapTo(_usCenter, _initialZoom);
  }

  void _returnToNationalMap() {
    // A state-specific game or retailer selection must not leak into the
    // national view. The map returns to its clean national-lotteries default.
    SouthCarolinaScratchMapFilterService.clear();
    SouthCarolinaLotteryMapFilterService.clear();
    SouthCarolinaRetailerMapService.hide();
    setState(() {
      _selectedStateName = null;
      _selectedCountyId = null;
      _hoveredStateName = null;
      _hoveredCountyId = null;
      _focusedRetailerId = null;
      _focusedHeatCountyKey = null;
      _showNextDrawings = false;
      _showScratchOffs = false;
      _showStateGames = false;
      _selectedStateActivityGameName = null;
    });

    _animateMapTo(_usCenter, _initialZoom);
  }

  void _goToHomeState() {
    final stateName = _homeStateName;
    if (stateName == null) {
      _resetMap();
      return;
    }

    setState(() {
      _selectedStateName = stateName;
      _selectedCountyId = null;
      _hoveredStateName = null;
      _hoveredCountyId = null;
    });

    if (stateName == 'Alaska') {
      _animateMapTo(_alaskaCenter, 4.4);
      return;
    }

    final points = _stateShapes
        .where((shape) => shape.name == stateName)
        .expand((shape) => shape.points)
        .toList();
    if (points.isEmpty) {
      _resetMap();
      return;
    }

    _animateCameraFit(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: _stateCameraPadding(stateName),
      ),
    );
  }

  void _returnToSelectedState() {
    final stateName = _selectedStateName;
    if (stateName == null) return;

    setState(() {
      _selectedCountyId = null;
      _hoveredCountyId = null;
      _focusedRetailerId = null;
      _focusedHeatCountyKey = null;
    });

    if (stateName == 'Alaska') {
      _animateMapTo(_alaskaCenter, 4.4);
      return;
    }

    final points = _stateShapes
        .where((shape) => shape.name == stateName)
        .expand((shape) => shape.points)
        .toList();
    if (points.isEmpty) return;

    _animateCameraFit(
      CameraFit.bounds(
        bounds: LatLngBounds.fromPoints(points),
        padding: _stateCameraPadding(stateName),
      ),
    );
  }

  Future<void> _setSelectedStateAsHome() async {
    final stateName = _selectedStateName;
    if (stateName == null) return;

    await AppPreferences.setHomeState(stateName);
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$stateName is now your home state.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedState = _selectedStateName == null
        ? null
        : StateNavigationService.getStateByName(_selectedStateName!);
    final isSouthCarolinaSelected = selectedState?.name == 'South Carolina';
    final selectedStateSource = selectedState == null
        ? null
        : StateLotterySourceRegistry.forState(selectedState.name);
    // Every state with an approved official source gets the same compact
    // toolbar. SC and NC retain their richer verified catalog adapters.
    final usesCompactStateToolbar = selectedStateSource != null;
    final selectedStateFips = _selectedStateName == null
        ? null
        : _stateFipsByName[_selectedStateName!];

    final visibleCounties = selectedStateFips == null
        ? const <_CountyShape>[]
        : _countyShapes
              .where((county) => county.stateFips == selectedStateFips)
              .toList();

    _CountyShape? selectedCounty;

    for (final county in _countyShapes) {
      if (county.id == _selectedCountyId) {
        selectedCounty = county;
        break;
      }
    }

    final visibleActivity = _visibleActivity();
    final selectedStateActivity = selectedState == null
        ? const <LotteryActivity>[]
        : LotteryActivityRepository.activity
              .where(
                (activity) =>
                    activity.state == selectedState.abbreviation.toUpperCase(),
              )
              .toList(growable: false);
    final shouldShowEmptyStateNotice =
        selectedState != null && visibleActivity.isEmpty;
    final countyActivity = _countyActivitySummaries(visibleActivity);
    final highestCountyTotalsByState = _highestCountyTotalsByState(
      countyActivity,
    );
    final activeScratchFilter =
        SouthCarolinaScratchMapFilterService.selection.value;
    final activeSouthCarolinaFilter =
        SouthCarolinaLotteryMapFilterService.selection.value;
    final showSouthCarolinaRetailers =
        SouthCarolinaRetailerMapService.isVisible.value;
    final visibleSouthCarolinaRetailers = _visibleSouthCarolinaRetailers();
    final southCarolinaVisibleRecordCount = visibleActivity
        .where((activity) => activity.state == 'SC')
        .length;
    // Auxiliary map menus must sit above the full control stack. A selected
    // state adds the back button, which otherwise overlaps this banner.
    final actionControlCount = _selectedStateName == null ? 3 : 4;
    final mapMenuBottom =
        160 + (actionControlCount * 52) + ((actionControlCount - 1) * 10) + 12;
    // In the U.S. view, the national-draw menu occupies the lower-left cell
    // of the same two-by-two toolbar grid as Game Filter, Filters, and Find a
    // State. Keeping one shared width prevents the menu from looking offset.
    final headerControlWidth = (MediaQuery.sizeOf(context).width - 44) / 2;

    return FutureBuilder<_MapGeometry>(
      future: _mapGeometryFuture,
      builder: (context, snapshot) {
        final stateShapes = snapshot.data?.states ?? const <_StateShape>[];

        return Stack(
          children: [
            // Keeps the ocean and surrounding countries the same dark-slate
            // family in Simple mode, where no raster tile layer is shown.
            const Positioned.fill(child: ColoredBox(color: Color(0xFF1D2933))),
            FlutterMap(
              mapController: _mapController,
              options: MapOptions(
                initialCenter: _usCenter,
                initialZoom: _initialZoom,
                minZoom: _minZoom,
                maxZoom: _maxZoom,
                // FlutterMap paints its own canvas above the Stack. Setting
                // this removes the white background in Simple mode.
                backgroundColor: const Color(0xFF1D2933),
                onPositionChanged: (camera, hasGesture) {
                  if ((_currentZoom - camera.zoom).abs() < 0.15) {
                    return;
                  }

                  setState(() {
                    _currentZoom = camera.zoom;
                  });
                },
                interactionOptions: const InteractionOptions(
                  flags: InteractiveFlag.all,
                ),
                onPointerHover: (_, point) =>
                    _updateHoveredStateFromMapPoint(point),
              ),
              children: [
                if (_mapDetailMode == MapDetailMode.standard)
                  TileLayer(
                    // CARTO's legacy raster endpoint now responds with an
                    // "API key required" watermark. Esri's dark canvas tiles
                    // preserve the same slate-gray treatment without adding
                    // a separate basemap credential to the desktop app.
                    urlTemplate:
                        'https://server.arcgisonline.com/ArcGIS/rest/services/'
                        'Canvas/World_Dark_Gray_Base/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'com.lotteryatlas.app',
                  ),
                if (_mapDetailMode == MapDetailMode.detailed)
                  TileLayer(
                    urlTemplate:
                        'https://server.arcgisonline.com/ArcGIS/rest/services/'
                        'World_Imagery/MapServer/tile/{z}/{y}/{x}',
                    userAgentPackageName: 'com.lotteryatlas.app',
                  ),
                if (_showTimeZones && _selectedStateName == null)
                  const TimeZoneBoundaryBands(),
                MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    behavior: HitTestBehavior.deferToChild,
                    onTap: _selectState,
                    child: PolygonLayer<String>(
                      hitNotifier: _stateHitNotifier,
                      polygons: stateShapes.map((shape) {
                        final isHovered = shape.name == _hoveredStateName;
                        final isSelected = shape.name == _selectedStateName;
                        final defaultStateFillColor =
                            _mapDetailMode == MapDetailMode.simple
                            ? const Color(0xFF26343E)
                            : _mapDetailMode == MapDetailMode.standard
                            ? const Color(0x8A26343E)
                            : const Color(0x142196F3);
                        // The state base stays neutral. Heat bubbles alone
                        // visualize the currently selected game, prize range,
                        // and timeline window, so no unrelated state appears
                        // active (such as New Mexico previously did).
                        final stateFillColor = defaultStateFillColor;

                        return Polygon<String>(
                          points: shape.points,
                          holePointsList: shape.holePoints,
                          hitValue: shape.name,
                          color: isSelected
                              ? const Color(0x663B82F6)
                              : isHovered
                              ? const Color(0x66FBBF24)
                              : stateFillColor,
                          borderColor: isSelected
                              ? const Color(0xFF38BDF8)
                              : isHovered
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF075AA8),
                          borderStrokeWidth: isSelected || isHovered
                              ? 3.0
                              : 2.0,
                        );
                      }).toList(),
                    ),
                  ),
                ),
                if (selectedState == null)
                  MarkerLayer(markers: _buildStateLabels(stateShapes)),
                if (_showTimeZones && _selectedStateName == null)
                  const TimeZoneClockMarkers(),
                if (selectedStateFips != null)
                  MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: GestureDetector(
                      behavior: HitTestBehavior.deferToChild,
                      onTap: _selectCounty,
                      child: PolygonLayer<String>(
                        hitNotifier: _countyHitNotifier,
                        polygons: visibleCounties.map((county) {
                          final isHovered = county.id == _hoveredCountyId;
                          final isSelected = county.id == _selectedCountyId;

                          final defaultCountyFillColor =
                              _mapDetailMode == MapDetailMode.detailed
                              ? const Color(0x38031626)
                              : const Color(0x102196F3);

                          final defaultCountyBorderColor =
                              _mapDetailMode == MapDetailMode.detailed
                              ? const Color(0xFFF6FDFF)
                              : const Color(0xFF3F6175);

                          final defaultCountyBorderWidth =
                              _mapDetailMode == MapDetailMode.detailed
                              ? 2.8
                              : 1.35;

                          return Polygon<String>(
                            points: county.points,
                            holePointsList: county.holePoints,
                            hitValue: county.id,
                            color: isSelected
                                ? const Color(0x664ADE80)
                                : isHovered
                                ? const Color(0x66FBBF24)
                                : defaultCountyFillColor,
                            borderColor: isSelected
                                ? const Color(0xFF22C55E)
                                : isHovered
                                ? const Color(0xFFF59E0B)
                                : defaultCountyBorderColor,
                            borderStrokeWidth: isSelected || isHovered
                                ? 2.8
                                : defaultCountyBorderWidth,
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                if (selectedStateFips != null)
                  MarkerLayer(markers: _buildCountyLabels(visibleCounties)),
                CircleLayer(
                  circles: countyActivity.asMap().entries.map((entry) {
                    final county = entry.value;
                    final statePeak = _highestCountyTotalFor(
                      county,
                      highestCountyTotalsByState,
                    );
                    final color = _animatedCountyHeatColor(
                      county,
                      _countyHeatColor(county.totalWinningTickets, statePeak),
                    );
                    final scale = _heatBubbleScale(entry.key);
                    final baseRadius = _countyHeatRadius(
                      county.totalWinningTickets,
                      statePeak,
                    );
                    return CircleMarker(
                      point: county.location,
                      radius: (baseRadius + 13) * scale,
                      color: color.withValues(alpha: 0.08 + 0.12 * scale),
                      borderColor: Colors.transparent,
                      borderStrokeWidth: 0,
                    );
                  }).toList(),
                ),
                CircleLayer(
                  circles: countyActivity.asMap().entries.map((entry) {
                    final county = entry.value;
                    final statePeak = _highestCountyTotalFor(
                      county,
                      highestCountyTotalsByState,
                    );
                    final color = _animatedCountyHeatColor(
                      county,
                      _countyHeatColor(county.totalWinningTickets, statePeak),
                    );
                    final scale = _heatBubbleScale(entry.key);
                    final radius =
                        _countyHeatRadius(
                          county.totalWinningTickets,
                          statePeak,
                        ) *
                        scale;
                    return CircleMarker(
                      point: county.location,
                      radius: radius,
                      color: color.withValues(alpha: 0.28 + 0.32 * scale),
                      borderColor: color,
                      borderStrokeWidth: 1 + scale,
                    );
                  }).toList(),
                ),
                if (_focusedHeatCountyKey != null)
                  CircleLayer(
                    circles: countyActivity
                        .where(
                          (county) =>
                              _countyHeatKey(county) == _focusedHeatCountyKey,
                        )
                        .map((county) {
                          final statePeak = _highestCountyTotalFor(
                            county,
                            highestCountyTotalsByState,
                          );
                          final progress = _countyFocusProgress();
                          final color = _countyHeatColor(
                            county.totalWinningTickets,
                            statePeak,
                          );
                          final radius =
                              _countyHeatRadius(
                                county.totalWinningTickets,
                                statePeak,
                              ) +
                              10 +
                              34 * progress;
                          return CircleMarker(
                            point: county.location,
                            radius: radius,
                            color: Colors.transparent,
                            borderColor: color.withValues(
                              alpha: 0.85 * (1 - progress),
                            ),
                            borderStrokeWidth: 3 * (1 - progress) + 0.5,
                          );
                        })
                        .toList(growable: false),
                  ),
                MarkerLayer(
                  markers: countyActivity.map((county) {
                    final statePeak = _highestCountyTotalFor(
                      county,
                      highestCountyTotalsByState,
                    );
                    final markerSize =
                        _countyHeatRadius(
                              county.totalWinningTickets,
                              statePeak,
                            ) *
                            2 +
                        28;
                    return Marker(
                      point: county.location,
                      width: markerSize,
                      height: markerSize,
                      alignment: Alignment.center,
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () => _focusCountyHeatBubble(county),
                          child: const SizedBox.expand(),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                if (showSouthCarolinaRetailers)
                  MarkerLayer(
                    markers: visibleSouthCarolinaRetailers
                        .map(_buildRetailerMarker)
                        .toList(growable: false),
                  ),
                if (_mapDetailMode == MapDetailMode.standard)
                  const RichAttributionWidget(
                    attributions: [TextSourceAttribution('Tiles © Esri')],
                  ),
                if (_mapDetailMode == MapDetailMode.detailed)
                  const RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution(
                        '© Esri, Maxar, Earthstar Geographics, '
                        'and the GIS User Community',
                      ),
                    ],
                  ),
              ],
            ),

            Positioned.fill(
              child: MapControlsOverlay(
                detailMode: _mapDetailMode,
                filterState: _filterState,
                showHeaderControls: selectedState == null,
                onDetailModeChanged: (mode) {
                  setState(() {
                    _mapDetailMode = mode;
                  });
                  AppPreferences.setMapDetailMode(mode);
                },
                onFilterChanged: _onMapFilterChanged,
                showTimeZones: _showTimeZones,
                onTimeZoneVisibilityChanged: (isVisible) {
                  setState(() {
                    _showTimeZones = isVisible;
                  });
                  AppPreferences.setShowTimeZones(isVisible);
                },
                onSearchSelected: _navigateToSearchResult,
                onStateSelected: _focusStateByName,
                onSearchVisibilityChanged: (isOpen) {
                  _magicMouseChannel.invokeMethod<void>(
                    'setMapActive',
                    !isOpen,
                  );
                },
                onActivityRefresh: _refreshPublishedActivityFeed,
              ),
            ),

            if (shouldShowEmptyStateNotice)
              Positioned(
                top: usesCompactStateToolbar ? 114 : 220,
                left: 34,
                right: 34,
                child: IgnorePointer(
                  child: _MapActivityEmptyNotice(
                    stateName: selectedState.name,
                    hasPublishedStateActivity: selectedStateActivity.isNotEmpty,
                  ),
                ),
              ),

            if (usesCompactStateToolbar)
              Positioned(
                left: 24,
                top: 24,
                right: 24,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _StateLotteryPageButton(
                      abbreviation: selectedState!.abbreviation,
                      onTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => isSouthCarolinaSelected
                                ? const SouthCarolinaLotteryScreen()
                                : StateLotterySourceScreen(
                                    source: selectedStateSource,
                                  ),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 10),
                    if (!(isSouthCarolinaSelected
                        ? _showScratchOffs
                        : _showStateGames))
                      Expanded(
                        child: MouseRegion(
                          onEnter: (_) => _magicMouseChannel.invokeMethod<void>(
                            'setMapActive',
                            false,
                          ),
                          onExit: (_) => _magicMouseChannel.invokeMethod<void>(
                            'setMapActive',
                            true,
                          ),
                          child: NextDrawingsPanel(
                            width: double.infinity,
                            stateName: _selectedStateName,
                            isExpanded: _showNextDrawings,
                            onExpandedChanged: (isExpanded) {
                              setState(() {
                                _showNextDrawings = isExpanded;
                                if (isExpanded) {
                                  _showScratchOffs = false;
                                  _showStateGames = false;
                                }
                              });
                            },
                            onViewNationalResults: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) =>
                                      const NationalDrawResultsScreen(),
                                ),
                              );
                            },
                            onStateDrawSelected: _showStateDrawGameOnMap,
                            showStateLabel: true,
                          ),
                        ),
                      ),
                    if (!(isSouthCarolinaSelected
                            ? _showScratchOffs
                            : _showStateGames) &&
                        !_showNextDrawings)
                      const SizedBox(width: 10),
                    if (!_showNextDrawings)
                      Expanded(
                        child: MouseRegion(
                          onEnter: (_) => _magicMouseChannel.invokeMethod<void>(
                            'setMapActive',
                            false,
                          ),
                          onExit: (_) => _magicMouseChannel.invokeMethod<void>(
                            'setMapActive',
                            true,
                          ),
                          child: isSouthCarolinaSelected
                              ? _SouthCarolinaScratchOffsPanel(
                                  width: double.infinity,
                                  isExpanded: _showScratchOffs,
                                  selectedGameId: activeScratchFilter?.gameId,
                                  onExpandedChanged: (isExpanded) {
                                    setState(() {
                                      _showScratchOffs = isExpanded;
                                      if (isExpanded) {
                                        _showNextDrawings = false;
                                      }
                                    });
                                  },
                                  onAllSelected: () =>
                                      _showSouthCarolinaScratchGameOnMap('all'),
                                  onGameSelected:
                                      _showSouthCarolinaScratchGameOnMap,
                                  onOpenPrizeFinder:
                                      _openSouthCarolinaScratchOffPicker,
                                )
                              : selectedState.name == 'North Carolina'
                              ? _NorthCarolinaScratchOffsPanel(
                                  width: double.infinity,
                                  selectedGameName:
                                      _selectedStateActivityGameName,
                                  isExpanded: _showStateGames,
                                  onExpandedChanged: (isExpanded) {
                                    setState(() {
                                      _showStateGames = isExpanded;
                                      if (isExpanded) {
                                        _showNextDrawings = false;
                                      }
                                    });
                                  },
                                  onAllSelected: () =>
                                      _showNorthCarolinaScratchGameOnMap(null),
                                  onGameSelected: (gameName) =>
                                      _showNorthCarolinaScratchGameOnMap(
                                        gameName,
                                      ),
                                )
                              : StateScratchCatalogRegistry.hasCatalog(
                                  selectedState.name,
                                )
                              ? _VerifiedStateScratchOffsPanel(
                                  stateName: selectedState.name,
                                  selectedGameName:
                                      _selectedStateActivityGameName,
                                  isExpanded: _showStateGames,
                                  onExpandedChanged: (isExpanded) {
                                    setState(() {
                                      _showStateGames = isExpanded;
                                      if (isExpanded) {
                                        _showNextDrawings = false;
                                      }
                                    });
                                  },
                                  onAllSelected: () =>
                                      _showStateScratchGameOnMap(null),
                                  onGameSelected: _showStateScratchGameOnMap,
                                  onOpenCatalog: () =>
                                      _openOfficialScratchCatalog(
                                        selectedStateSource,
                                      ),
                                )
                              : _StateScratchOffsSourcePanel(
                                  stateName: selectedState.name,
                                  isExpanded: _showStateGames,
                                  onExpandedChanged: (isExpanded) {
                                    setState(() {
                                      _showStateGames = isExpanded;
                                      if (isExpanded) {
                                        _showNextDrawings = false;
                                      }
                                    });
                                  },
                                  onOpenCatalog: () =>
                                      _openOfficialScratchCatalog(
                                        selectedStateSource,
                                      ),
                                ),
                        ),
                      ),
                  ],
                ),
              ),
            if (!usesCompactStateToolbar)
              Positioned(
                left: 16,
                top: selectedState == null ? 148 : 160,
                child: MouseRegion(
                  onEnter: (_) => _magicMouseChannel.invokeMethod<void>(
                    'setMapActive',
                    false,
                  ),
                  onExit: (_) => _magicMouseChannel.invokeMethod<void>(
                    'setMapActive',
                    true,
                  ),
                  child: NextDrawingsPanel(
                    width: selectedState == null ? headerControlWidth : null,
                    stateName: _selectedStateName,
                    isExpanded: _showNextDrawings,
                    onExpandedChanged: (isExpanded) {
                      setState(() {
                        _showNextDrawings = isExpanded;
                      });
                    },
                    onViewNationalResults: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const NationalDrawResultsScreen(),
                        ),
                      );
                    },
                    onStateDrawSelected: _showSouthCarolinaDrawGameOnMap,
                  ),
                ),
              ),

            if (selectedState != null && !usesCompactStateToolbar)
              Positioned(
                top: 24,
                right: 24,
                child: _StateLotteryPanel(
                  state: selectedState,
                  selectedCountyName: selectedCounty?.name,
                  selectedCountyId: selectedCounty?.id,
                  onClose: _resetMap,
                  onClearCounty: _returnToSelectedState,
                  onOpenCounties: _openCountyPicker,
                  isHomeState: _homeStateName == selectedState.name,
                  onSetHomeState: _setSelectedStateAsHome,
                  onRefreshData: _refreshPublishedActivityFeed,
                ),
              ),

            if (activeScratchFilter != null)
              Positioned(
                right: 20,
                bottom: mapMenuBottom.toDouble(),
                child: _SouthCarolinaScratchFilterBanner(
                  label: activeScratchFilter.label,
                  recordCount: southCarolinaVisibleRecordCount,
                  onTap: _openSouthCarolinaGamePicker,
                  onInsights: _openCountyHeatInsights,
                  onClear: SouthCarolinaScratchMapFilterService.clear,
                ),
              ),

            if (activeSouthCarolinaFilter != null)
              Positioned(
                right: 20,
                bottom: mapMenuBottom.toDouble(),
                child: _SouthCarolinaScratchFilterBanner(
                  label: activeSouthCarolinaFilter.label,
                  recordCount: southCarolinaVisibleRecordCount,
                  onTap: _openSouthCarolinaGamePicker,
                  onInsights: _openCountyHeatInsights,
                  onClear: SouthCarolinaLotteryMapFilterService.clear,
                ),
              ),

            if (showSouthCarolinaRetailers)
              Positioned(
                right: 20,
                bottom: mapMenuBottom.toDouble(),
                child: _SouthCarolinaRetailerBanner(
                  count: visibleSouthCarolinaRetailers.length,
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const SouthCarolinaRetailersScreen(),
                      ),
                    );
                  },
                  onClear: SouthCarolinaRetailerMapService.hide,
                ),
              ),

            Positioned(
              right: 20,
              bottom: 160,
              child: MapActionControls(
                onReset: _resetMap,
                onHome: _homeStateName == null ? null : _goToHomeState,
                onBack: _focusedRetailerId != null
                    ? _returnToCountyFromRetailer
                    : _selectedCountyId != null
                    ? _returnToSelectedState
                    : _selectedStateName == null
                    ? null
                    : _returnToNationalMap,
                backTooltip: _focusedRetailerId != null
                    ? 'Back to county map'
                    : _selectedCountyId != null
                    ? 'Back to state map'
                    : 'Back to U.S. map',
                onZoomIn: () => _zoomBy(1),
                onZoomOut: () => _zoomBy(-1),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _MapActivityEmptyNotice extends StatelessWidget {
  const _MapActivityEmptyNotice({
    required this.stateName,
    required this.hasPublishedStateActivity,
  });

  final String stateName;
  final bool hasPublishedStateActivity;

  @override
  Widget build(BuildContext context) {
    final title = hasPublishedStateActivity
        ? 'No $stateName activity matches this view'
        : 'No published $stateName claim locations yet';
    final detail = hasPublishedStateActivity
        ? 'Try another game, a wider prize range, or a longer timeline period.'
        : 'Draw times and ticket catalogs can be available before official winner reports provide retailer-level map activity.';

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xE60A1824),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF355066)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x55000000),
            blurRadius: 14,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(13),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              hasPublishedStateActivity
                  ? Icons.filter_alt_off_outlined
                  : Icons.info_outline_rounded,
              color: const Color(0xFF93C5FD),
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    detail,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SouthCarolinaScratchFilterBanner extends StatelessWidget {
  const _SouthCarolinaScratchFilterBanner({
    required this.label,
    required this.recordCount,
    required this.onTap,
    required this.onInsights,
    required this.onClear,
  });

  final String label;
  final int recordCount;
  final VoidCallback onTap;
  final VoidCallback onInsights;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xEE102638),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      width: 270,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF60A5FA)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      children: [
                        const Icon(
                          Icons.filter_alt_rounded,
                          size: 18,
                          color: Color(0xFF60A5FA),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            label,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: Colors.white70,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              IconButton(
                tooltip: 'County heat insights',
                onPressed: onInsights,
                icon: const Icon(
                  Icons.insights_rounded,
                  color: Color(0xFF93C5FD),
                ),
                visualDensity: VisualDensity.compact,
              ),
              IconButton(
                tooltip: 'Clear Scratch-Off map filter',
                onPressed: onClear,
                icon: const Icon(Icons.close_rounded, color: Colors.white70),
                visualDensity: VisualDensity.compact,
              ),
            ],
          ),
          Padding(
            padding: const EdgeInsets.only(left: 26, bottom: 2),
            child: Text(
              '$recordCount matching ${recordCount == 1 ? 'record' : 'records'} on the map',
              style: const TextStyle(
                color: Colors.white60,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    ),
  );
}

class _SouthCarolinaRetailerBanner extends StatelessWidget {
  const _SouthCarolinaRetailerBanner({
    required this.count,
    required this.onTap,
    required this.onClear,
  });

  final int count;
  final VoidCallback onTap;
  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) => Material(
    color: const Color(0xEE102638),
    borderRadius: BorderRadius.circular(14),
    child: Container(
      width: 270,
      padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFF38BDF8)),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  children: [
                    const Icon(
                      Icons.storefront_rounded,
                      size: 18,
                      color: Color(0xFF93C5FD),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '$count SC retailer claim locations',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.open_in_new_rounded,
                      size: 17,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ),
          ),
          IconButton(
            tooltip: 'Hide retailer locations',
            onPressed: onClear,
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    ),
  );
}

class _CountyActivitySummary {
  const _CountyActivitySummary({
    required this.county,
    required this.state,
    required this.location,
    required this.records,
    required this.totalWinningTickets,
    required this.highestPrize,
  });

  final String county;
  final String state;
  final LatLng location;
  final List<LotteryActivity> records;
  final int totalWinningTickets;
  final LotteryActivity highestPrize;

  factory _CountyActivitySummary.fromActivity(List<LotteryActivity> records) {
    assert(records.isNotEmpty);

    final first = records.first;
    var latitudeTotal = 0.0;
    var longitudeTotal = 0.0;
    var winningTicketTotal = 0;
    var highestPrize = first;

    for (final record in records) {
      latitudeTotal += record.location.latitude;
      longitudeTotal += record.location.longitude;
      winningTicketTotal += record.winningTickets;
      if (record.prizeAmount > highestPrize.prizeAmount) {
        highestPrize = record;
      }
    }

    return _CountyActivitySummary(
      county: first.county,
      state: first.state,
      location: LatLng(
        latitudeTotal / records.length,
        longitudeTotal / records.length,
      ),
      records: List<LotteryActivity>.unmodifiable(records),
      totalWinningTickets: winningTicketTotal,
      highestPrize: highestPrize,
    );
  }
}

class _MapGeometry {
  const _MapGeometry({required this.states, required this.counties});

  final List<_StateShape> states;
  final List<_CountyShape> counties;
}

class _StateShape {
  const _StateShape({
    required this.name,
    required this.points,
    required this.holePoints,
  });

  final String name;
  final List<LatLng> points;
  final List<List<LatLng>> holePoints;
}

class _CountyShape {
  const _CountyShape({
    required this.id,
    required this.name,
    required this.stateFips,
    required this.points,
    required this.holePoints,
  });

  final String id;
  final String name;
  final String stateFips;
  final List<LatLng> points;
  final List<List<LatLng>> holePoints;
}

class _StateLotteryPageButton extends StatelessWidget {
  const _StateLotteryPageButton({
    required this.abbreviation,
    required this.onTap,
  });

  final String abbreviation;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
    color: Colors.transparent,
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        height: 48,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xEE0A1824),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFF355066)),
          boxShadow: const [
            BoxShadow(
              color: Colors.black45,
              blurRadius: 12,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.account_balance_outlined,
              color: Color(0xFF60A5FA),
            ),
            const SizedBox(width: 8),
            Text(
              '$abbreviation LOTTERY',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(
              Icons.open_in_new_rounded,
              color: Colors.white54,
              size: 16,
            ),
          ],
        ),
      ),
    ),
  );
}

class _SouthCarolinaScratchOffsPanel extends StatelessWidget {
  const _SouthCarolinaScratchOffsPanel({
    required this.isExpanded,
    required this.selectedGameId,
    required this.onExpandedChanged,
    required this.onAllSelected,
    required this.onGameSelected,
    required this.onOpenPrizeFinder,
    this.width,
  });

  final bool isExpanded;
  final String? selectedGameId;
  final ValueChanged<bool> onExpandedChanged;
  final VoidCallback onAllSelected;
  final ValueChanged<String> onGameSelected;
  final VoidCallback onOpenPrizeFinder;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final expandedHeight = (MediaQuery.sizeOf(context).height - 205)
        .clamp(300.0, 520.0)
        .toDouble();

    return SizedBox(
      width: width ?? 290,
      height: isExpanded ? expandedHeight : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xED0A1824),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => onExpandedChanged(!isExpanded),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        color: Color(0xFFFACC15),
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'SOUTH CAROLINA SCRATCH-OFFS',
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1, color: Colors.white24),
              Expanded(
                child: Scrollbar(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                    children: [
                      const Text(
                        'Select a ticket to focus the heat map. Prize Finder lets you choose a custom winnings range.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ScratchOffMenuTile(
                        icon: Icons.layers_rounded,
                        title: 'All Scratch-Off activity',
                        subtitle: 'Show every published Scratch-Off claim',
                        isSelected: selectedGameId == 'all',
                        onTap: onAllSelected,
                      ),
                      _ScratchOffMenuTile(
                        icon: Icons.tune_rounded,
                        title: 'Choose ticket and prize range',
                        subtitle: 'Open the full SC Scratch-Off prize finder',
                        onTap: onOpenPrizeFinder,
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(4, 14, 4, 6),
                        child: Text(
                          'TICKETS',
                          style: TextStyle(
                            color: Color(0xFF93C5FD),
                            fontSize: 10,
                            letterSpacing: 0.9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      ...SouthCarolinaScratchCatalog.games.map(
                        (game) => _ScratchOffMenuTile(
                          icon: Icons.confirmation_number_outlined,
                          title: game.displayName,
                          subtitle:
                              'Top prize ${_formatPrize(game.topPrize)} · ${game.claimedYesterday} claims',
                          isSelected: selectedGameId == game.id,
                          onTap: () => onGameSelected(game.id),
                          favoriteGame: FavoriteLotteryGame(
                            key: 'sc-scratch:${game.id}',
                            gameId: game.id,
                            name: game.displayName,
                            subtitle: 'South Carolina Scratch-Off',
                            kind: FavoriteLotteryGameKind.scratchOff,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatPrize(int amount) {
    if (amount >= 1000000) return '\$${amount ~/ 1000000}M';
    if (amount >= 1000) return '\$${amount ~/ 1000}K';
    return '\$$amount';
  }
}

/// Uses the same compact state-toolbar treatment as South Carolina's
/// Scratch-Off control. NC's ticket catalog is inventory data; only the
/// official winner records matching a selected ticket become heat-map points.
class _NorthCarolinaScratchOffsPanel extends StatelessWidget {
  const _NorthCarolinaScratchOffsPanel({
    required this.selectedGameName,
    required this.isExpanded,
    required this.onExpandedChanged,
    required this.onAllSelected,
    required this.onGameSelected,
    this.width,
  });

  final String? selectedGameName;
  final bool isExpanded;
  final ValueChanged<bool> onExpandedChanged;
  final VoidCallback onAllSelected;
  final ValueChanged<String> onGameSelected;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final expandedHeight = (MediaQuery.sizeOf(context).height - 205)
        .clamp(300.0, 520.0)
        .toDouble();
    const label = 'NORTH CAROLINA SCRATCH-OFFS';

    return SizedBox(
      width: width ?? 290,
      height: isExpanded ? expandedHeight : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xED0A1824),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => onExpandedChanged(!isExpanded),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        color: Color(0xFFFACC15),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1, color: Colors.white24),
              Expanded(
                child: Scrollbar(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                    children: [
                      Text(
                        'Select a ticket to focus the map on its published claim activity. The catalog shows official current prize inventory.',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ScratchOffMenuTile(
                        icon: Icons.layers_rounded,
                        title: 'All North Carolina Scratch-Off activity',
                        subtitle: 'Show every published Scratch-Off claim',
                        isSelected: selectedGameName == null,
                        onTap: onAllSelected,
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(4, 14, 4, 6),
                        child: Text(
                          'VERIFIED TICKET SNAPSHOT',
                          style: TextStyle(
                            color: Color(0xFF93C5FD),
                            fontSize: 10,
                            letterSpacing: 0.9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      ...NorthCarolinaScratchCatalog.games.map(
                        (game) => _ScratchOffMenuTile(
                          icon: Icons.confirmation_number_outlined,
                          title: game.name,
                          subtitle:
                              'Top prize ${_formatNcPrize(game.topPrize)} · ${game.topPrizesRemaining} remaining',
                          isSelected: selectedGameName == game.name,
                          onTap: () => onGameSelected(game.name),
                          favoriteGame: FavoriteLotteryGame(
                            key: 'nc-scratch:${game.id}',
                            gameId: game.id,
                            name: game.name,
                            subtitle: 'North Carolina Scratch-Off',
                            kind: FavoriteLotteryGameKind.scratchOff,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static String _formatNcPrize(int amount) {
    if (amount >= 1000000) return '\$${amount ~/ 1000000}M';
    if (amount >= 1000) return '\$${amount ~/ 1000}K';
    return '\$$amount';
  }
}

/// Reusable ticket menu for a state with a verified official scratch catalog.
/// The catalog is shown separately from the heat map so the app never implies
/// that a remaining prize can be located at a particular retailer.
class _VerifiedStateScratchOffsPanel extends StatelessWidget {
  const _VerifiedStateScratchOffsPanel({
    required this.stateName,
    required this.selectedGameName,
    required this.isExpanded,
    required this.onExpandedChanged,
    required this.onAllSelected,
    required this.onGameSelected,
    required this.onOpenCatalog,
  });

  final String stateName;
  final String? selectedGameName;
  final bool isExpanded;
  final ValueChanged<bool> onExpandedChanged;
  final VoidCallback onAllSelected;
  final ValueChanged<String> onGameSelected;
  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    final games = StateScratchCatalogRegistry.gamesFor(stateName);
    final expandedHeight = (MediaQuery.sizeOf(context).height - 205)
        .clamp(300.0, 520.0)
        .toDouble();

    return SizedBox(
      width: double.infinity,
      height: isExpanded ? expandedHeight : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xED0A1824),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => onExpandedChanged(!isExpanded),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        color: Color(0xFFFACC15),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '$stateName SCRATCH-OFFS'.toUpperCase(),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1, color: Colors.white24),
              Expanded(
                child: Scrollbar(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                    children: [
                      const Text(
                        'Verified ticket snapshot. Select a ticket to focus any published claim activity for that game. Retailer locations appear only when an official winner feed provides them.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 11,
                          height: 1.3,
                        ),
                      ),
                      const SizedBox(height: 10),
                      _ScratchOffMenuTile(
                        icon: Icons.layers_rounded,
                        title: 'All $stateName Scratch-Off activity',
                        subtitle: 'Show every published Scratch-Off claim',
                        isSelected: selectedGameName == null,
                        onTap: onAllSelected,
                      ),
                      const SizedBox(height: 7),
                      _ScratchOffMenuTile(
                        icon: Icons.open_in_new_rounded,
                        title: 'Open full official catalog',
                        subtitle: 'View every active ticket and prize update',
                        onTap: onOpenCatalog,
                      ),
                      const Padding(
                        padding: EdgeInsets.fromLTRB(4, 14, 4, 6),
                        child: Text(
                          'VERIFIED TICKET SNAPSHOT',
                          style: TextStyle(
                            color: Color(0xFF93C5FD),
                            fontSize: 10,
                            letterSpacing: 0.9,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      ...games.map(
                        (game) => _ScratchOffMenuTile(
                          icon: Icons.confirmation_number_outlined,
                          title: game.name,
                          subtitle: _gameSummary(game),
                          isSelected: selectedGameName == game.name,
                          onTap: () => onGameSelected(game.name),
                          favoriteGame: FavoriteLotteryGame(
                            key:
                                '${stateName.toLowerCase().replaceAll(' ', '-')}-scratch:${game.id}',
                            gameId: game.id,
                            name: game.name,
                            subtitle: '$stateName Scratch-Off',
                            kind: FavoriteLotteryGameKind.scratchOff,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _gameSummary(StateScratchGame game) {
    final remaining = game.topPrizesRemaining;
    final topPrize = game.topPrizeLabel ?? _money(game.topPrize);
    return remaining == null
        ? '\$${game.cost} ticket · Top prize $topPrize'
        : '\$${game.cost} ticket · Top $topPrize · $remaining remaining';
  }

  String _money(int amount) {
    if (amount >= 1000000) return '\$${amount ~/ 1000000}M';
    if (amount >= 1000) return '\$${amount ~/ 1000}K';
    return '\$$amount';
  }
}

/// Shared Scratch-Off menu used by every approved state source while its
/// item-level catalog is being connected. It keeps the state-map toolbar
/// consistent without presenting unverified ticket names as app data.
class _StateScratchOffsSourcePanel extends StatelessWidget {
  const _StateScratchOffsSourcePanel({
    required this.stateName,
    required this.isExpanded,
    required this.onExpandedChanged,
    required this.onOpenCatalog,
  });

  final String stateName;
  final bool isExpanded;
  final ValueChanged<bool> onExpandedChanged;
  final VoidCallback onOpenCatalog;

  @override
  Widget build(BuildContext context) {
    final expandedHeight = (MediaQuery.sizeOf(context).height - 205)
        .clamp(300.0, 520.0)
        .toDouble();
    final label = '$stateName SCRATCH-OFFS'.toUpperCase();

    return SizedBox(
      width: double.infinity,
      height: isExpanded ? expandedHeight : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: const Color(0xED0A1824),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white24),
          boxShadow: const [
            BoxShadow(
              color: Color(0x66000000),
              blurRadius: 14,
              offset: Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: isExpanded ? MainAxisSize.max : MainAxisSize.min,
          children: [
            InkWell(
              onTap: () => onExpandedChanged(!isExpanded),
              borderRadius: BorderRadius.circular(18),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 4,
                ),
                child: SizedBox(
                  height: 40,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.confirmation_number_outlined,
                        color: Color(0xFFFACC15),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          label,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.7,
                          ),
                        ),
                      ),
                      Icon(
                        isExpanded
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        color: Colors.white70,
                      ),
                    ],
                  ),
                ),
              ),
            ),
            if (isExpanded) ...[
              const Divider(height: 1, color: Colors.white24),
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 18),
                  children: [
                    const Text(
                      'The official catalog is ready to browse. Ticket-level prize and location data appears here once its verified state feed is connected to the map.',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                        height: 1.3,
                      ),
                    ),
                    const SizedBox(height: 12),
                    _ScratchOffMenuTile(
                      icon: Icons.open_in_new_rounded,
                      title: 'Open official Scratch-Off catalog',
                      subtitle: 'Browse current games and prize information',
                      onTap: onOpenCatalog,
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _ScratchOffMenuTile extends StatelessWidget {
  const _ScratchOffMenuTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.favoriteGame,
    this.isSelected = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final FavoriteLotteryGame? favoriteGame;
  final bool isSelected;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 7),
    child: Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Ink(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isSelected
                ? const Color(0xFF1D4ED8).withValues(alpha: 0.24)
                : Colors.white.withValues(alpha: 0.04),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? const Color(0xFF60A5FA) : Colors.white24,
            ),
          ),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFFACC15), size: 19),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              if (isSelected)
                const Icon(
                  Icons.check_circle_rounded,
                  color: Color(0xFF60A5FA),
                  size: 18,
                ),
              if (favoriteGame != null)
                _ScratchFavoriteGameButton(game: favoriteGame!),
            ],
          ),
        ),
      ),
    ),
  );
}

class _ScratchFavoriteGameButton extends StatelessWidget {
  const _ScratchFavoriteGameButton({required this.game});

  final FavoriteLotteryGame game;

  Future<void> _toggle(BuildContext context) async {
    final isSaved = await FavoriteGamesService.toggle(game);
    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSaved
              ? '${game.name} saved to favorite games.'
              : '${game.name} removed from favorite games.',
        ),
      ),
    );
  }

  @override
  Widget build(
    BuildContext context,
  ) => ValueListenableBuilder<List<FavoriteLotteryGame>>(
    valueListenable: FavoriteGamesService.games,
    builder: (context, favorites, _) {
      final isFavorite = favorites.any((favorite) => favorite.key == game.key);

      return IconButton(
        tooltip: isFavorite
            ? 'Remove from favorite games'
            : 'Save to favorite games',
        visualDensity: VisualDensity.compact,
        constraints: const BoxConstraints.tightFor(width: 34, height: 34),
        padding: EdgeInsets.zero,
        onPressed: () => _toggle(context),
        icon: Icon(
          isFavorite ? Icons.favorite_rounded : Icons.favorite_border_rounded,
          size: 19,
          color: isFavorite ? const Color(0xFFE94B6A) : Colors.white70,
        ),
      );
    },
  );
}

class _StateLotteryPanel extends StatefulWidget {
  const _StateLotteryPanel({
    required this.state,
    required this.selectedCountyName,
    required this.selectedCountyId,
    required this.onClose,
    required this.onClearCounty,
    required this.onOpenCounties,
    required this.isHomeState,
    required this.onSetHomeState,
    this.onRefreshData,
  });

  final StateModel state;
  final String? selectedCountyName;
  final String? selectedCountyId;
  final VoidCallback onClose;
  final VoidCallback onClearCounty;
  final Future<void> Function() onOpenCounties;
  final bool isHomeState;
  final Future<void> Function() onSetHomeState;
  final Future<void> Function()? onRefreshData;

  @override
  State<_StateLotteryPanel> createState() => _StateLotteryPanelState();
}

class _StateLotteryPanelState extends State<_StateLotteryPanel> {
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    FavoritePlacesService.load();
  }

  FavoritePlace get _stateFavorite => FavoritePlace(
    key: 'state:${widget.state.name.toLowerCase()}',
    title: widget.state.name,
    subtitle: '${widget.state.name} Lottery',
    kind: FavoritePlaceKind.state,
    stateName: widget.state.name,
  );

  FavoritePlace? get _countyFavorite {
    final countyId = widget.selectedCountyId;
    final countyName = widget.selectedCountyName;
    if (countyId == null || countyName == null) return null;
    return FavoritePlace(
      key: 'county:$countyId',
      title: '$countyName County',
      subtitle: '${widget.state.name} county',
      kind: FavoritePlaceKind.county,
      stateName: widget.state.name,
      countyId: countyId,
    );
  }

  Future<void> _toggleFavorite(FavoritePlace place) async {
    final saved = await FavoritePlacesService.toggle(place);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          saved
              ? '${place.title} saved to Favorites.'
              : '${place.title} removed from Favorites.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final officialSource = StateLotterySourceRegistry.forState(
      widget.state.name,
    );
    return Material(
      color: Colors.transparent,
      child: Container(
        width: _isCollapsed ? 238 : 290,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xEE121820),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.blueAccent.withValues(alpha: 0.55)),
          boxShadow: const [
            BoxShadow(color: Colors.black54, blurRadius: 20, spreadRadius: 2),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${widget.state.name} Lottery',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  tooltip: _isCollapsed
                      ? 'Show state tools'
                      : 'Collapse state tools',
                  onPressed: () => setState(() => _isCollapsed = !_isCollapsed),
                  icon: Icon(
                    _isCollapsed
                        ? Icons.keyboard_arrow_down_rounded
                        : Icons.keyboard_arrow_up_rounded,
                    color: Colors.white70,
                  ),
                ),
                IconButton(
                  tooltip: 'Return to national map',
                  onPressed: widget.onClose,
                  icon: const Icon(Icons.close, color: Colors.white70),
                ),
              ],
            ),
            if (_isCollapsed)
              const Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text(
                  'Tap the arrow to open state tools',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              )
            else ...[
              Text(
                widget.state.abbreviation,
                style: const TextStyle(color: Colors.amber, fontSize: 16),
              ),
              const SizedBox(height: 12),
              _StateDataCoverageCard(stateName: widget.state.name),
              const SizedBox(height: 4),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.isHomeState
                      ? null
                      : () async => widget.onSetHomeState(),
                  icon: Icon(
                    widget.isHomeState
                        ? Icons.home_rounded
                        : Icons.home_outlined,
                    size: 18,
                  ),
                  label: Text(
                    widget.isHomeState
                        ? 'Your home state'
                        : 'Make this my home state',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF93C5FD),
                    disabledForegroundColor: const Color(0xFF86EFAC),
                    side: const BorderSide(color: Color(0xFF355066)),
                    minimumSize: const Size.fromHeight(40),
                    alignment: Alignment.centerLeft,
                  ),
                ),
              ),
              const SizedBox(height: 8),
              ValueListenableBuilder<List<FavoritePlace>>(
                valueListenable: FavoritePlacesService.places,
                builder: (context, favorites, _) {
                  final isFavorite = favorites.any(
                    (place) => place.key == _stateFavorite.key,
                  );
                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _toggleFavorite(_stateFavorite),
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 18,
                      ),
                      label: Text(
                        isFavorite
                            ? 'Remove state from Favorites'
                            : 'Save state to Favorites',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: isFavorite
                            ? const Color(0xFFE94B6A)
                            : const Color(0xFF93C5FD),
                        side: BorderSide(
                          color: isFavorite
                              ? const Color(0xFFE94B6A)
                              : const Color(0xFF355066),
                        ),
                        minimumSize: const Size.fromHeight(40),
                        alignment: Alignment.centerLeft,
                      ),
                    ),
                  );
                },
              ),
              if (widget.state.name == 'South Carolina' &&
                  widget.onRefreshData != null)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Align(
                      alignment: Alignment.centerLeft,
                      child: TextButton.icon(
                        onPressed: () async => widget.onRefreshData!(),
                        icon: const Icon(Icons.refresh_rounded, size: 17),
                        label: const Text('Refresh SC map data'),
                        style: TextButton.styleFrom(
                          foregroundColor: const Color(0xFF93C5FD),
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                        ),
                      ),
                    ),
                    const Padding(
                      padding: EdgeInsets.only(left: 4),
                      child: Text(
                        'Keeps the last valid data available when offline.',
                        style: TextStyle(color: Colors.white38, fontSize: 10),
                      ),
                    ),
                  ],
                ),
              if (widget.selectedCountyName != null &&
                  widget.selectedCountyId != null) ...[
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0x3322C55E),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFF22C55E)),
                  ),
                  child: Row(
                    children: [
                      const Icon(
                        Icons.location_on_outlined,
                        color: Color(0xFF22C55E),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          '${widget.selectedCountyName} selected',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                if (_countyFavorite != null)
                  ValueListenableBuilder<List<FavoritePlace>>(
                    valueListenable: FavoritePlacesService.places,
                    builder: (context, favorites, _) {
                      final countyFavorite = _countyFavorite!;
                      final isFavorite = favorites.any(
                        (place) => place.key == countyFavorite.key,
                      );
                      return SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () => _toggleFavorite(countyFavorite),
                          icon: Icon(
                            isFavorite
                                ? Icons.favorite_rounded
                                : Icons.favorite_border_rounded,
                          ),
                          label: Text(
                            isFavorite
                                ? 'Remove county from Favorites'
                                : 'Save county to Favorites',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: isFavorite
                                ? const Color(0xFFE94B6A)
                                : const Color(0xFF93C5FD),
                            side: BorderSide(
                              color: isFavorite
                                  ? const Color(0xFFE94B6A)
                                  : const Color(0xFF355066),
                            ),
                            minimumSize: const Size.fromHeight(42),
                          ),
                        ),
                      );
                    },
                  ),
                if (_countyFavorite != null) const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CountyDetailsScreen(
                            state: widget.state,
                            countyName: widget.selectedCountyName!,
                            countyFips: widget.selectedCountyId!,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open County Details'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1478FF),
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: widget.onClearCounty,
                    icon: const Icon(Icons.arrow_back_rounded),
                    label: const Text('Back to state map'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF93C5FD),
                      side: const BorderSide(color: Color(0xFF355066)),
                      minimumSize: const Size.fromHeight(42),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 14),
              if (officialSource != null)
                _menuButton(
                  context,
                  icon: Icons.verified_outlined,
                  label: 'Official lottery source',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => widget.state.name == 'South Carolina'
                            ? const SouthCarolinaLotteryScreen()
                            : StateLotterySourceScreen(source: officialSource),
                      ),
                    );
                  },
                ),
              _menuButton(
                context,
                icon: Icons.analytics_outlined,
                label: 'Lottery Overview',
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) =>
                          LotteryOverviewScreen(state: widget.state),
                    ),
                  );
                },
              ),
              _menuButton(
                context,
                icon: Icons.confirmation_number_outlined,
                label: 'Scratch-Off Games',
                onTap: widget.state.name == 'South Carolina'
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) =>
                                const SouthCarolinaScratchOffsScreen(),
                          ),
                        );
                      }
                    : null,
              ),
              _menuButton(
                context,
                icon: Icons.map_outlined,
                label: 'Counties',
                onTap: () async => widget.onOpenCounties(),
              ),
              _menuButton(
                context,
                icon: Icons.storefront_outlined,
                label: 'Retailers',
                onTap: widget.state.name == 'South Carolina'
                    ? () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) =>
                                const SouthCarolinaRetailersScreen(),
                          ),
                        );
                      }
                    : null,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _menuButton(
    BuildContext context, {
    required IconData icon,
    required String label,
    VoidCallback? onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: OutlinedButton.icon(
        onPressed:
            onTap ??
            () {
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(SnackBar(content: Text('$label is coming soon.')));
            },
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(44),
          foregroundColor: Colors.white,
          side: const BorderSide(color: Colors.white24),
          alignment: Alignment.centerLeft,
        ),
      ),
    );
  }
}

class _StateDataCoverageCard extends StatelessWidget {
  const _StateDataCoverageCard({required this.stateName});

  final String stateName;

  @override
  Widget build(BuildContext context) {
    final profile = StateLotteryDataRegistry.forStateName(stateName);
    final hasPublishedActivity =
        profile.readiness == StateLotteryDataReadiness.mapDataReady;
    final hasNoStateLottery =
        profile.readiness == StateLotteryDataReadiness.noStateLottery;
    final stateRecords = LotteryActivityRepository.activity
        .where((activity) => activity.state == profile.abbreviation)
        .toList(growable: false);
    final stateCountyCount = stateRecords
        .map((activity) => activity.county)
        .toSet()
        .length;
    final color = hasNoStateLottery
        ? const Color(0xFF94A3B8)
        : profile.readiness == StateLotteryDataReadiness.mapDataReady
        ? const Color(0xFF2CC36B)
        : profile.hasOfficialSource
        ? const Color(0xFF60A5FA)
        : const Color(0xFFFFC107);
    final icon = hasNoStateLottery
        ? Icons.do_not_disturb_on_outlined
        : profile.readiness == StateLotteryDataReadiness.mapDataReady
        ? Icons.verified_outlined
        : profile.hasOfficialSource
        ? Icons.link_rounded
        : Icons.science_outlined;
    final heading = hasNoStateLottery
        ? 'NO STATE LOTTERY'
        : hasPublishedActivity
        ? 'PUBLISHED MAP ACTIVITY'
        : profile.readiness == StateLotteryDataReadiness.sourceLinked
        ? 'OFFICIAL SOURCE LINKED'
        : 'SAMPLE STATE COVERAGE';
    final detail = hasNoStateLottery
        ? '${profile.stateName} does not operate a state lottery, so Lottery Atlas has no draw, Scratch-Off, retailer, or heat-map activity to display for this state.'
        : hasPublishedActivity
        ? 'Published ${profile.stateName} activity is ready for the heat map. Game selection, prize filtering, and the timeline only use matching records.'
        : profile.readiness == StateLotteryDataReadiness.sourceLinked
        ? 'Official ${profile.providerName} links are ready. Verified county-level activity will appear here after its data feed is onboarded.'
        : 'County activity and local-game schedules are sample data. National Powerball and Mega Millions results are available separately through MUSL.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.7)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 19),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  heading,
                  style: TextStyle(
                    color: color,
                    fontSize: 10,
                    letterSpacing: 0.7,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  detail,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                _coverageSummary(profile),
                if (hasPublishedActivity) ...[
                  const SizedBox(height: 8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: const Color(0xFF071827).withValues(alpha: 0.45),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${stateRecords.length} qualifying records loaded across '
                      '$stateCountyCount ${profile.stateName} counties.',
                      style: const TextStyle(
                        color: Color(0xFFDCFCE7),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        height: 1.3,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  _sourceStatusLine(
                    context,
                    label: 'Map activity',
                    source: LotteryActivityRepository.activitySourceLabel,
                    updatedAt: LotteryActivityRepository.activityUpdatedAt,
                    isCached: LotteryActivityRepository.isCachedActivityData,
                  ),
                  if (stateName == 'South Carolina') ...[
                    const SizedBox(height: 5),
                    _sourceStatusLine(
                      context,
                      label: 'Retailer claims',
                      source: SouthCarolinaRetailerRepository.sourceLabel,
                      updatedAt: SouthCarolinaRetailerRepository.updatedAt,
                      isCached: SouthCarolinaRetailerRepository.isCached,
                    ),
                  ],
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _coverageSummary(StateLotteryDataProfile profile) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(9),
    decoration: BoxDecoration(
      color: const Color(0xFF071827).withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      profile.readiness == StateLotteryDataReadiness.noStateLottery
          ? 'No state lottery data is expected for this jurisdiction.'
          : '${profile.hasVerifiedSchedule ? 'Verified drawings' : 'Drawing schedule pending'} · '
                '${profile.hasScratchCatalog ? '${profile.scratchCatalogGameCount} verified Scratch-Off tickets' : 'Scratch-Off catalog pending'} · '
                '${profile.retailerRecordCount > 0 ? '${profile.retailerRecordCount} retailer claims' : 'Retailer feed pending'}\n'
                '${profile.historicalCoverageLabel}${profile.hasVerifiedRecordsEachYearSince2024 ? ' · live coverage verified' : ' · coverage in progress'}',
      style: const TextStyle(
        color: Color(0xFFBFDBFE),
        fontSize: 11,
        fontWeight: FontWeight.w700,
        height: 1.3,
      ),
    ),
  );

  Widget _sourceStatusLine(
    BuildContext context, {
    required String label,
    required String source,
    required DateTime? updatedAt,
    required bool isCached,
  }) {
    final dateLabel = updatedAt == null
        ? 'No feed timestamp'
        : '${MaterialLocalizations.of(context).formatMediumDate(updatedAt.toLocal())} · '
              '${MaterialLocalizations.of(context).formatTimeOfDay(TimeOfDay.fromDateTime(updatedAt.toLocal()))}';
    return Text(
      '$label · $dateLabel${isCached ? ' · saved copy' : ' · live feed'}\n$source',
      maxLines: 3,
      overflow: TextOverflow.ellipsis,
      style: const TextStyle(
        color: Color(0xFFBFDBFE),
        fontSize: 10,
        height: 1.25,
      ),
    );
  }
}
