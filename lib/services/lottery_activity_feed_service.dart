import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/lottery_activity.dart';
import 'lottery_activity_repository.dart';

/// Loads published city/county activity records for the map.
///
/// Give the app a public, read-only JSON URL at run time:
/// --dart-define=LOTTERY_ACTIVITY_FEED_URL=https://your-domain/activity.json
///
/// For nationwide rollout, independent state feeds can be merged with a
/// manifest:
/// --dart-define=LOTTERY_ACTIVITY_FEED_MANIFEST_URL=https://your-domain/feeds.json
///
/// Manifest format:
/// {
///   "source": "Lottery Atlas state activity feeds",
///   "feeds": [
///     {"state": "SC", "url": "https://.../south-carolina.json"},
///     {"state": "NC", "url": "https://.../north-carolina.json"}
///   ]
/// }
///
/// Small, verified state snapshots can also be bundled while their permanent
/// public feeds are being prepared. Remote records with the same id replace
/// bundled records. The latest valid result is cached on the device for offline
/// use.
class LotteryActivityFeedService {
  LotteryActivityFeedService._();

  static const String _feedUrl = String.fromEnvironment(
    'LOTTERY_ACTIVITY_FEED_URL',
    defaultValue:
        'https://apollohouser-cpu.github.io/lottery_atlas/activity.json',
  );
  static const String _manifestUrl = String.fromEnvironment(
    'LOTTERY_ACTIVITY_FEED_MANIFEST_URL',
  );
  static const String _cacheKey = 'lottery_atlas.activity_feed.v1';
  static const List<String> _bootstrapAssets = [
    'data/north_carolina_activity.initial.json',
    'data/north_carolina_national_history.initial.json',
    'data/south_carolina_historical_activity.initial.json',
    'data/georgia_winner_activity.initial.json',
    'data/georgia_historical_activity.initial.json',
    'data/florida_winner_activity.initial.json',
    'data/florida_historical_activity.initial.json',
    'data/tennessee_winner_activity.initial.json',
    'data/tennessee_historical_activity.initial.json',
    'data/kentucky_winner_activity.initial.json',
    'data/maryland_winner_activity.initial.json',
    'data/maryland_historical_activity.initial.json',
    'data/delaware_winner_activity.initial.json',
    'data/delaware_historical_activity.initial.json',
    'data/new_jersey_winner_activity.initial.json',
    'data/new_jersey_historical_activity.initial.json',
    'data/pennsylvania_historical_activity.initial.json',
    'data/west_virginia_winner_activity.initial.json',
    'data/california_winner_activity.initial.json',
    'data/iowa_winner_activity.initial.json',
    'data/wisconsin_winner_activity.initial.json',
    'data/minnesota_winner_activity.initial.json',
    'data/missouri_winner_activity.initial.json',
    'data/kansas_winner_activity.initial.json',
    'data/michigan_winner_activity.initial.json',
    'data/michigan_historical_activity.initial.json',
  ];
  static final SharedPreferencesAsync _store = SharedPreferencesAsync();

  static bool get isConfigured =>
      _feedUrl.trim().isNotEmpty || _manifestUrl.trim().isNotEmpty;

  static Future<void> loadConfiguredFeed({http.Client? client}) async {
    await _restoreCachedFeed();

    final activeClient = client ?? http.Client();
    try {
      final feeds = <_LotteryActivityFeed>[];
      feeds.addAll(await _loadBundledVerifiedFeeds());
      if (_feedUrl.trim().isNotEmpty) {
        final feed = await _downloadFeed(activeClient, _feedUrl);
        if (feed != null) feeds.add(feed);
      }
      if (_manifestUrl.trim().isNotEmpty) {
        feeds.addAll(await _downloadManifestFeeds(activeClient));
      }
      if (feeds.isEmpty) return;

      final feed = _mergeFeeds(feeds);
      LotteryActivityRepository.usePublishedActivity(
        feed.records,
        sourceLabel: feed.sourceLabel,
        updatedAt: feed.updatedAt,
        sourceLastUpdated: feed.sourceLastUpdated,
        coverageNote: feed.coverageNote,
      );
      await _store.setString(_cacheKey, _encodeFeed(feed));
    } catch (_) {
      // The repository keeps its last valid cached or local sample feed.
    } finally {
      if (client == null) activeClient.close();
    }
  }

