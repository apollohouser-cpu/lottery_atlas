import 'dart:convert';

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
