import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/south_carolina_scratch_game.dart';
import 'south_carolina_scratch_catalog.dart';

/// Retrieves the latest published South Carolina Scratch-Off snapshot.
///
/// The built-in catalog remains available when the device is offline or when a
/// new published file is malformed, so the prize finder always stays usable.
class SouthCarolinaScratchCatalogFeedService {
  SouthCarolinaScratchCatalogFeedService._();

  static const String _feedUrl = String.fromEnvironment(
    'SOUTH_CAROLINA_SCRATCH_FEED_URL',
    defaultValue:
        'https://lottery-atlas-activity-feed.apollohouser.chatgpt.site/south-carolina-scratch-offs.json',
  );
  static const String _cacheKey = 'lottery_atlas.sc_scratch_catalog.v1';
  static final SharedPreferencesAsync _store = SharedPreferencesAsync();

  static SouthCarolinaScratchCatalogSnapshot builtInSnapshot() {
    return SouthCarolinaScratchCatalogSnapshot(
      games: SouthCarolinaScratchCatalog.games,
      updatedAt: SouthCarolinaScratchCatalog.snapshotUpdatedAt,
      sourceUrl: SouthCarolinaScratchCatalog.officialSourceUrl,
      isPublished: false,
      isCached: false,
      rejectedGames: 0,
      duplicateGames: 0,
    );
  }

  static Future<SouthCarolinaScratchCatalogSnapshot> load({
    http.Client? client,
  }) async {
    final cachedSnapshot = await _restoreCachedSnapshot();
    final activeClient = client ?? http.Client();
    try {
      final response = await activeClient
          .get(
            Uri.parse(_feedUrl),
            headers: const {'accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        return cachedSnapshot ?? builtInSnapshot();
      }
      final snapshot = _parse(response.body);
      await _store.setString(_cacheKey, response.body);
      return snapshot;
    } catch (_) {
      return cachedSnapshot ?? builtInSnapshot();
    } finally {
      if (client == null) activeClient.close();
    }
  }

  static Future<SouthCarolinaScratchCatalogSnapshot?> _restoreCachedSnapshot() async {
    try {
      final rawCache = await _store.getString(_cacheKey);
      if (rawCache == null || rawCache.isEmpty) return null;
      return _parse(rawCache, isCached: true);
    } catch (_) {
      return null;
    }
  }

  static SouthCarolinaScratchCatalogSnapshot _parse(
    String raw, {
    bool isCached = false,
  }) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('Scratch-Off feed must be a JSON object.');
    }
    final root = Map<String, dynamic>.from(decoded);
    if (root['state']?.toString().trim().toUpperCase() != 'SC') {
      throw const FormatException(
        'Scratch-Off feed is not for South Carolina.',
      );
    }

    final rawGames = root['games'];
    final updatedAt = DateTime.tryParse(root['updatedAt']?.toString() ?? '');
    final sourceUrl = root['source']?.toString().trim() ?? '';
    if (rawGames is! List || updatedAt == null || sourceUrl.isEmpty) {
      throw const FormatException('Scratch-Off feed has missing fields.');
    }

    final games = <SouthCarolinaScratchGame>[];
    final seenIds = <String>{};
    var rejectedGames = 0;
    var duplicateGames = 0;
    for (final item in rawGames) {
      if (item is! Map) {
        rejectedGames++;
        continue;
      }
      try {
        final game = SouthCarolinaScratchGame.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (!seenIds.add(game.id.toLowerCase())) {
          duplicateGames++;
          continue;
        }
        games.add(game);
      } on FormatException {
        rejectedGames++;
      }
    }
    if (games.isEmpty) {
      throw const FormatException('Scratch-Off feed has no valid games.');
    }

    return SouthCarolinaScratchCatalogSnapshot(
      games: List.unmodifiable(games),
      updatedAt: updatedAt,
      sourceUrl: sourceUrl,
      isPublished: true,
      isCached: isCached,
      rejectedGames: rejectedGames,
      duplicateGames: duplicateGames,
    );
  }
}

class SouthCarolinaScratchCatalogSnapshot {
  const SouthCarolinaScratchCatalogSnapshot({
    required this.games,
    required this.updatedAt,
    required this.sourceUrl,
    required this.isPublished,
    required this.isCached,
    required this.rejectedGames,
    required this.duplicateGames,
  });

  final List<SouthCarolinaScratchGame> games;
  final DateTime updatedAt;
  final String sourceUrl;
  final bool isPublished;
  final bool isCached;
  final int rejectedGames;
  final int duplicateGames;
}
