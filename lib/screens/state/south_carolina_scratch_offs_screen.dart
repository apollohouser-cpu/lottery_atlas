import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../models/favorite_lottery_game.dart';
import '../../models/south_carolina_scratch_game.dart';
import '../../services/favorite_games_service.dart';
import '../../services/lottery_activity_repository.dart';
import '../../services/south_carolina_scratch_catalog.dart';
import '../../services/south_carolina_scratch_catalog_feed_service.dart';
import '../../services/south_carolina_scratch_map_filter_service.dart';

class SouthCarolinaScratchOffsScreen extends StatefulWidget {
  const SouthCarolinaScratchOffsScreen({super.key, this.initialGameId});

  final String? initialGameId;

  @override
  State<SouthCarolinaScratchOffsScreen> createState() =>
      _SouthCarolinaScratchOffsScreenState();
}

class _SouthCarolinaScratchOffsScreenState
    extends State<SouthCarolinaScratchOffsScreen> {
  static const MethodChannel _magicMouseChannel = MethodChannel(
    'lottery_atlas/magic_mouse',
  );

  static const _prizeStops = <int>[
    1,
    5,
    10,
    20,
    50,
    100,
    250,
    500,
    1000,
    5000,
    10000,
    25000,
    50000,
    100000,
    200000,
    500000,
    1000000,
    2500000,
  ];

  String _selectedGameId = 'all';
  int _minimumPrize = 1;
  int _maximumPrize = 2500000;
  late SouthCarolinaScratchCatalogSnapshot _catalogSnapshot;
  bool _isRefreshingCatalog = false;

  @override
  void initState() {
    super.initState();
    _catalogSnapshot = SouthCarolinaScratchCatalogFeedService.builtInSnapshot();
    _selectedGameId = widget.initialGameId ?? 'all';
    _magicMouseChannel.invokeMethod<void>('setMapActive', false);
    FavoriteGamesService.load();
    _refreshCatalog();
  }

  @override
  void dispose() {
    _magicMouseChannel.invokeMethod<void>('setMapActive', true);
    super.dispose();
  }

  Future<void> _openOfficialSource() async {
    final opened = await launchUrl(
      Uri.parse(SouthCarolinaScratchCatalog.officialSourceUrl),
      mode: LaunchMode.externalApplication,
    );
    if (!opened && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Could not open the official SC Lottery page.'),
        ),
      );
    }
  }

  List<SouthCarolinaScratchGame> get _visibleGames {
    final selected = _selectedGameId == 'all'
        ? _catalogSnapshot.games
        : _catalogSnapshot.games
              .where((game) => game.id == _selectedGameId)
              .toList();
    return selected
        .where(
          (game) => game
              .matchingTiers(
                minimumPrize: _minimumPrize,
                maximumPrize: _maximumPrize,
              )
              .isNotEmpty,
        )
        .toList()
      ..sort((a, b) => b.topPrize.compareTo(a.topPrize));
  }

  @override
  Widget build(BuildContext context) {
    final games = _visibleGames;
    final totalClaims = games.fold<int>(
      0,
      (total, game) =>
          total +
          game.claimsInRange(
            minimumPrize: _minimumPrize,
            maximumPrize: _maximumPrize,
          ),
    );
    final mapFilter = SouthCarolinaScratchMapFilter(
      gameId: _selectedGameId,
      minimumPrize: _minimumPrize,
      maximumPrize: _maximumPrize,
      gameNameOverride: _selectedGameName,
    );
    final matchingMapRecords = LotteryActivityRepository.activity
        .where(mapFilter.matches)
        .toList();

    return Scaffold(
      backgroundColor: const Color(0xFF071827),
      appBar: AppBar(
        backgroundColor: const Color(0xFF071827),
        foregroundColor: Colors.white,
        title: const Text('SC Scratch-Off Finder'),
        actions: [
          IconButton(
            tooltip: 'Open official daily winners',
            onPressed: _openOfficialSource,
            icon: const Icon(Icons.open_in_new_rounded),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          _SourceCard(
            snapshot: _catalogSnapshot,
            isRefreshing: _isRefreshingCatalog,
            onOpenSource: _openOfficialSource,
            onRefresh: _refreshCatalog,
          ),
          const SizedBox(height: 18),
          const Text(
            'FIND A PRIZE TIER',
            style: TextStyle(
              color: Color(0xFF60A5FA),
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.1,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Choose a Scratch-Off game and the prize range you want to explore.',
            style: TextStyle(color: Colors.white70, height: 1.35),
          ),
          const SizedBox(height: 14),
          _FilterCard(
            games: _catalogSnapshot.games,
            selectedGameId: _selectedGameId,
            minimumPrize: _minimumPrize,
            maximumPrize: _maximumPrize,
            onGameChanged: (id) => setState(() => _selectedGameId = id),
            onMinimumChanged: (value) {
              setState(() {
                _minimumPrize = value;
                if (_maximumPrize < value) _maximumPrize = value;
              });
            },
            onMaximumChanged: (value) {
              setState(() {
                _maximumPrize = value;
                if (_minimumPrize > value) _minimumPrize = value;
              });
            },
          ),
          const SizedBox(height: 18),
          _ResultsSummary(gameCount: games.length, claimCount: totalClaims),
          const SizedBox(height: 10),
          _MapCoverageCard(recordCount: matchingMapRecords.length),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: games.isEmpty ? null : _showMatchingMapActivity,
              icon: const Icon(Icons.map_outlined),
              label: Text(
                matchingMapRecords.isEmpty
                    ? 'Show this filter on map'
                    : 'Show ${matchingMapRecords.length} matching map record${matchingMapRecords.length == 1 ? '' : 's'}',
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF1478FF),
                foregroundColor: Colors.white,
                minimumSize: const Size.fromHeight(48),
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Map records are published official \$500+ claimed-ticket reports. Their retailer city and county are retained, while map points are centered on the county for the heat index. They are separate from the statewide daily prize-tier counts above.',
            style: TextStyle(color: Colors.white54, fontSize: 11, height: 1.3),
          ),
          const SizedBox(height: 14),
          if (games.isEmpty)
            const _EmptyResults()
          else
            ValueListenableBuilder<List<FavoriteLotteryGame>>(
              valueListenable: FavoriteGamesService.games,
              builder: (context, favoriteGames, _) => Column(
                children: games
                    .map(
                      (game) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ScratchGameCard(
                          game: game,
                          minimumPrize: _minimumPrize,
                          maximumPrize: _maximumPrize,
                          onOpenSource: _openOfficialSource,
                          isFavorite: favoriteGames.any(
                            (favorite) =>
                                favorite.key == 'sc-scratch:${game.id}',
                          ),
                          onToggleFavorite: () => _toggleFavoriteGame(game),
                        ),
                      ),
                    )
                    .toList(growable: false),
              ),
            ),
        ],
      ),
    );
  }

  void _showMatchingMapActivity() {
    SouthCarolinaScratchMapFilterService.apply(
      SouthCarolinaScratchMapFilter(
        gameId: _selectedGameId,
        minimumPrize: _minimumPrize,
        maximumPrize: _maximumPrize,
        gameNameOverride: _selectedGameName,
      ),
    );
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  String? get _selectedGameName {
    if (_selectedGameId == 'all') return null;
    for (final game in _catalogSnapshot.games) {
      if (game.id == _selectedGameId) return game.name;
    }
    return null;
  }

  Future<void> _refreshCatalog() async {
    if (_isRefreshingCatalog) return;
    setState(() => _isRefreshingCatalog = true);
    final snapshot = await SouthCarolinaScratchCatalogFeedService.load();
    if (!mounted) return;

    setState(() {
      _catalogSnapshot = snapshot;
      _isRefreshingCatalog = false;
      if (_selectedGameId != 'all' &&
          !_catalogSnapshot.games.any((game) => game.id == _selectedGameId)) {
        _selectedGameId = 'all';
      }
    });
  }

  FavoriteLotteryGame _favoriteGame(SouthCarolinaScratchGame game) =>
      FavoriteLotteryGame(
        key: 'sc-scratch:${game.id}',
        gameId: game.id,
        name: game.displayName,
        subtitle: 'South Carolina Scratch-Off',
        kind: FavoriteLotteryGameKind.scratchOff,
      );

  Future<void> _toggleFavoriteGame(SouthCarolinaScratchGame game) async {
    final isSaved = await FavoriteGamesService.toggle(_favoriteGame(game));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSaved
              ? '${game.displayName} saved to favorite games.'
              : '${game.displayName} removed from favorite games.',
        ),
      ),
    );
  }
}

