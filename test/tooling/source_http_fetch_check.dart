// Standalone: no package resolution or Flutter SDK required in the publisher.
import 'dart:async';
import 'dart:io';
import '../../tooling/source_http_fetch.dart';

void check(bool condition, String message) {
  if (!condition) throw StateError(message);
}

Future<void> main() async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final calls = <String, int>{};
  final subscription = server.listen((request) async {
    final path = request.uri.path;
    final count = calls.update(path, (n) => n + 1, ifAbsent: () => 1);
    if (path == '/recover') {
      request.response.statusCode = count == 1 ? 503 : 200;
      request.response.write('official report');
    } else if (path == '/missing') {
      request.response.statusCode = 404;
    } else if (path == '/outage') {
      request.response.statusCode = 503;
    } else if (path == '/slow') {
      await Future<void>.delayed(const Duration(milliseconds: 150));
    } else if (path == '/bad-utf8') {
      request.response.add([0xff]);
    }
    await request.response.close();
  });
  Uri uri(String path) => Uri.parse('http://127.0.0.1:${server.port}$path');
  Future<String> fetch(String path) => fetchOfficialSource(
    uri(path),
    attempts: 3,
    retryDelay: Duration.zero,
    timeout: path == '/slow'
        ? const Duration(milliseconds: 40)
        : const Duration(seconds: 2),
  );
  try {
    check(await fetch('/recover') == 'official report', 'Recovery lost body');
    check(calls['/recover'] == 2, 'Transient response not retried');
    try {
      await fetch('/missing');
      throw StateError('404 was accepted');
    } on SourceHttpException catch (e) {
      check(e.statusCode == 404 && calls['/missing'] == 1, '404 retried');
    }
    try {
      await fetch('/outage');
      throw StateError('Outage was accepted');
    } on SourceHttpException {
      check(calls['/outage'] == 3, 'Unbounded or missing retries');
    }
    try {
      await fetch('/slow');
      throw StateError('Timeout was accepted');
    } on TimeoutException {
      check(calls['/slow'] == 3, 'Timeout retries wrong');
    }
    try {
      await fetch('/bad-utf8');
      throw StateError('Invalid source body accepted');
    } on FormatException {
      check(calls['/bad-utf8'] == 1, 'Malformed body retried');
    }
    stdout.writeln(
      'Passed 5 source HTTP checks: recovery, permanent errors, retry bounds, timeout, malformed data.',
    );
  } finally {
    await server.close(force: true);
    await subscription.cancel();
  }
}
