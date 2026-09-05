import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/state_model.dart';
import '../models/state_scratch_game.dart';
import 'state_scratch_catalog_registry.dart';

/// Loads verified multi-state Scratch-Off catalog snapshots.
///
/// A catalog feed is intentionally separate from [LotteryActivityFeedService]:
/// a ticket being on sale does not establish where a winning ticket was sold.
/// The map only creates heat points from location-based winner activity.
///
/// Configure one JSON feed:
/// --dart-define=STATE_SCRATCH_CATALOG_FEED_URL=https://example.com/catalogs.json
///
/// Or a small manifest of independent official-state catalog snapshots:
/// --dart-define=STATE_SCRATCH_CATALOG_MANIFEST_URL=https://example.com/catalog-feeds.json
///
/// Feed format:
/// {
///   "source": "Official state lottery catalog snapshots",
///   "updatedAt": "2026-08-29T00:00:00Z",
///   "catalogs": [
///     {
///       "state": "Arizona",
///       "source": "https://www.arizonalottery.com/...",
///       "games": [
///         {"stateName":"Arizona","id":"123","name":"Example",
///          "cost":10,"topPrize":1000000,"topPrizesRemaining":2}
///       ]
///     }
///   ]
/// }
///
/// Manifest format: {"feeds":[{"url":"..."}]}
class StateScratchCatalogFeedService {
  StateScratchCatalogFeedService._();

  static const String _feedUrl = String.fromEnvironment(
    'STATE_SCRATCH_CATALOG_FEED_URL',
  );
  static const String _manifestUrl = String.fromEnvironment(
    'STATE_SCRATCH_CATALOG_MANIFEST_URL',
  );
  static const String _cacheKey = 'lottery_atlas.state_scratch_catalogs.v1';
  static const List<String> _bootstrapAssets = <String>[
    'data/iowa_scratch_catalog.initial.json',
    'data/washington_scratch_catalog.initial.json',
    'data/wisconsin_scratch_catalog.initial.json',
    'data/minnesota_scratch_catalog.initial.json',
    'data/missouri_scratch_catalog.initial.json',
    'data/oklahoma_scratch_catalog.initial.json',
    'data/colorado_scratch_catalog.initial.json',
    'data/indiana_scratch_catalog.initial.json',
    'data/oregon_scratch_catalog.initial.json',
    'data/ohio_scratch_catalog.initial.json',
    'data/michigan_scratch_catalog.initial.json',
    'data/kentucky_scratch_catalog.initial.json',
    'data/virginia_scratch_catalog.initial.json',
  ];
  static final SharedPreferencesAsync _store = SharedPreferencesAsync();

  static bool get isConfigured =>
      _feedUrl.trim().isNotEmpty || _manifestUrl.trim().isNotEmpty;

  static Future<void> loadConfiguredFeed({http.Client? client}) async {
    final cachedCatalogs = await _restoreCachedCatalogs();
    final activeClient = client ?? http.Client();
    try {
      final feeds = <_ScratchCatalogFeed>[
        ?cachedCatalogs,
        ...await _loadBundledVerifiedCatalogs(),
      ];
      if (_feedUrl.trim().isNotEmpty) {
        final feed = await _download(activeClient, _feedUrl);
        if (feed != null) feeds.add(feed);
      }
      if (_manifestUrl.trim().isNotEmpty) {
        feeds.addAll(await _downloadManifestFeeds(activeClient));
      }
      if (feeds.isEmpty) return;

      final merged = _merge(feeds);
      StateScratchCatalogRegistry.usePublishedCatalogs(
        merged.catalogs,
        sourceUrls: merged.sourceUrls,
      );
      await _store.setString(_cacheKey, _encode(merged));
    } catch (_) {
      // The last valid snapshot, if present, remains available offline.
    } finally {
      if (client == null) activeClient.close();
    }
  }

  static Future<List<_ScratchCatalogFeed>>
  _loadBundledVerifiedCatalogs() async {
    final feeds = <_ScratchCatalogFeed>[];
    for (final asset in _bootstrapAssets) {
      try {
        feeds.add(_parse(await rootBundle.loadString(asset)));
      } catch (_) {
        // An optional bundled snapshot must never block remote state feeds.
      }
    }
    return feeds;
  }

