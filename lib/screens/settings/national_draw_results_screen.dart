import 'package:flutter/material.dart';

import '../../models/favorite_lottery_game.dart';
import '../../services/favorite_games_service.dart';
import '../../services/musl_draw_service.dart';
import 'ticket_checker_screen.dart';

class NationalDrawResultsScreen extends StatefulWidget {
  const NationalDrawResultsScreen({super.key});

  @override
  State<NationalDrawResultsScreen> createState() =>
      _NationalDrawResultsScreenState();
}

class _NationalDrawResultsScreenState extends State<NationalDrawResultsScreen> {
  final MuslDrawService _service = MuslDrawService();
  late Future<List<NationalDrawResult>> _results;

  @override
  void initState() {
    super.initState();
    _results = _loadResults();
    FavoriteGamesService.load();
  }

  @override
  void dispose() {
    _service.dispose();
    super.dispose();
  }

  Future<List<NationalDrawResult>> _loadResults() async {
    return Future.wait([
      _service.latest('powerball'),
      _service.latest('mega-millions'),
    ]);
  }

  void _refresh() {
    setState(() => _results = _loadResults());
  }

  FavoriteLotteryGame _favoriteGameFor(NationalDrawResult result) {
    final normalizedName = result.gameName.toLowerCase();
    final isPowerball = normalizedName.contains('powerball');
    return FavoriteLotteryGame(
      key: isPowerball
          ? 'national-draw:powerball'
          : 'national-draw:mega-millions',
      gameId: isPowerball ? 'powerball' : 'mega-millions',
      name: isPowerball ? 'Powerball' : 'Mega Millions',
      subtitle: 'National draw game',
      kind: FavoriteLotteryGameKind.nationalDraw,
    );
  }

  Future<void> _toggleFavoriteGame(NationalDrawResult result) async {
    final favorite = _favoriteGameFor(result);
    final isSaved = await FavoriteGamesService.toggle(favorite);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          isSaved
              ? '${favorite.name} saved to favorite games.'
              : '${favorite.name} removed from favorite games.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: const Color(0xFF071827),
    appBar: AppBar(
      backgroundColor: const Color(0xFF071827),
      foregroundColor: Colors.white,
      title: const Text('National Draw Results'),
      actions: [
        IconButton(
          tooltip: 'Ticket checker',
          onPressed: () => Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const TicketCheckerScreen()),
          ),
          icon: const Icon(Icons.fact_check_outlined),
        ),
        IconButton(
          tooltip: 'Refresh',
          onPressed: _service.isConfigured ? _refresh : null,
          icon: const Icon(Icons.refresh_rounded),
        ),
      ],
    ),
    body: !_service.isConfigured
        ? const _ConnectionNeeded()
        : FutureBuilder<List<NationalDrawResult>>(
            future: _results,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Center(
                  child: CircularProgressIndicator(color: Color(0xFF1478FF)),
                );
              }
              if (snapshot.hasError) {
                return _LoadError(
                  message: snapshot.error.toString(),
                  onRetry: _refresh,
                );
              }
              final results = snapshot.data!;
              final hasCachedResults = results.any((result) => result.isCached);
              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 28),
                children: [
                  const Text(
                    'OFFICIAL NATIONAL RESULTS',
                    style: TextStyle(
                      color: Color(0xFF60A5FA),
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    hasCachedResults
                        ? 'A saved result is being shown because a live update is unavailable. Verify a ticket with the official lottery before relying on these results.'
                        : 'Powerball and Mega Millions data provided through the MUSL API. Verify a ticket with the official lottery before relying on these results.',
                    style: const TextStyle(color: Colors.white60, height: 1.35),
                  ),
                  const SizedBox(height: 18),
                  ValueListenableBuilder<List<FavoriteLotteryGame>>(
                    valueListenable: FavoriteGamesService.games,
                    builder: (context, favoriteGames, _) => Column(
                      children: results
                          .map((result) {
                            final favorite = _favoriteGameFor(result);
                            final isFavorite = favoriteGames.any(
                              (game) => game.key == favorite.key,
                            );
                            return _DrawResultCard(
                              result: result,
                              isFavorite: isFavorite,
                              onToggleFavorite: () =>
                                  _toggleFavoriteGame(result),
                            );
                          })
                          .toList(growable: false),
                    ),
                  ),
                ],
              );
            },
          ),
  );
}

