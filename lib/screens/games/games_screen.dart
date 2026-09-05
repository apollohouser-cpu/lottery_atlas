import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/favorite_lottery_game.dart';
import '../../models/lottery_activity.dart';
import '../../services/favorite_games_service.dart';
import '../../services/lottery_activity_repository.dart';
import '../../widgets/map/map_filter_state.dart';

class GamesScreen extends StatefulWidget {
  const GamesScreen({
    super.key,
    this.initialGame = LotteryGame.allGames,
  });

  final LotteryGame initialGame;

  @override
  State<GamesScreen> createState() => _GamesScreenState();
}

class _GamesScreenState extends State<GamesScreen> {
  static const _storageKey = 'lottery_atlas.favorite_activity_keys';
  final _preferences = SharedPreferencesAsync();
  final _searchController = TextEditingController();
  late LotteryGame _selectedGame;
  Set<String> _favoriteKeys = <String>{};

  @override
  void initState() {
    super.initState();
    _selectedGame = widget.initialGame;
    _loadFavorites();
    FavoriteGamesService.load();
    _searchController.addListener(_refresh);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refresh)
      ..dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _loadFavorites() async {
    final savedKeys = await _preferences.getStringList(_storageKey);
    if (!mounted) return;
    setState(() {
      _favoriteKeys =
          savedKeys?.toSet() ??
          LotteryActivityRepository.activity
              .where((item) => item.isFavorite)
              .map((item) => item.id)
              .toSet();
    });
  }

  Future<void> _toggleFavorite(LotteryActivity activity) async {
    final keys = Set<String>.from(_favoriteKeys);
    keys.contains(activity.id)
        ? keys.remove(activity.id)
        : keys.add(activity.id);
    setState(() => _favoriteKeys = keys);
    await _preferences.setStringList(_storageKey, keys.toList());
  }

  FavoriteLotteryGame _favoriteGame(LotteryGame game) => FavoriteLotteryGame(
    key: 'draw:${game.name}',
    gameId: game.name,
    name: game.label,
    subtitle: game == LotteryGame.scratchOff
        ? 'Lottery game'
        : 'National and draw game',
    kind: FavoriteLotteryGameKind.draw,
  );

  Future<void> _toggleFavoriteGame(LotteryGame game) async {
    final isSaved = await FavoriteGamesService.toggle(_favoriteGame(game));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSaved
              ? '${game.label} saved to favorite games.'
              : '${game.label} removed from favorite games.',
        ),
      ),
    );
  }

  List<LotteryActivity> get _visibleActivity {
    final query = _searchController.text.trim().toLowerCase();
    final activity = LotteryActivityRepository.activity.where((item) {
      final matchesGame =
          _selectedGame == LotteryGame.allGames || item.game == _selectedGame;
      final text =
          '${item.city} ${item.county} ${item.state} ${item.game.label}'
              .toLowerCase();
      return matchesGame && (query.isEmpty || text.contains(query));
    }).toList();
    activity.sort((a, b) => b.drawDate.compareTo(a.drawDate));
    return activity;
  }

  void _showDetails(LotteryActivity item) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF102638),
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 8, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${item.city}, ${item.state}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.county} • ${item.game.label}',
                style: const TextStyle(color: Colors.white60),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _DetailMetric(
                      label: 'WINNING TICKETS',
                      value: '${item.winningTickets}',
                    ),
                  ),
                  Expanded(
                    child: _DetailMetric(
                      label: 'TOP PRIZE',
                      value: item.formattedPrizeAmount,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'Sample activity data — official lottery results will replace these records when sources are connected.',
                style: TextStyle(color: Colors.white54, fontSize: 12),
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<List<FavoriteLotteryGame>>(
                valueListenable: FavoriteGamesService.games,
                builder: (context, favoriteGames, _) {
                  final isFavorite = favoriteGames.any(
                    (favorite) => favorite.key == 'draw:${item.game.name}',
                  );
                  return SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => _toggleFavoriteGame(item.game),
                      icon: Icon(
                        isFavorite
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                      ),
                      label: Text(
                        isFavorite
                            ? 'Remove ${item.game.label} from favorite games'
                            : 'Save ${item.game.label} to favorite games',
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
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final activity = _visibleActivity;
    return Scaffold(
      backgroundColor: const Color(0xFF071827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071827),
        foregroundColor: Colors.white,
        title: const Text('Lottery Activity'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 12),
            child: TextField(
              controller: _searchController,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Search city, county, state, or game',
                hintStyle: const TextStyle(color: Colors.white54),
                prefixIcon: const Icon(Icons.search_rounded),
                filled: true,
                fillColor: const Color(0xFF102638),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF355066)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: Color(0xFF1478FF)),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: LotteryGame.values.map((game) {
                final selected = game == _selectedGame;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(game.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _selectedGame = game),
                    selectedColor: const Color(0xFF1478FF),
                    backgroundColor: const Color(0xFF102638),
                    labelStyle: TextStyle(
                      color: Colors.white,
                      fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    ),
                    side: const BorderSide(color: Color(0xFF355066)),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: activity.isEmpty
                ? const Center(
                    child: Text(
                      'No activity matches those filters.',
                      style: TextStyle(color: Colors.white60),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: activity.length,
                    itemBuilder: (context, index) {
                      final item = activity[index];
                      final favorite = _favoriteKeys.contains(item.id);
                      return Card(
                        color: const Color(0xFF102638),
                        margin: const EdgeInsets.only(bottom: 10),
                        child: ListTile(
                          onTap: () => _showDetails(item),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 6,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: _gameColor(
                              item.game,
                            ).withValues(alpha: .20),
                            child: Icon(
                              item.game.icon,
                              color: _gameColor(item.game),
                            ),
                          ),
                          title: Text(
                            '${item.city}, ${item.state}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          subtitle: Text(
                            '${item.game.label} • ${item.county}\n${item.winningTickets} winning tickets • ${item.formattedPrizeAmount}',
                            style: const TextStyle(color: Colors.white60),
                          ),
                          isThreeLine: true,
                          trailing: IconButton(
                            tooltip: favorite
                                ? 'Remove favorite'
                                : 'Add favorite',
                            onPressed: () => _toggleFavorite(item),
                            icon: Icon(
                              favorite
                                  ? Icons.favorite_rounded
                                  : Icons.favorite_border_rounded,
                              color: favorite
                                  ? const Color(0xFFE94B6A)
                                  : Colors.white54,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Color _gameColor(LotteryGame game) {
    switch (game) {
      case LotteryGame.powerball:
        return const Color(0xFFE94B6A);
      case LotteryGame.megaMillions:
        return const Color(0xFFFFC107);
      case LotteryGame.scratchOff:
        return const Color(0xFF2CC36B);
      case LotteryGame.stateDraw:
        return const Color(0xFF7C5CFC);
      case LotteryGame.allGames:
        return const Color(0xFF1478FF);
    }
  }
}

class _DetailMetric extends StatelessWidget {
  const _DetailMetric({required this.label, required this.value});
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(right: 8),
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF071827),
      borderRadius: BorderRadius.circular(12),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white54,
            fontSize: 10,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    ),
  );
}
