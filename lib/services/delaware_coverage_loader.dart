import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Development-only Delaware transport, not wired to ordinary app routes.
/// Exact reviewed bytes are required; new observations require source validation.
/// No public remote endpoint is enabled by the development factory.
class DelawareCoverageLoader {
  DelawareCoverageLoader({
    required this.readBundle,
    required this.fetchRemote,
    required this.readCache,
    required this.writeCache,
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

  final Future<String> Function() readBundle;
  final Future<String> Function() fetchRemote;
  final Future<String?> Function() readCache;
  final Future<void> Function(String) writeCache;
  static const reviewedCandidateSha256 =
      '77da403a86ac7ece2f36372213ec2ce4282abaa7f0c523b1000bfa18049c7fe1';

  static Map<String, dynamic> decode(String raw) {
    final digest = sha256.convert(utf8.encode(raw)).toString();
    if (digest != reviewedCandidateSha256) {
      throw const FormatException('Unreviewed Delaware coverage artifact');
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['stateCode'] != 'DE' ||
        data['schemaVersion'] != 1 ||
        data['productionReady'] != false ||
        data['recordType'] != 'incomplete-development-candidate') {
      throw const FormatException('Invalid Delaware candidate identity');
    }
    return data;
  }

  Future<DelawareCoverageLoad> load() async {
    Map<String, dynamic>? retained;
    var origin = 'cache';
    try {
      final raw = await readCache();
      if (raw != null) retained = decode(raw);
    } catch (error) {
      debugPrint('Delaware cache load failed: $error');
    }
    if (retained == null) {
      origin = 'bundle';
      try {
        retained = decode(await readBundle());
      } catch (error) {
        debugPrint('Delaware bundle load failed: $error');
      }
    }
    try {
      final raw = await fetchRemote().timeout(const Duration(seconds: 8));
      final data = decode(raw);
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
