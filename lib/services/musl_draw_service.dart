import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// A small, national-results-only adapter for the Multi-State Lottery
/// Association (MUSL) API.
///
/// The API requires a public key issued by MUSL. Supply it at run time with:
/// --dart-define=MUSL_API_KEY=your_key
///
/// Do not place a production key in source control. This adapter intentionally
/// does not claim to provide state games, ticket-sale locations, or retailer
/// data; those require separate official state data sources.
class MuslDrawService {
  MuslDrawService({http.Client? client}) : _client = client ?? http.Client();

  static const String _apiKey = String.fromEnvironment('MUSL_API_KEY');
  static const String _endpoint = 'https://api.musl.com/v3/drawreport';
  static const String _winnersEndpoint = 'https://api.musl.com/v3/winners';
  static const String _cachePrefix = 'lottery_atlas.musl.draw.';
  static const String _winnerCachePrefix = 'lottery_atlas.musl.winners.';

  final http.Client _client;
  final SharedPreferencesAsync _store = SharedPreferencesAsync();

  bool get isConfigured => _apiKey.isNotEmpty;

  /// Returns the most recently saved result without requesting the network.
  Future<NationalDrawResult?> cachedLatest(String gameCode) =>
      _cachedResult(gameCode);

  /// Uses a recent saved official result when one is available, otherwise
  /// fetches a fresh result. This keeps normal map launches lightweight while
  /// still refreshing regularly during active use.
  Future<NationalDrawResult> latestCachedOrRefresh(
    String gameCode, {
    Duration maxCacheAge = const Duration(minutes: 30),
    String? organizationCode,
  }) async {
    final cached = await _cachedResult(
      gameCode,
      organizationCode: organizationCode,
    );
    final savedAt = cached?.lastUpdated;
    if (cached != null &&
        savedAt != null &&
        DateTime.now().difference(savedAt) <= maxCacheAge) {
      return cached;
    }
    return latest(gameCode, organizationCode: organizationCode);
  }

