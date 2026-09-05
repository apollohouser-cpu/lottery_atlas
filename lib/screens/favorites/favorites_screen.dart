import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/favorite_lottery_game.dart';
import '../../models/favorite_place.dart';
import '../../models/lottery_activity.dart';
import '../../services/favorite_games_service.dart';
import '../../services/favorite_places_service.dart';
import '../../services/lottery_activity_repository.dart';
import '../../services/map_focus_service.dart';
import '../../services/south_carolina_lottery_map_filter_service.dart';
import '../../services/south_carolina_scratch_map_filter_service.dart';
import '../../widgets/map/map_filter_state.dart';
import '../games/games_screen.dart';
import '../settings/national_draw_results_screen.dart';
import '../state/south_carolina_scratch_offs_screen.dart';

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  static const String _locationStorageKey =
      'lottery_atlas.favorite_activity_keys';

  final SharedPreferencesAsync _preferences = SharedPreferencesAsync();
  bool _isLoading = true;
  Set<String> _favoriteLocationKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _loadLocationFavorites();
    FavoriteGamesService.load();
    FavoritePlacesService.load();
  }

  Future<void> _loadLocationFavorites() async {
    final savedKeys = await _preferences.getStringList(_locationStorageKey);
    if (!mounted) return;
    setState(() {
      _favoriteLocationKeys =
          savedKeys?.toSet() ??
          LotteryActivityRepository.activity
              .where((activity) => activity.isFavorite)
              .map((activity) => activity.id)
              .toSet();
      _isLoading = false;
    });
  }

  Future<void> _removeFavoriteLocation(LotteryActivity activity) async {
    final updatedKeys = Set<String>.from(_favoriteLocationKeys)
      ..remove(activity.id);
    setState(() => _favoriteLocationKeys = updatedKeys);
    await _preferences.setStringList(_locationStorageKey, updatedKeys.toList());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${activity.city} removed from favorite locations.'),
      ),
    );
  }

  Future<void> _removeFavoriteGame(FavoriteLotteryGame game) async {
    await FavoriteGamesService.remove(game.key);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${game.name} removed from favorite games.')),
    );
  }

  Future<void> _removeFavoritePlace(FavoritePlace place) async {
    await FavoritePlacesService.remove(place.key);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${place.title} removed from favorite places.')),
    );
  }

  void _openFavoritePlace(FavoritePlace place) {
    switch (place.kind) {
      case FavoritePlaceKind.state:
        MapFocusService.focusState(place.stateName);
      case FavoritePlaceKind.county:
        final countyId = place.countyId;
        if (countyId == null) return;
        MapFocusService.focusCounty(
          stateName: place.stateName,
          countyId: countyId,
        );
      case FavoritePlaceKind.retailer:
        final retailerId = place.retailerId;
        if (retailerId == null) return;
        MapFocusService.focusRetailer(
          stateName: place.stateName,
          retailerId: retailerId,
        );
    }
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  void _openFavoriteGame(FavoriteLotteryGame game) {
    switch (game.kind) {
      case FavoriteLotteryGameKind.scratchOff:
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                SouthCarolinaScratchOffsScreen(initialGameId: game.gameId),
          ),
        );
      case FavoriteLotteryGameKind.draw:
        final matchingGames = LotteryGame.values.where(
          (item) => item.name == game.gameId,
        );
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => GamesScreen(
              initialGame: matchingGames.isEmpty
                  ? LotteryGame.allGames
                  : matchingGames.first,
            ),
          ),
        );
      case FavoriteLotteryGameKind.nationalDraw:
        Navigator.of(context).push(
          MaterialPageRoute(builder: (_) => const NationalDrawResultsScreen()),
        );
      case FavoriteLotteryGameKind.stateDraw:
        final gameName = _southCarolinaMapGameName(game.gameId);
        final matchingFilter = SouthCarolinaLotteryMapFilter.drawGames.where(
          (filter) => filter.gameName == gameName,
        );
        if (matchingFilter.isEmpty) return;
        SouthCarolinaScratchMapFilterService.clear();
        SouthCarolinaLotteryMapFilterService.apply(matchingFilter.first);
        Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  String _southCarolinaMapGameName(String name) {
    final normalized = name.toLowerCase();
    if (normalized.startsWith('pick 3')) return 'Pick 3';
    if (normalized.startsWith('pick 4')) return 'Pick 4';
    if (normalized.startsWith('cash pop')) return 'Cash Pop';
    return name;
  }

  @override
  Widget build(BuildContext context) {
    final favoriteLocations =
        LotteryActivityRepository.activity
            .where((activity) => _favoriteLocationKeys.contains(activity.id))
            .toList()
          ..sort((a, b) => b.drawDate.compareTo(a.drawDate));

    return Scaffold(
      backgroundColor: const Color(0xFF071827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071827),
        foregroundColor: Colors.white,
        title: const Text('Favorites'),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1478FF)),
            )
          : AnimatedBuilder(
              animation: Listenable.merge([
                FavoriteGamesService.games,
                FavoritePlacesService.places,
              ]),
              builder: (context, _) {
                final favoriteGames = FavoriteGamesService.games.value;
                final favoritePlaces = FavoritePlacesService.places.value;
                if (favoriteGames.isEmpty &&
                    favoritePlaces.isEmpty &&
                    favoriteLocations.isEmpty) {
                  return const _EmptyFavorites();
                }

                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    if (favoritePlaces.isNotEmpty) ...[
                      const _SectionLabel('FAVORITE PLACES'),
                      const SizedBox(height: 8),
                      ...favoritePlaces.map(
                        (place) => _FavoritePlaceCard(
                          place: place,
                          onOpen: () => _openFavoritePlace(place),
                          onRemove: () => _removeFavoritePlace(place),
                        ),
                      ),
                    ],
                    if (favoriteGames.isNotEmpty) ...[
                      if (favoritePlaces.isNotEmpty) const SizedBox(height: 14),
                      const _SectionLabel('FAVORITE GAMES'),
                      const SizedBox(height: 8),
                      ...favoriteGames.map(
                        (game) => _FavoriteGameCard(
                          game: game,
                          onOpen: () => _openFavoriteGame(game),
                          onRemove: () => _removeFavoriteGame(game),
                        ),
                      ),
                    ],
                    if (favoriteLocations.isNotEmpty) ...[
                      if (favoritePlaces.isNotEmpty || favoriteGames.isNotEmpty)
                        const SizedBox(height: 14),
                      const _SectionLabel('FAVORITE HEAT LOCATIONS'),
                      const SizedBox(height: 8),
                      ...favoriteLocations.map(
                        (activity) => _FavoriteLocationCard(
                          activity: activity,
                          onRemove: () => _removeFavoriteLocation(activity),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
    );
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) => Text(
    label,
    style: const TextStyle(
      color: Color(0xFF60A5FA),
      fontSize: 12,
      letterSpacing: 1.1,
      fontWeight: FontWeight.w800,
    ),
  );
}

class _FavoriteGameCard extends StatelessWidget {
  const _FavoriteGameCard({
    required this.game,
    required this.onOpen,
    required this.onRemove,
  });

  final FavoriteLotteryGame game;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF102638),
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      onTap: onOpen,
      leading: CircleAvatar(
        backgroundColor: const Color(0x261478FF),
        child: Icon(
          game.kind == FavoriteLotteryGameKind.scratchOff
              ? Icons.confirmation_number_outlined
              : game.kind == FavoriteLotteryGameKind.stateDraw
              ? Icons.schedule_rounded
              : Icons.casino_outlined,
          color: const Color(0xFF60A5FA),
        ),
      ),
      title: Text(
        game.name,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        game.subtitle,
        style: const TextStyle(color: Colors.white60),
      ),
      trailing: IconButton(
        tooltip: 'Remove favorite game',
        icon: const Icon(Icons.favorite_rounded, color: Color(0xFFE94B6A)),
        onPressed: onRemove,
      ),
    ),
  );
}