class _MapCoverageCard extends StatelessWidget {
  const _MapCoverageCard({required this.recordCount});

  final int recordCount;

  @override
  Widget build(BuildContext context) {
    final hasCoverage = recordCount > 0;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hasCoverage ? const Color(0xFF0D2A30) : const Color(0xFF102638),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: hasCoverage
              ? const Color(0xFF1FAF77)
              : const Color(0xFF355066),
        ),
      ),
      child: Row(
        children: [
          Icon(
            hasCoverage ? Icons.location_on_outlined : Icons.info_outline,
            color: hasCoverage
                ? const Color(0xFF86EFAC)
                : const Color(0xFF93C5FD),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              hasCoverage
                  ? '$recordCount published claimed-ticket record${recordCount == 1 ? '' : 's'} match this selection.'
                  : 'No published \$500+ claimed-ticket record matches this selection in the current report window. The statewide claimed-prize totals are still shown above.',
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.snapshot,
    required this.isRefreshing,
    required this.onOpenSource,
    required this.onRefresh,
  });

  final SouthCarolinaScratchCatalogSnapshot snapshot;
  final bool isRefreshing;
  final VoidCallback onOpenSource;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: const Color(0xFF102638),
      borderRadius: BorderRadius.circular(18),
      border: Border.all(color: const Color(0xFF355066)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.verified_outlined, color: Color(0xFF86EFAC)),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                snapshot.isPublished
                    ? snapshot.isCached
                          ? 'SAVED SOUTH CAROLINA SNAPSHOT'
                          : 'PUBLISHED SOUTH CAROLINA SNAPSHOT'
                    : 'BUILT-IN SOUTH CAROLINA SNAPSHOT',
                style: const TextStyle(
                  color: Color(0xFF86EFAC),
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.05,
                ),
              ),
            ),
            IconButton(
              tooltip: 'Refresh Scratch-Off data',
              onPressed: isRefreshing ? null : onRefresh,
              icon: isRefreshing
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh_rounded, size: 20),
              color: const Color(0xFF93C5FD),
            ),
          ],
        ),
        const SizedBox(height: 9),
        Row(
          children: [
            const Icon(
              Icons.schedule_rounded,
              size: 16,
              color: Color(0xFF93C5FD),
            ),
            const SizedBox(width: 7),
            Text(
              'Snapshot: ${_formatSnapshotDate(snapshot.updatedAt)}',
              style: const TextStyle(
                color: Color(0xFFBFDBFE),
                fontSize: 12,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 9),
        if (snapshot.duplicateGames > 0 || snapshot.rejectedGames > 0) ...[
          Text(
            '${snapshot.games.length} valid games loaded'
            '${snapshot.duplicateGames > 0 ? ' • ${snapshot.duplicateGames} duplicate${snapshot.duplicateGames == 1 ? '' : 's'} removed' : ''}'
            '${snapshot.rejectedGames > 0 ? ' • ${snapshot.rejectedGames} invalid game${snapshot.rejectedGames == 1 ? '' : 's'} skipped' : ''}',
            style: const TextStyle(
              color: Color(0xFF93C5FD),
              fontSize: 11,
              height: 1.3,
            ),
          ),
          const SizedBox(height: 9),
        ],
        const Text(
          'Daily claimed Scratch-Off winners, reported by game and prize tier. A zero means no claims in that tier during this daily snapshot—it does not mean the prize is unavailable.',
          style: TextStyle(color: Colors.white70, height: 1.35),
        ),
        const SizedBox(height: 12),
        TextButton.icon(
          onPressed: onOpenSource,
          icon: const Icon(Icons.open_in_new_rounded, size: 18),
          label: const Text('Verify on SC Education Lottery'),
          style: TextButton.styleFrom(foregroundColor: const Color(0xFF60A5FA)),
        ),
      ],
    ),
  );
}

