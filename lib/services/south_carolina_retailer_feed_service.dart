import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/south_carolina_retailer.dart';
import 'south_carolina_retailer_repository.dart';

/// Loads a published, read-only South Carolina retailer-claim feed.
///
/// Configure it at launch when the public JSON is ready:
/// --dart-define=SOUTH_CAROLINA_RETAILER_FEED_URL=https://your-domain/retailers.json
///
/// The built-in verified starter records remain available when the feed is not
/// configured, invalid, or temporarily unreachable.
class SouthCarolinaRetailerFeedService {
  SouthCarolinaRetailerFeedService._();

  static const String _feedUrl = String.fromEnvironment(
    'SOUTH_CAROLINA_RETAILER_FEED_URL',
  );
  static const String _cacheKey = 'lottery_atlas.sc_retailer_claims.v1';
  static final SharedPreferencesAsync _store = SharedPreferencesAsync();

  static bool get isConfigured => _feedUrl.trim().isNotEmpty;

  static Future<SouthCarolinaRetailerFeedRefreshResult> loadConfiguredFeed({
    http.Client? client,
  }) async {
    await _restoreCachedFeed();
    if (!isConfigured) {
      return const SouthCarolinaRetailerFeedRefreshResult.notConfigured();
    }

    final activeClient = client ?? http.Client();
    try {
      final response = await activeClient
          .get(
            Uri.parse(_feedUrl),
            headers: const {'accept': 'application/json'},
          )
          .timeout(const Duration(seconds: 12));
      if (response.statusCode != 200) {
        return SouthCarolinaRetailerFeedRefreshResult.failed(
          'The published retailer feed returned ${response.statusCode}.',
        );
      }

      final feed = _parseFeed(response.body);
      SouthCarolinaRetailerRepository.usePublishedRetailers(
        feed.retailers,
        sourceLabel: feed.sourceLabel,
        updatedAt: feed.updatedAt,
      );
      await _store.setString(_cacheKey, response.body);
      return SouthCarolinaRetailerFeedRefreshResult.updated(
        acceptedRecords: feed.retailers.length,
        rejectedRecords: feed.rejectedRecords,
        duplicateRecords: feed.duplicateRecords,
      );
    } on FormatException catch (error) {
      return SouthCarolinaRetailerFeedRefreshResult.failed(error.message);
    } catch (_) {
      // Keep the last valid cached or built-in data if the refresh fails.
      return const SouthCarolinaRetailerFeedRefreshResult.failed(
        'The published retailer feed could not be reached.',
      );
    } finally {
      if (client == null) activeClient.close();
    }
  }

  static Future<void> _restoreCachedFeed() async {
    final rawCache = await _store.getString(_cacheKey);
    if (rawCache == null || rawCache.isEmpty) return;
    try {
      final feed = _parseFeed(rawCache);
      SouthCarolinaRetailerRepository.usePublishedRetailers(
        feed.retailers,
        sourceLabel: '${feed.sourceLabel} • saved on this device',
        updatedAt: feed.updatedAt,
        isCached: true,
      );
    } catch (_) {
      // An obsolete cache must never prevent the starter data from loading.
    }
  }

  static _SouthCarolinaRetailerFeed _parseFeed(String raw) {
    final decoded = jsonDecode(raw);
    final root = decoded is Map
        ? Map<String, dynamic>.from(decoded)
        : <String, dynamic>{'retailers': decoded};
    final state = root['state']?.toString().trim().toUpperCase();
    if (state != null && state.isNotEmpty && state != 'SC') {
      throw const FormatException('The retailer feed is not for South Carolina.');
    }
    final rawRetailers = root['retailers'];
    if (rawRetailers is! List) {
      throw const FormatException('The retailer feed needs a retailers list.');
    }

    final retailers = <SouthCarolinaRetailer>[];
    final seenIds = <String>{};
    var rejectedRecords = 0;
    var duplicateRecords = 0;
    for (final item in rawRetailers) {
      if (item is! Map) {
        rejectedRecords++;
        continue;
      }
      try {
        final retailer = SouthCarolinaRetailer.fromJson(
          Map<String, dynamic>.from(item),
        );
        if (!seenIds.add(retailer.id.toLowerCase())) {
          duplicateRecords++;
          continue;
        }
        retailers.add(retailer);
      } on FormatException {
        // One malformed entry should not discard a complete daily feed.
        rejectedRecords++;
      }
    }
    if (retailers.isEmpty) {
      throw const FormatException('The retailer feed has no valid records.');
    }

    final source = root['source']?.toString().trim();
    final updatedAt = DateTime.tryParse(root['updatedAt']?.toString() ?? '');
    return _SouthCarolinaRetailerFeed(
      retailers: retailers,
      sourceLabel: source == null || source.isEmpty
          ? 'Published SC retailer claim feed'
          : source,
      updatedAt: updatedAt,
      rejectedRecords: rejectedRecords,
      duplicateRecords: duplicateRecords,
    );
  }
}

class _SouthCarolinaRetailerFeed {
  const _SouthCarolinaRetailerFeed({
    required this.retailers,
    required this.sourceLabel,
    required this.updatedAt,
    required this.rejectedRecords,
    required this.duplicateRecords,
  });

  final List<SouthCarolinaRetailer> retailers;
  final String sourceLabel;
  final DateTime? updatedAt;
  final int rejectedRecords;
  final int duplicateRecords;
}

/// A short, user-safe summary of the most recent published feed check.
class SouthCarolinaRetailerFeedRefreshResult {
  const SouthCarolinaRetailerFeedRefreshResult._({
    required this.didUpdate,
    required this.message,
    this.acceptedRecords = 0,
    this.rejectedRecords = 0,
    this.duplicateRecords = 0,
  });

  const SouthCarolinaRetailerFeedRefreshResult.notConfigured()
      : this._(
          didUpdate: false,
          message: 'No public retailer feed is configured yet.',
        );

  const SouthCarolinaRetailerFeedRefreshResult.failed(String message)
      : this._(didUpdate: false, message: message);

  factory SouthCarolinaRetailerFeedRefreshResult.updated({
    required int acceptedRecords,
    required int rejectedRecords,
    required int duplicateRecords,
  }) {
    final details = <String>[
      '$acceptedRecords accepted',
      if (duplicateRecords > 0) '$duplicateRecords duplicate${duplicateRecords == 1 ? '' : 's'} removed',
      if (rejectedRecords > 0) '$rejectedRecords invalid record${rejectedRecords == 1 ? '' : 's'} skipped',
    ];
    return SouthCarolinaRetailerFeedRefreshResult._(
      didUpdate: true,
      message: 'Retailer feed refreshed: ${details.join(' • ')}.',
      acceptedRecords: acceptedRecords,
      rejectedRecords: rejectedRecords,
      duplicateRecords: duplicateRecords,
    );
  }

  final bool didUpdate;
  final String message;
  final int acceptedRecords;
  final int rejectedRecords;
  final int duplicateRecords;
}