  static Future<_ScratchCatalogFeed?> _download(
    http.Client client,
    String url,
  ) async {
    try {
      final response = await client
          .get(Uri.parse(url), headers: const {'accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;
      return _parse(response.body);
    } catch (_) {
      return null;
    }
  }

  static Future<List<_ScratchCatalogFeed>> _downloadManifestFeeds(
    http.Client client,
  ) async {
    try {
      final response = await client
          .get(
            Uri.parse(_manifestUrl),
            headers: const {'accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return const <_ScratchCatalogFeed>[];
      final decoded = jsonDecode(response.body);
      if (decoded is! Map || decoded['feeds'] is! List) {
        throw const FormatException('Catalog manifest needs a feeds list.');
      }
      final urls = (decoded['feeds'] as List)
          .whereType<Map>()
          .map((item) => item['url']?.toString().trim() ?? '')
          .where((url) => url.isNotEmpty)
          .toList(growable: false);
      final feeds = await Future.wait(
        urls.map((url) => _download(client, url)),
      );
      return feeds.whereType<_ScratchCatalogFeed>().toList(growable: false);
    } catch (_) {
      return const <_ScratchCatalogFeed>[];
    }
  }

  static _ScratchCatalogFeed _parse(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException(
        'Scratch-Off catalog feed must be an object.',
      );
    }
    final root = Map<String, dynamic>.from(decoded);
    final rawCatalogs = root['catalogs'];
    if (rawCatalogs is! List) {
      throw const FormatException('Scratch-Off catalog feed needs catalogs.');
    }

    final knownStates = allStates.map((state) => state.name).toSet();
    final catalogs = <String, List<StateScratchGame>>{};
    final sourceUrls = <String, String>{};
    for (final item in rawCatalogs) {
      if (item is! Map) continue;
      final catalog = Map<String, dynamic>.from(item);
      final stateName = catalog['state']?.toString().trim() ?? '';
      final sourceUrl = catalog['source']?.toString().trim() ?? '';
      final rawGames = catalog['games'];
      if (!knownStates.contains(stateName) ||
          sourceUrl.isEmpty ||
          rawGames is! List) {
        continue;
      }

      final games = <StateScratchGame>[];
      final gameIds = <String>{};
      for (final rawGame in rawGames) {
        if (rawGame is! Map) continue;
        try {
          final payload = Map<String, dynamic>.from(rawGame);
          payload['stateName'] ??= stateName;
          final game = StateScratchGame.fromJson(payload);
          if (game.stateName != stateName || !gameIds.add(game.id)) continue;
          games.add(game);
        } on FormatException {
          // One malformed ticket must not discard a state-wide official file.
        }
      }
      if (games.isEmpty) continue;
      catalogs[stateName] = List.unmodifiable(games);
      sourceUrls[stateName] = sourceUrl;
    }
    if (catalogs.isEmpty) {
      throw const FormatException('Catalog feed has no valid state catalogs.');
    }
    return _ScratchCatalogFeed(catalogs: catalogs, sourceUrls: sourceUrls);
  }

  static _ScratchCatalogFeed _merge(List<_ScratchCatalogFeed> feeds) {
    final catalogs = <String, List<StateScratchGame>>{};
    final sourceUrls = <String, String>{};
    for (final feed in feeds) {
      catalogs.addAll(feed.catalogs);
      sourceUrls.addAll(feed.sourceUrls);
    }
    return _ScratchCatalogFeed(catalogs: catalogs, sourceUrls: sourceUrls);
  }

  static String _encode(_ScratchCatalogFeed feed) =>
      jsonEncode(<String, dynamic>{
        'catalogs': feed.catalogs.entries
            .map(
              (entry) => <String, dynamic>{
                'state': entry.key,
                'source': feed.sourceUrls[entry.key],
                'games': entry.value.map((game) => game.toJson()).toList(),
              },
            )
            .toList(),
      });

  static Future<_ScratchCatalogFeed?> _restoreCachedCatalogs() async {
    try {
      final raw = await _store.getString(_cacheKey);
      if (raw == null || raw.isEmpty) return null;
      final cached = _parse(raw);
      StateScratchCatalogRegistry.usePublishedCatalogs(
        cached.catalogs,
        sourceUrls: cached.sourceUrls,
      );
      return cached;
    } catch (_) {
      // Ignore old or malformed cache data.
      return null;
    }
  }
}

class _ScratchCatalogFeed {
  const _ScratchCatalogFeed({required this.catalogs, required this.sourceUrls});

  final Map<String, List<StateScratchGame>> catalogs;
  final Map<String, String> sourceUrls;
}