class _FavoritePlaceCard extends StatelessWidget {
  const _FavoritePlaceCard({
    required this.place,
    required this.onOpen,
    required this.onRemove,
  });

  final FavoritePlace place;
  final VoidCallback onOpen;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final icon = switch (place.kind) {
      FavoritePlaceKind.state => Icons.map_outlined,
      FavoritePlaceKind.county => Icons.account_tree_outlined,
      FavoritePlaceKind.retailer => Icons.storefront_outlined,
    };
    return Card(
      color: const Color(0xFF102638),
      margin: const EdgeInsets.only(bottom: 10),
      child: ListTile(
        onTap: onOpen,
        leading: CircleAvatar(
          backgroundColor: const Color(0x261478FF),
          child: Icon(icon, color: const Color(0xFF60A5FA)),
        ),
        title: Text(
          place.title,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
        subtitle: Text(
          place.subtitle,
          style: const TextStyle(color: Colors.white60),
        ),
        trailing: IconButton(
          tooltip: 'Remove favorite place',
          icon: const Icon(Icons.favorite_rounded, color: Color(0xFFE94B6A)),
          onPressed: onRemove,
        ),
      ),
    );
  }
}

class _FavoriteLocationCard extends StatelessWidget {
  const _FavoriteLocationCard({required this.activity, required this.onRemove});

  final LotteryActivity activity;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xFF102638),
    margin: const EdgeInsets.only(bottom: 10),
    child: ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0x331478FF),
        child: Icon(Icons.location_on_rounded, color: Color(0xFF1478FF)),
      ),
      title: Text(
        '${activity.city}, ${activity.state}',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
      ),
      subtitle: Text(
        '${activity.game.label} • ${activity.county}\n'
        '${activity.winningTickets} winning tickets • '
        '${activity.formattedPrizeAmount} top prize',
        style: const TextStyle(color: Colors.white60),
      ),
      isThreeLine: true,
      trailing: IconButton(
        tooltip: 'Remove favorite location',
        icon: const Icon(Icons.favorite_rounded, color: Color(0xFFE94B6A)),
        onPressed: onRemove,
      ),
    ),
  );
}

class _EmptyFavorites extends StatelessWidget {
  const _EmptyFavorites();

  @override
  Widget build(BuildContext context) => const Center(
    child: Padding(
      padding: EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border_rounded, size: 60, color: Colors.white38),
          SizedBox(height: 16),
          Text(
            'No favorites yet',
            style: TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Save a game from its detail card or save a map activity point to reach it quickly here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white60),
          ),
        ],
      ),
    ),
  );
}