  Future<NationalDrawResult> latest(
    String gameCode, {
    String? organizationCode,
  }) async {
    if (!isConfigured) {
      throw const MuslDrawException(
        'MUSL is not connected. Add your MUSL API key when running the app.',
      );
    }

    try {
      final queryParameters = <String, String>{'GameCode': gameCode};
      final normalizedOrganizationCode = organizationCode?.trim().toUpperCase();
      if (normalizedOrganizationCode != null &&
          normalizedOrganizationCode.isNotEmpty) {
        queryParameters['OrganizationCode'] = normalizedOrganizationCode;
      }
      final uri = Uri.parse(
        _endpoint,
      ).replace(queryParameters: queryParameters);
      final response = await _client.get(
        uri,
        headers: <String, String>{
          'accept': 'application/json',
          'x-api-key': _apiKey,
        },
      );

      if (response.statusCode != 200) {
        throw MuslDrawException(
          'MUSL could not return $gameCode right now (${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final updatedAt = DateTime.now();
      await _store.setString(
        _cacheKey(gameCode, organizationCode: normalizedOrganizationCode),
        jsonEncode(<String, dynamic>{
          'savedAt': updatedAt.toIso8601String(),
          'result': decoded,
        }),
      );
      return NationalDrawResult.fromJson(
        decoded,
        lastUpdated: updatedAt,
        organizationCode: normalizedOrganizationCode,
      );
    } catch (error) {
      final cached = await _cachedResult(
        gameCode,
        organizationCode: organizationCode,
      );
      if (cached != null) return cached;
      if (error is MuslDrawException) rethrow;
      throw MuslDrawException(
        'MUSL could not return $gameCode right now. Check your connection and try again.',
      );
    }
  }

  /// Returns state-level counts for MUSL's reported top winner tiers.
  /// This deliberately does not infer county, city, retailer, or ticket data.
  Future<NationalStateWinnerSummary> latestTopTierStateWinnersCachedOrRefresh(
    String gameCode, {
    Duration maxCacheAge = const Duration(minutes: 30),
  }) async {
    final cached = await _cachedTopTierStateWinners(gameCode);
    final savedAt = cached?.lastUpdated;
    if (cached != null &&
        savedAt != null &&
        DateTime.now().difference(savedAt) <= maxCacheAge) {
      return cached;
    }
    return latestTopTierStateWinners(gameCode);
  }

  Future<NationalStateWinnerSummary> latestTopTierStateWinners(
    String gameCode,
  ) async {
    if (!isConfigured) {
      throw const MuslDrawException(
        'MUSL is not connected. Add your MUSL API key when running the app.',
      );
    }

    try {
      final uri = Uri.parse(
        _winnersEndpoint,
      ).replace(queryParameters: <String, String>{'GameCode': gameCode});
      final response = await _client.get(
        uri,
        headers: <String, String>{
          'accept': 'application/json',
          'x-api-key': _apiKey,
        },
      );
      if (response.statusCode != 200) {
        throw MuslDrawException(
          'MUSL could not return $gameCode winner tiers right now (${response.statusCode}).',
        );
      }

      final decoded = jsonDecode(response.body) as Map<String, dynamic>;
      final updatedAt = DateTime.now();
      await _store.setString(
        '$_winnerCachePrefix$gameCode',
        jsonEncode(<String, dynamic>{
          'savedAt': updatedAt.toIso8601String(),
          'result': decoded,
        }),
      );
      return NationalStateWinnerSummary.fromJson(
        gameCode: gameCode,
        json: decoded,
        lastUpdated: updatedAt,
      );
    } catch (error) {
      final cached = await _cachedTopTierStateWinners(gameCode);
      if (cached != null) return cached;
      if (error is MuslDrawException) rethrow;
      throw MuslDrawException(
        'MUSL could not return $gameCode winner tiers right now. Check your connection and try again.',
      );
    }
  }

  Future<NationalDrawResult?> _cachedResult(
    String gameCode, {
    String? organizationCode,
  }) async {
    final rawCache = await _store.getString(
      _cacheKey(gameCode, organizationCode: organizationCode),
    );
    if (rawCache == null) return null;

    try {
      final cache = jsonDecode(rawCache) as Map<String, dynamic>;
      final result = cache['result'] as Map<String, dynamic>?;
      if (result == null) return null;
      return NationalDrawResult.fromJson(
        result,
        isCached: true,
        lastUpdated: DateTime.tryParse(cache['savedAt'] as String? ?? ''),
        organizationCode: organizationCode,
      );
    } catch (_) {
      return null;
    }
  }

  Future<NationalStateWinnerSummary?> _cachedTopTierStateWinners(
    String gameCode,
  ) async {
    final rawCache = await _store.getString('$_winnerCachePrefix$gameCode');
    if (rawCache == null) return null;
    try {
      final cache = jsonDecode(rawCache) as Map<String, dynamic>;
      final result = cache['result'] as Map<String, dynamic>?;
      if (result == null) return null;
      return NationalStateWinnerSummary.fromJson(
        gameCode: gameCode,
        json: result,
        lastUpdated: DateTime.tryParse(cache['savedAt'] as String? ?? ''),
        isCached: true,
      );
    } catch (_) {
      return null;
    }
  }

  String _cacheKey(String gameCode, {String? organizationCode}) {
    final organization = organizationCode?.trim().toUpperCase();
    return organization == null || organization.isEmpty
        ? '$_cachePrefix$gameCode'
        : '$_cachePrefix$gameCode.$organization';
  }

  void dispose() => _client.close();
}

class MuslDrawException implements Exception {
  const MuslDrawException(this.message);
  final String message;
  @override
  String toString() => message;
}

class NationalDrawResult {
  const NationalDrawResult({
    required this.gameName,
    required this.drawDate,
    required this.numbers,
    required this.specialNumber,
    required this.prizeText,
    required this.nextPrizeText,
    this.isCached = false,
    this.lastUpdated,
    this.organizationCode,
    this.reportedWinnerCount,
  });

  final String gameName;
  final String drawDate;
  final List<String> numbers;
  final String? specialNumber;
  final String? prizeText;
  final String? nextPrizeText;
  final bool isCached;
  final DateTime? lastUpdated;
  final String? organizationCode;

  /// Sum of the winner tiers reported for a requested MUSL organization.
  /// This is state-level only; MUSL does not provide county or retailer data.
  final int? reportedWinnerCount;

  factory NationalDrawResult.fromJson(
    Map<String, dynamic> json, {
    bool isCached = false,
    DateTime? lastUpdated,
    String? organizationCode,
  }) {
    final rawNumbers = (json['numbers'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>();
    final regular =
        rawNumbers
            .where((number) => number['ruleCode'] == 'white-balls')
            .toList()
          ..sort(
            (a, b) => ((a['orderDrawn'] as num?)?.toInt() ?? 0).compareTo(
              (b['orderDrawn'] as num?)?.toInt() ?? 0,
            ),
          );
    final special = rawNumbers.where(
      (number) =>
          number['ruleCode'] != 'white-balls' &&
          number['itemCode'] != 'power-play',
    );
    final game = json['game'] as Map<String, dynamic>? ?? const {};
    final grandPrize = json['grandPrize'] as Map<String, dynamic>? ?? const {};
    final winnerCount = _reportedWinnerCount(json);

    return NationalDrawResult(
      gameName: game['name'] as String? ?? 'National draw',
      drawDate: json['drawDate'] as String? ?? 'Latest completed draw',
      numbers: regular
          .map((number) => number['value']?.toString() ?? '')
          .where((value) => value.isNotEmpty)
          .toList(),
      specialNumber: special.isEmpty
          ? null
          : special.first['value']?.toString(),
      prizeText: grandPrize['prizeText'] as String?,
      nextPrizeText: grandPrize['nextPrizeText'] as String?,
      isCached: isCached,
      lastUpdated: lastUpdated,
      organizationCode: organizationCode,
      reportedWinnerCount: winnerCount,
    );
  }

  static int? _reportedWinnerCount(Map<String, dynamic> json) {
    final winners = json['winners'];
    if (winners is! Map) return null;
    final winnerMap = Map<String, dynamic>.from(winners);
    final tiers = winnerMap['tiers'] ?? winnerMap['topTiers'];
    if (tiers is! List) return null;

    var foundCount = false;
    var total = 0;
    for (final tier in tiers) {
      if (tier is! Map) continue;
      final count = tier['count'];
      if (count is num) {
        total += count.toInt();
        foundCount = true;
      }
    }
    return foundCount ? total : null;
  }
}

/// State-level totals in MUSL's top winner tiers for one national game.
class NationalStateWinnerSummary {
  const NationalStateWinnerSummary({
    required this.gameCode,
    required this.countsByOrganization,
    this.lastUpdated,
    this.isCached = false,
  });

  final String gameCode;
  final Map<String, int> countsByOrganization;
  final DateTime? lastUpdated;
  final bool isCached;

  factory NationalStateWinnerSummary.fromJson({
    required String gameCode,
    required Map<String, dynamic> json,
    DateTime? lastUpdated,
    bool isCached = false,
  }) {
    final counts = <String, int>{};
    final winners = json['winners'];
    final winnerMap = winners is Map
        ? Map<String, dynamic>.from(winners)
        : const <String, dynamic>{};
    final topTiers = winnerMap['topTiers'];

    if (topTiers is List) {
      for (final tier in topTiers) {
        if (tier is! Map) continue;
        final organizations = tier['organizations'];
        if (organizations is! List) continue;
        for (final organization in organizations) {
          if (organization is! Map) continue;
          final code = organization['organizationCode']?.toString().trim();
          final count = organization['count'];
          if (code == null || code.isEmpty || count is! num) continue;
          counts.update(
            code.toUpperCase(),
            (current) => current + count.toInt(),
            ifAbsent: () => count.toInt(),
          );
        }
      }
    }

    return NationalStateWinnerSummary(
      gameCode: gameCode,
      countsByOrganization: counts,
      lastUpdated: lastUpdated,
      isCached: isCached,
    );
  }
}
