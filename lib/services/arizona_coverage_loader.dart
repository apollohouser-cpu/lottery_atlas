import 'dart:convert';
import 'package:crypto/crypto.dart';

/// Fixed reviewed development artifact. New observations require Python source
/// validation and an explicitly reviewed digest update; arbitrary JSON is never
/// accepted merely because it has the same shape. No production URL is enabled.
class ArizonaCoverageLoader {
  ArizonaCoverageLoader({
    required this.readBundle,
    required this.fetchRemote,
    required this.readCache,
    required this.writeCache,
  });
  final Future<String> Function() readBundle;
  final Future<String> Function() fetchRemote;
  final Future<String?> Function() readCache;
  final Future<void> Function(String) writeCache;
  static const reviewedCandidateSha256 =
      '23b668a9a2f5c51f8eddf2b66ea7b366d0f3d4c3879111e46bf9c1bb530c670d';

  static Map<String, dynamic> decode(String raw) {
    if (sha256.convert(utf8.encode(raw)).toString() !=
        reviewedCandidateSha256) {
      throw const FormatException('Unreviewed Arizona coverage artifact');
    }
    final data = jsonDecode(raw) as Map<String, dynamic>;
    if (data['stateCode'] != 'AZ' ||
        data['schemaVersion'] != 1 ||
        data['productionReady'] != false ||
        data['recordType'] != 'supported-coverage-candidate') {
      throw const FormatException('Invalid Arizona candidate identity');
    }
    return data;
  }

  Future<ArizonaCoverageLoad> load() async {
    Map<String, dynamic>? retained;
    var origin = 'cache';
    try {
      final raw = await readCache();
      if (raw != null) retained = decode(raw);
    } catch (_) {}
    if (retained == null) {
      origin = 'bundle';
      try {
        retained = decode(await readBundle());
      } catch (_) {}
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
      return ArizonaCoverageLoad(
        data: data,
        origin: 'remote',
        refreshFailed: false,
        persistenceFailed: !persisted,
      );
    } catch (_) {
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
