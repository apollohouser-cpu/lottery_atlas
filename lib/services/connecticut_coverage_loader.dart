import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

import 'package:crypto/crypto.dart';

/// Loads an explicitly reviewed Connecticut artifact. No public endpoint or
/// bundle is enabled until the supported release has been reviewed and packaged.
class ConnecticutCoverageLoader {
  ConnecticutCoverageLoader({
    required this.reviewedSha256,
    required this.readBundle,
    required this.readCache,
    required this.writeCache,
    required this.fetchRemote,
  });

  static const releasedSha256 =
      '10ca4859d574887366c2fd027266dfabd50ec916e1c3d804ab7ff8a084c538dd';
  static const releasedUrl =
      'https://apollohouser-cpu.github.io/lottery_atlas/connecticut_coverage.json';
  factory ConnecticutCoverageLoader.published() {
    late final prefs = SharedPreferencesAsync();
    return ConnecticutCoverageLoader(
      reviewedSha256: releasedSha256,
      readBundle: () =>
          rootBundle.loadString('data/connecticut_coverage.generated.json'),
      readCache: () => prefs.getString('connecticut_supported_coverage_v1'),
      writeCache: (raw) =>
          prefs.setString('connecticut_supported_coverage_v1', raw),
      fetchRemote: () async {
        final response = await http.get(Uri.parse(releasedUrl));
        if (response.statusCode != 200) {
          throw StateError('Connecticut coverage HTTP ${response.statusCode}');
        }
        return utf8.decode(response.bodyBytes);
      },
    );
  }

  final String reviewedSha256;
  final Future<String> Function() readBundle;
  final Future<String?> Function() readCache;
  final Future<void> Function(String) writeCache;
  final Future<String> Function() fetchRemote;

  Map<String, dynamic> decode(String raw) {
    if (!RegExp(r'^[a-f0-9]{64}$').hasMatch(reviewedSha256) ||
        sha256.convert(utf8.encode(raw)).toString() != reviewedSha256) {
      throw const FormatException('Unreviewed Connecticut coverage artifact');
    }
    final value = jsonDecode(raw);
    if (value is! Map<String, dynamic> ||
        value['schemaVersion'] != 1 ||
        value['stateCode'] != 'CT' ||
        value['productionReady'] != true ||
        value['recordType'] != 'supported-coverage') {
      throw const FormatException('Not a Connecticut supported release');
    }
    return value;
  }

  Future<ConnecticutCoverageLoad> load() async {
    Map<String, dynamic>? retained;
    var origin = 'cache';
    try {
      final raw = await readCache();
      if (raw != null) retained = decode(raw);
    } catch (_) {
      // Invalid or inaccessible cache cannot replace the reviewed bundle.
    }
    if (retained == null) {
      origin = 'bundle';
      try {
        retained = decode(await readBundle());
      } catch (_) {
        // A validated remote artifact may still recover an unavailable bundle.
      }
    }
    try {
      final raw = await fetchRemote().timeout(const Duration(seconds: 8));
      final data = decode(raw);
      var persistenceFailed = false;
      try {
        await writeCache(raw);
      } catch (_) {
        persistenceFailed = true;
      }
      return ConnecticutCoverageLoad(
        data: data,
        origin: 'remote',
        refreshFailed: false,
        persistenceFailed: persistenceFailed,
      );
    } catch (_) {
      if (retained == null) {
        throw StateError('No reviewed Connecticut coverage available');
      }
      return ConnecticutCoverageLoad(
        data: retained,
        origin: origin,
        refreshFailed: true,
        persistenceFailed: false,
      );
    }
  }
}

class ConnecticutCoverageLoad {
  const ConnecticutCoverageLoad({
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