class _ConnectionNeeded extends StatelessWidget {
  const _ConnectionNeeded();

  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF102638),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: const Color(0xFF355066)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.vpn_key_outlined, color: Color(0xFFFFC107), size: 38),
            SizedBox(height: 14),
            Text(
              'MUSL connection needed',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w800,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Request a free public key from MUSL, then run the app with MUSL_API_KEY. The key is not stored in this project.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white60, height: 1.35),
            ),
          ],
        ),
      ),
    ),
  );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});
  final String message;
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Center(
    child: Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded, color: Colors.white54, size: 42),
          const SizedBox(height: 12),
          const Text(
            'Could not load national draw results',
            style: TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white60),
          ),
          const SizedBox(height: 14),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try again'),
          ),
        ],
      ),
    ),
  );
}

class _DrawResultCard extends StatelessWidget {
  const _DrawResultCard({
    required this.result,
    required this.isFavorite,
    required this.onToggleFavorite,
  });
  final NationalDrawResult result;
  final bool isFavorite;
  final VoidCallback onToggleFavorite;

  String _timeLabel(DateTime dateTime) {
    final hour = dateTime.hour % 12 == 0 ? 12 : dateTime.hour % 12;
    final minute = dateTime.minute.toString().padLeft(2, '0');
    final period = dateTime.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
  }

  @override
  Widget build(BuildContext context) => Container(
    margin: const EdgeInsets.only(bottom: 14),
    padding: const EdgeInsets.all(18),
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
            Expanded(
              child: Text(
                result.gameName,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 21,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            _SourceBadge(isCached: result.isCached),
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
          ],
        ),
        const SizedBox(height: 4),
        Text(
          'Draw date: ${result.drawDate}',
          style: const TextStyle(color: Colors.white60, fontSize: 12),
        ),
        if (result.lastUpdated != null) ...[
          const SizedBox(height: 2),
          Text(
            '${result.isCached ? 'Saved' : 'Updated'} ${_timeLabel(result.lastUpdated!)}',
            style: const TextStyle(color: Colors.white38, fontSize: 11),
          ),
        ],
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ...result.numbers.map((number) => _Ball(value: number)),
            if (result.specialNumber != null)
              _Ball(value: result.specialNumber!, special: true),
          ],
        ),
        if (result.prizeText != null || result.nextPrizeText != null) ...[
          const Divider(height: 26, color: Colors.white12),
          if (result.prizeText != null)
            Text(
              'Grand prize: ${result.prizeText}',
              style: const TextStyle(color: Colors.white70),
            ),
          if (result.nextPrizeText != null) ...[
            const SizedBox(height: 4),
            Text(
              'Next estimated prize: ${result.nextPrizeText}',
              style: const TextStyle(
                color: Color(0xFF60A5FA),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ],
    ),
  );
}

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.isCached});

  final bool isCached;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: isCached ? const Color(0x33FFC107) : const Color(0x332CC36B),
      borderRadius: BorderRadius.circular(99),
      border: Border.all(
        color: isCached ? const Color(0xFFFFC107) : const Color(0xFF2CC36B),
      ),
    ),
    child: Text(
      isCached ? 'SAVED' : 'LIVE',
      style: TextStyle(
        color: isCached ? const Color(0xFFFFC107) : const Color(0xFF86EFAC),
        fontSize: 10,
        fontWeight: FontWeight.w800,
        letterSpacing: 0.6,
      ),
    ),
  );
}

class _Ball extends StatelessWidget {
  const _Ball({required this.value, this.special = false});
  final String value;
  final bool special;
  @override
  Widget build(BuildContext context) => Container(
    width: 38,
    height: 38,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: special ? const Color(0xFFE94B6A) : Colors.white,
      shape: BoxShape.circle,
    ),
    child: Text(
      value,
      style: TextStyle(
        color: special ? Colors.white : const Color(0xFF071827),
        fontWeight: FontWeight.w800,
      ),
    ),
  );
}
