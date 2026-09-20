import 'dart:async';
import 'dart:convert';
import 'dart:io';

class SourceHttpException implements Exception {
  const SourceHttpException(this.statusCode);
  final int statusCode;
  @override
  String toString() => 'Official source returned HTTP $statusCode';
}

Future<String> fetchOfficialSource(
  Uri uri, {
  int attempts = 4,
  Duration timeout = const Duration(seconds: 30),
  Duration retryDelay = const Duration(seconds: 1),
}) async {
  if (attempts < 1) throw ArgumentError.value(attempts, 'attempts');
  const transient = {408, 429, 500, 502, 503, 504};
  for (var attempt = 0; attempt < attempts; attempt++) {
    final client = HttpClient()..connectionTimeout = timeout;
    try {
      return await (() async {
        final request = await client.getUrl(uri);
        request.headers.set(
          HttpHeaders.userAgentHeader,
          'LotteryAtlasOfficialDataBot/1.0',
        );
        final response = await request.close();
        if (response.statusCode != HttpStatus.ok) {
          throw SourceHttpException(response.statusCode);
        }
        return utf8.decoder.bind(response).join();
      })().timeout(timeout);
    } on SourceHttpException catch (error) {
      if (!transient.contains(error.statusCode) || attempt == attempts - 1) {
        rethrow;
      }
    } on SocketException {
      if (attempt == attempts - 1) rethrow;
    } on TimeoutException {
      if (attempt == attempts - 1) rethrow;
    } on HttpException {
      if (attempt == attempts - 1) rethrow;
    } finally {
      client.close(force: true);
    }
    await Future<void>.delayed(retryDelay * (attempt + 1));
  }
  throw StateError('Unreachable fetch state');
}