  static Future<List<_LotteryActivityFeed>> _loadBundledVerifiedFeeds() async {
    final feeds = <_LotteryActivityFeed>[];
    for (final asset in _bootstrapAssets) {
      try {
        feeds.add(_parseFeed(await rootBundle.loadString(asset)));
      } catch (_) {
        // A missing optional bootstrap file must never prevent live feeds.
      }
    }
    return feeds;
  }

  static Future<_LotteryActivityFeed?> _downloadFeed(
    http.Client client,
    String url,
  ) async {
    try {
      final response = await client
          .get(Uri.parse(url), headers: const {'accept': 'application/json'})
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return null;
      return _parseFeed(response.body);
    } catch (_) {
      return null;
    }
  }

  static Future<List<_LotteryActivityFeed>> _downloadManifestFeeds(
    http.Client client,
  ) async {
    try {
      final response = await client
          .get(
            Uri.parse(_manifestUrl),
            headers: const {'accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) return const [];

      final manifest = _parseManifest(response.body);
      final downloaded = await Future.wait(
        manifest.feeds.map(
          (reference) => _downloadFeed(client, reference.url).then((feed) {
            if (feed == null) return null;
            if (reference.state == null) return feed;
            final recordsForState = feed.records
                .where((record) => record.state == reference.state)
                .toList(growable: false);
            return recordsForState.isEmpty
                ? null
                : feed.copyWith(records: recordsForState);
          }),
        ),
      );
      return downloaded.whereType<_LotteryActivityFeed>().toList(
        growable: false,
      );
    } catch (_) {
      return const [];
    }
  }

  static _LotteryActivityFeed _mergeFeeds(List<_LotteryActivityFeed> feeds) {
    final records = <String, LotteryActivity>{
      for (final feed in feeds)
        for (final record in feed.records) record.id: record,
    }.values.toList(growable: false);
    final updates =
        feeds.map((feed) => feed.updatedAt).whereType<DateTime>().toList()
          ..sort();
    final sourceUpdates =
        feeds
            .map((feed) => feed.sourceLastUpdated)
            .whereType<DateTime>()
            .toList()
          ..sort();
    final sourceLabels = feeds.map((feed) => feed.sourceLabel).toSet();
    final coverageNotes = feeds
        .map((feed) => feed.coverageNote)
        .whereType<String>()
        .where((note) => note.isNotEmpty)
        .toList(growable: false);

    return _LotteryActivityFeed(
      records: records,
      sourceLabel: sourceLabels.length == 1
          ? sourceLabels.single
          : 'Published state activity feeds (${sourceLabels.length} sources)',
      updatedAt: updates.isEmpty ? null : updates.last,
      sourceLastUpdated: sourceUpdates.isEmpty ? null : sourceUpdates.last,
      coverageNote: coverageNotes.isEmpty ? null : coverageNotes.join(' '),
    );
  }

  static _ActivityFeedManifest _parseManifest(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const FormatException('The state-feed manifest must be an object.');
    }
    final rawFeeds = decoded['feeds'];
    if (rawFeeds is! List) {
      throw const FormatException(
        'The state-feed manifest needs a feeds list.',
      );
    }
    final feeds = <_ActivityFeedReference>[];
    for (final item in rawFeeds) {
      if (item is! Map) continue;
      final url = item['url']?.toString().trim() ?? '';
      final state = item['state']?.toString().trim().toUpperCase();
      if (url.isEmpty) continue;
      feeds.add(
        _ActivityFeedReference(
          url: url,
          state: state == null || state.length != 2 ? null : state,
        ),
      );
    }
    if (feeds.isEmpty) {
      throw const FormatException(
        'The state-feed manifest has no valid feeds.',
      );
    }
    return _ActivityFeedManifest(feeds);
  }

  static Future<void> _restoreCachedFeed() async {
    final rawCache = await _store.getString(_cacheKey);
    if (rawCache == null || rawCache.isEmpty) return;
    try {
      final feed = _parseFeed(rawCache);
      LotteryActivityRepository.usePublishedActivity(
        feed.records,
        sourceLabel: '${feed.sourceLabel} • saved on this device',
        updatedAt: feed.updatedAt,
        isCached: true,
        sourceLastUpdated: feed.sourceLastUpdated,
        coverageNote: feed.coverageNote,
      );
    } catch (_) {
      // A malformed or obsolete cache must never block the map.
    }
  }

  static _LotteryActivityFeed _parseFeed(String raw) {
    final decoded = jsonDecode(raw);
    final root = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{'activities': decoded};
    final rawActivities = root['activities'];
    if (rawActivities is! List) {
      throw const FormatException(
        'The activity feed needs an activities list.',
      );
    }

    final records = _parseRecords(rawActivities);
    final rawHistoricalActivities = root['historicalActivities'];
    if (rawHistoricalActivities is List) {
      records.addAll(
        _parseRecords(rawHistoricalActivities, isHistorical: true),
      );
    }

    final uniqueRecords = <String, LotteryActivity>{
      for (final record in records) record.id: record,
    }.values.toList(growable: false);
    if (uniqueRecords.isEmpty) {
      throw const FormatException('The activity feed has no valid records.');
    }

    final source = root['source']?.toString().trim();
    final updatedAt = DateTime.tryParse(root['updatedAt']?.toString() ?? '');
    final sourceLastUpdated = DateTime.tryParse(
      root['sourceLastUpdated']?.toString() ?? '',
    );
    final coverage = root['coverage']?.toString().trim();
    return _LotteryActivityFeed(
      records: uniqueRecords,
      sourceLabel: source == null || source.isEmpty
          ? 'Published lottery activity feed'
          : source,
      updatedAt: updatedAt,
      sourceLastUpdated: sourceLastUpdated,
      coverageNote: coverage == null || coverage.isEmpty ? null : coverage,
    );
  }

  static String _encodeFeed(_LotteryActivityFeed feed) => jsonEncode({
    'source': feed.sourceLabel,
    'updatedAt': feed.updatedAt?.toIso8601String(),
    'sourceLastUpdated': feed.sourceLastUpdated?.toIso8601String(),
    'coverage': feed.coverageNote,
    'activities': feed.records.map((record) => record.toJson()).toList(),
  });

  static List<LotteryActivity> _parseRecords(
    List<dynamic> rawActivities, {
    bool isHistorical = false,
  }) {
    final records = <LotteryActivity>[];
    for (final item in rawActivities) {
      if (item is! Map) continue;
      try {
        records.add(
          LotteryActivity.fromJson(
            Map<String, dynamic>.from(item),
            defaultIsHistorical: isHistorical,
          ),
        );
      } on FormatException {
        // One malformed record should not discard a complete daily feed.
      }
    }
    return records;
  }
}

class _LotteryActivityFeed {
  const _LotteryActivityFeed({
    required this.records,
    required this.sourceLabel,
    required this.updatedAt,
    required this.sourceLastUpdated,
    required this.coverageNote,
  });

  final List<LotteryActivity> records;
  final String sourceLabel;
  final DateTime? updatedAt;
  final DateTime? sourceLastUpdated;
  final String? coverageNote;

  _LotteryActivityFeed copyWith({List<LotteryActivity>? records}) =>
      _LotteryActivityFeed(
        records: records ?? this.records,
        sourceLabel: sourceLabel,
        updatedAt: updatedAt,
        sourceLastUpdated: sourceLastUpdated,
        coverageNote: coverageNote,
      );
}

class _ActivityFeedManifest {
  const _ActivityFeedManifest(this.feeds);

  final List<_ActivityFeedReference> feeds;
}

class _ActivityFeedReference {
  const _ActivityFeedReference({required this.url, required this.state});

  final String url;
  final String? state;
}