String _formatSnapshotDate(DateTime timestamp) {
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
  return '${months[timestamp.month - 1]} ${timestamp.day}, ${timestamp.year}';
}

class _FilterCard extends StatelessWidget {
  const _FilterCard({
    required this.games,
    required this.selectedGameId,
    required this.minimumPrize,
    required this.maximumPrize,
    required this.onGameChanged,
    required this.onMinimumChanged,
    required this.onMaximumChanged,
  });

  final List<SouthCarolinaScratchGame> games;
  final String selectedGameId;
  final int minimumPrize;
  final int maximumPrize;
  final ValueChanged<String> onGameChanged;
  final ValueChanged<int> onMinimumChanged;
  final ValueChanged<int> onMaximumChanged;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(14),
    decoration: BoxDecoration(
      color: const Color(0xFF102638),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF355066)),
    ),
    child: Column(
      children: [
        DropdownButtonFormField<String>(
          initialValue: selectedGameId,
          isExpanded: true,
          dropdownColor: const Color(0xFF102638),
          decoration: _decoration('Scratch-Off game'),
          style: const TextStyle(color: Colors.white),
          items: [
            const DropdownMenuItem<String>(
              value: 'all',
              child: Text('All active games'),
            ),
            ...games.map(
              (game) => DropdownMenuItem<String>(
                value: game.id,
                child: Text(game.displayName, overflow: TextOverflow.ellipsis),
              ),
            ),
          ],
          onChanged: (id) {
            if (id != null) onGameChanged(id);
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _PrizeDropdown(
                label: 'Minimum prize',
                value: minimumPrize,
                onChanged: onMinimumChanged,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _PrizeDropdown(
                label: 'Maximum prize',
                value: maximumPrize,
                onChanged: onMaximumChanged,
              ),
            ),
          ],
        ),
      ],
    ),
  );

  InputDecoration _decoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: const TextStyle(color: Colors.white60),
    filled: true,
    fillColor: const Color(0xFF0B1D2C),
    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF355066)),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF1478FF), width: 1.5),
    ),
  );
}

