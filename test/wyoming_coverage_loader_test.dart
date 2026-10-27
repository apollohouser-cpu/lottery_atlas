import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/wyoming_coverage_loader.dart';
import 'package:lottery_atlas/services/wyoming_coverage_validator.dart';

void main() {
  final raw = File('data/wyoming_coverage.generated.json').readAsStringSync();
  Map<String, dynamic> data() => jsonDecode(raw);
  test('baseline has all groups and unavailable reports', () {
    final d = WyomingCoverageValidator.decode(raw);
    expect(d['results'].length, 15);
  });
  test('rejects number, identity, date, rule and provenance mutations', () {
    final mutations = <void Function(Map<String, dynamic>)>[
      (d) => d['results'][0]['numbers'][0] = 99,
      (d) => d['results'][0]['drawId'] = true,
      (d) => d['results'][0]['drawDate'] = '2026-10-25',
      (d) => d['results'][0]['reportStatus'] = 'available',
      (d) => d['results'][0]['sourceRetrievedAt'] = d['updatedAt'],
      (d) => d['results'].removeLast(),
      (d) => d['rules'][0]['visualSchedule']['rows'].clear(),
      (d) => d['sources'][3]['url'] = 'https://example.com/',
      (d) => d['sources'][0]['sha256'] = 'bad',
      (d) => d['kenoWindow']['firstId']--,
      (d) => d['customerId'] = 'private',
    ];
    for (final mutate in mutations) {
      final d = data();
      mutate(d);
      expect(
        () => WyomingCoverageValidator.decode(jsonEncode(d)),
        throwsA(anything),
      );
    }
  });
  test('failure retains validated cache without writing', () async {
    var writes = 0;
    final loader = WyomingCoverageLoader(
      readCache: () async => raw,
      readBundle: () async => throw StateError('unused'),
      fetchRemote: () async => throw const SocketException('controlled'),
      writeCache: (_) async {
        writes++;
      },
    );
    expect((await loader.load())['updatedAt'], data()['updatedAt']);
    expect(writes, 0);
  });
  test(
    'corrupt cache falls back to bundle and rejects corrupt remote',
    () async {
      final loader = WyomingCoverageLoader(
        readCache: () async => '{}',
        readBundle: () async => raw,
        fetchRemote: () async => '{}',
        writeCache: (_) async => fail('invalid write'),
      );
      expect((await loader.load())['results'].length, 15);
    },
  );
  test('valid remote survives persistence failure', () async {
    final loader = WyomingCoverageLoader(
      readCache: () async => null,
      readBundle: () async => raw,
      fetchRemote: () async => raw,
      writeCache: (_) async => throw FileSystemException('controlled'),
    );
    expect((await loader.load())['results'].length, 15);
  });
  test('bounded Keno window advances and retained correction fails', () {
    final next = data();
    final rows = next['results'] as List;
    final newest = Map<String, dynamic>.from(
      rows.firstWhere((r) => r['game'] == 'keno'),
    );
    newest['drawId']++;
    newest['drawTimeUtc'] = DateTime.parse(
      newest['drawTimeUtc'],
    ).add(const Duration(minutes: 4)).toIso8601String();
    rows.removeLast();
    rows.insert(10, newest);
    next['kenoWindow']['firstId']++;
    next['kenoWindow']['lastId']++;
    final uri = Uri.parse(next['sources'][9]['url']);
    final parts = List<String>.from(uri.pathSegments);
    parts[parts.length - 2] = '${next['kenoWindow']['firstId']}';
    parts[parts.length - 1] = '${next['kenoWindow']['lastId']}';
    next['sources'][9]['url'] = uri.replace(pathSegments: parts).toString();
    WyomingCoverageValidator.decode(jsonEncode(next));
    final corrupt = jsonDecode(jsonEncode(next)) as Map<String, dynamic>;
    corrupt['results'][10]['numbers'] =
        (corrupt['results'][10]['numbers'] as List).reversed.toList();
    expect(
      () => WyomingCoverageValidator.continuity(next, corrupt),
      throwsFormatException,
    );
  });
}
