import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Fixed reviewed Delaware artifacts. New observations require Python source
/// validation and an explicitly reviewed digest update; arbitrary JSON is never
/// accepted merely because it has the same shape. Release loading excludes candidates.
class DelawareCoverageLoader {
  DelawareCoverageLoader({
    required this.readBundle,
    required this.fetchRemote,
    required this.readCache,
    required this.writeCache,
    this.releaseOnly = false,
  });
  static const developmentCacheKey = 'delaware_development_candidate_v1';
  factory DelawareCoverageLoader.development() {
    late final prefs = SharedPreferencesAsync();
    return DelawareCoverageLoader(
      readBundle: () =>
          rootBundle.loadString('data/delaware_coverage.candidate.json'),
      readCache: () => prefs.getString(developmentCacheKey),
      writeCache: (raw) => prefs.setString(developmentCacheKey, raw),
      fetchRemote: () async =>
          throw StateError('Delaware remote feed is not enabled'),
    );
  }

  static const releasedSha256 =
      'e36c696497328a752c1731498d8713e8963c99c2e8898389d0efe6b45841eab6';
  static const releasedUrl =
      'https://apollohouser-cpu.github.io/lottery_atlas/delaware_coverage.json';
  factory DelawareCoverageLoader.published() {
    late final prefs = SharedPreferencesAsync();
    return DelawareCoverageLoader(
      releaseOnly: true,
      readBundle: () =>
          rootBundle.loadString('data/delaware_coverage.generated.json'),
      readCache: () => prefs.getString('delaware_supported_coverage_v1'),
      writeCache: (raw) =>
          prefs.setString('delaware_supported_coverage_v1', raw),
      fetchRemote: () async {
        final response = await http.get(Uri.parse(releasedUrl));
        if (response.statusCode != 200) {
          throw StateError('Delaware coverage HTTP ${response.statusCode}');
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
      '77da403a86ac7ece2f36372213ec2ce4282abaa7f0c523b1000bfa18049c7fe1';

  static Map<String, dynamic> decode(String raw) {
    final digest = sha256.convert(utf8.encode(raw)).toString();
    final released = digest == releasedSha256;
    if (!released && digest != reviewedCandidateSha256) {
      throw const FormatException('Unreviewed Delaware coverage artifact');
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['stateCode'] != 'DE' ||
        data['schemaVersion'] != 1 ||
        data['productionReady'] != released ||
        data['recordType'] !=
            (released
                ? 'supported-coverage'
                : 'incomplete-development-candidate')) {
      throw const FormatException('Invalid Delaware candidate identity');
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

  Future<DelawareCoverageLoad> load() async {
    Map<String, dynamic>? retained;
    var origin = 'cache';
    try {
      final raw = await readCache();
      if (raw != null) retained = decodeForLoad(raw);
    } catch (error) {
      debugPrint('Delaware cache load failed: $error');
    }
    if (retained == null) {
      origin = 'bundle';
      try {
        retained = decodeForLoad(await readBundle());
      } catch (error) {
        debugPrint('Delaware bundle load failed: $error');
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
      return DelawareCoverageLoad(
        data: data,
        origin: 'remote',
        refreshFailed: false,
        persistenceFailed: !persisted,
      );
    } catch (error) {
      debugPrint('Delaware refresh failed: $error');
      if (retained == null) {
        throw StateError('No validated Delaware coverage available');
      }
      return DelawareCoverageLoad(
        data: retained,
        origin: origin,
        refreshFailed: true,
        persistenceFailed: false,
      );
    }
  }
}

class DelawareCoverageLoad {
  const DelawareCoverageLoad({
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