class _PrizeDropdown extends StatelessWidget {
  const _PrizeDropdown({
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final String label;
  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => DropdownButtonFormField<int>(
    initialValue: value,
    isExpanded: true,
    dropdownColor: const Color(0xFF102638),
    decoration: InputDecoration(
      labelText: label,
      labelStyle: const TextStyle(color: Colors.white60),
      filled: true,
      fillColor: const Color(0xFF0B1D2C),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF355066)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFF1478FF), width: 1.5),
      ),
    ),
    style: const TextStyle(color: Colors.white),
    items: _SouthCarolinaScratchOffsScreenState._prizeStops
        .map(
          (amount) => DropdownMenuItem(
            value: amount,
            child: Text(_money(amount), overflow: TextOverflow.ellipsis),
          ),
        )
        .toList(),
    onChanged: (amount) {
      if (amount != null) onChanged(amount);
    },
  );
}

class _ResultsSummary extends StatelessWidget {
  const _ResultsSummary({required this.gameCount, required this.claimCount});

  final int gameCount;
  final int claimCount;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          '$gameCount game${gameCount == 1 ? '' : 's'} match this prize range',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      Text(
        '$claimCount daily claims',
        style: const TextStyle(color: Color(0xFF86EFAC), fontSize: 12),
      ),
    ],
  );
}

class _EmptyResults extends StatelessWidget {
  const _EmptyResults();

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(
      color: const Color(0xFF102638),
      borderRadius: BorderRadius.circular(16),
      border: Border.all(color: const Color(0xFF355066)),
    ),
    child: const Column(
      children: [
        Icon(Icons.search_off_rounded, color: Colors.white54, size: 36),
        SizedBox(height: 10),
        Text(
          'No listed prize tiers match this range.',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 4),
        Text(
          'Try widening the minimum or maximum prize.',
          style: TextStyle(color: Colors.white60),
          textAlign: TextAlign.center,
        ),
      ],
    ),
  );
}

class _ScratchGameCard extends StatelessWidget {
  const _ScratchGameCard({
    required this.game,
    required this.minimumPrize,
    required this.maximumPrize,
    required this.onOpenSource,
    required this.isFavorite,
    required this.onToggleFavorite,
  });

  final SouthCarolinaScratchGame game;
  final int minimumPrize;
  final int maximumPrize;
  final VoidCallback onOpenSource;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final tiers = game.matchingTiers(
      minimumPrize: minimumPrize,
      maximumPrize: maximumPrize,
    );
    final claims = game.claimsInRange(
      minimumPrize: minimumPrize,
      maximumPrize: maximumPrize,
    );

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFF102638),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF355066)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.confirmation_number_outlined,
                  color: Color(0xFF60A5FA),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  game.displayName,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                tooltip: isFavorite
                    ? 'Remove from favorite games'
                    : 'Save to favorite games',
                onPressed: onToggleFavorite,
                icon: Icon(
                  isFavorite
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: isFavorite ? const Color(0xFFE94B6A) : Colors.white70,
                ),
              ),
              Text(
                'Top ${_money(game.topPrize)}',
                style: const TextStyle(
                  color: Color(0xFF86EFAC),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            '$claims prize claims in the selected range yesterday',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              ...tiers.take(7).map((tier) => _PrizeTierChip(tier: tier)),
              if (tiers.length > 7)
                Chip(
                  label: Text('+${tiers.length - 7} more'),
                  backgroundColor: const Color(0xFF0B1D2C),
                  side: const BorderSide(color: Color(0xFF355066)),
                  labelStyle: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                  visualDensity: VisualDensity.compact,
                ),
            ],
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: onOpenSource,
              child: const Text('Official daily table'),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrizeTierChip extends StatelessWidget {
  const _PrizeTierChip({required this.tier});

  final SouthCarolinaScratchPrizeTier tier;

  @override
  Widget build(BuildContext context) => Chip(
    label: Text('${_money(tier.amount)} · ${tier.claimedYesterday}'),
    backgroundColor: const Color(0xFF0B1D2C),
    side: const BorderSide(color: Color(0xFF355066)),
    labelStyle: const TextStyle(color: Colors.white70, fontSize: 11),
    visualDensity: VisualDensity.compact,
  );
}

String _money(int amount) {
  if (amount >= 1000000) {
    final millions = amount / 1000000;
    return r'$' +
        millions.toStringAsFixed(millions == millions.roundToDouble() ? 0 : 1) +
        'M';
  }
  if (amount >= 1000) return r'$' + (amount / 1000).toStringAsFixed(0) + 'K';
  return r'$' + amount.toString();
}
