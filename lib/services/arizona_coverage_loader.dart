import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fixed reviewed Arizona artifacts. New observations require Python source
/// validation and an explicitly reviewed digest update; arbitrary JSON is never
/// accepted merely because it has the same shape. Release loading excludes candidates.
class ArizonaCoverageLoader {
  ArizonaCoverageLoader({
    required this.readBundle,
    required this.fetchRemote,
    required this.readCache,
    required this.writeCache,
    this.releaseOnly = false,
  });
  static const developmentCacheKey = 'arizona_development_candidate_v1';
  factory ArizonaCoverageLoader.development() {
    late final prefs = SharedPreferencesAsync();
    return ArizonaCoverageLoader(
      readBundle: () =>
          rootBundle.loadString('data/arizona_coverage.candidate.json'),
      readCache: () => prefs.getString(developmentCacheKey),
      writeCache: (raw) => prefs.setString(developmentCacheKey, raw),
      fetchRemote: () async =>
          throw StateError('Arizona remote feed is not enabled'),
    );
  }

  /// Reviewed static candidate transport, still gated from ordinary app routes.
  /// Successful download does not imply a fresh agency collection or acceptance.
  static const candidateUrl =
      'https://apollohouser-cpu.github.io/lottery_atlas/arizona_coverage.candidate.json';
  factory ArizonaCoverageLoader.preview() {
    late final prefs = SharedPreferencesAsync();
    return ArizonaCoverageLoader(
      readBundle: () =>
          rootBundle.loadString('data/arizona_coverage.candidate.json'),
      readCache: () => prefs.getString(developmentCacheKey),
      writeCache: (raw) => prefs.setString(developmentCacheKey, raw),
      fetchRemote: () async {
        final response = await http.get(Uri.parse(candidateUrl));
        if (response.statusCode != 200) {
          throw StateError('Arizona candidate HTTP ${response.statusCode}');
        }
        return utf8.decode(response.bodyBytes);
      },
    );
  }
  static const releasedSha256 =
      'fa48e46f0d526f4fee7dc0ea71db84202f028d6102475824b2f3668d62f961d5';
  static const releasedUrl =
      'https://apollohouser-cpu.github.io/lottery_atlas/arizona_coverage.json';
  factory ArizonaCoverageLoader.published() {
    late final prefs = SharedPreferencesAsync();
    return ArizonaCoverageLoader(
      releaseOnly: true,
      readBundle: () =>
          rootBundle.loadString('data/arizona_coverage.generated.json'),
      readCache: () => prefs.getString('arizona_supported_coverage_v1'),
      writeCache: (raw) =>
          prefs.setString('arizona_supported_coverage_v1', raw),
      fetchRemote: () async {
        final response = await http.get(Uri.parse(releasedUrl));
        if (response.statusCode != 200) {
          throw StateError('Arizona coverage HTTP ${response.statusCode}');
        }
        return utf8.decode(response.bodyBytes);
      },
    );
  }
  final bool releaseOnly;
  final Future<String> Function() readBundle;
  final Future<String> Function() fetchRemote;
  final Future<String?> Function() readCache;
  final Future<void> Function(String) writeCache;
  static const reviewedCandidateSha256 =
      '17cb702fe6100bf32f65e0911e73c7d7bb312d7321f5a02dc9bf15baf51524d3';

  static Map<String, dynamic> decode(String raw) {
    final digest = sha256.convert(utf8.encode(raw)).toString();
    final released = digest == releasedSha256;
    if (!released && digest != reviewedCandidateSha256) {
      throw const FormatException('Unreviewed Arizona coverage artifact');
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['stateCode'] != 'AZ' ||
        data['schemaVersion'] != 1 ||
        data['productionReady'] != released ||
        data['recordType'] !=
            (released
                ? 'supported-coverage'
                : 'supported-coverage-candidate')) {
      throw const FormatException('Invalid Arizona candidate identity');
    }
    return data;
  }

  Map<String, dynamic> decodeForLoad(String raw) {
    final data = decode(raw);
    if (releaseOnly && data['productionReady'] != true) {
      throw const FormatException(
        'Development candidate is not a released artifact',
      );
    }
    return data;
  }

  Future<ArizonaCoverageLoad> load() async {
    Map<String, dynamic>? retained;
    var origin = 'cache';
    try {
      final raw = await readCache();
      if (raw != null) retained = decodeForLoad(raw);
    } catch (error) {
      debugPrint('Arizona cache load failed: $error');
    }
    if (retained == null) {
      origin = 'bundle';
      try {
        retained = decodeForLoad(await readBundle());
      } catch (error) {
        debugPrint('Arizona bundle load failed: $error');
      }
    }
    try {
      final raw = await fetchRemote().timeout(const Duration(seconds: 8));
      final data = decodeForLoad(raw);
      var persisted = true;
      try {
        await writeCache(raw);
      } catch (_) {
        persisted = false;
      }
      return ArizonaCoverageLoad(
        data: data,
        origin: 'remote',
        refreshFailed: false,
        persistenceFailed: !persisted,
      );
    } catch (error) {
      debugPrint('Arizona refresh failed: $error');
      if (retained == null) {
        throw StateError('No validated Arizona coverage available');
      }
      return ArizonaCoverageLoad(
        data: retained,
        origin: origin,
        refreshFailed: true,
        persistenceFailed: false,
      );
    }
  }
}

class ArizonaCoverageLoad {
  const ArizonaCoverageLoad({
    required this.data,
    required this.origin,
    required this.refreshFailed,
    required this.persistenceFailed,
  });
  final Map<String, dynamic> data;
  final String origin;
  final bool refreshFailed;
  final bool persistenceFailed;
}
