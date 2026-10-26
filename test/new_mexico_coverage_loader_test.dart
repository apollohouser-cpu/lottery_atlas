import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/new_mexico_coverage_loader.dart';
import 'package:lottery_atlas/services/new_mexico_coverage_validator.dart';

void main() {
  final raw = File(
    'data/new_mexico_coverage.generated.json',
  ).readAsStringSync();
  Map<String, dynamic> fixture() => jsonDecode(raw);
  test('reviewed bundle retains exact reports and explicit gaps', () {
    final data = NewMexicoCoverageValidator.decode(raw);
    expect(data['results'], hasLength(18));
    expect(
      (data['results'] as List).where((r) => r['report'] != null),
      hasLength(4),
    );
    expect(data['scratch']['games'], hasLength(57));
    expect(data['scratch']['sourceTimezone'], isNull);
  });
  test('estimated inventory decreases but cannot increase against cache', () {
    final old = fixture();
    old['scratch']['games'][0]['topPrizesRemaining'] -= 2;
    final next = fixture();
    next['scratch']['games'][0]['topPrizesRemaining'] -= 1;
    NewMexicoCoverageValidator.decode(jsonEncode(old));
    expect(
      () => NewMexicoCoverageValidator.continuity(old, next),
      throwsFormatException,
    );
  });
  test('changed results reports units rules and unknown keys fail closed', () {
    final mutations = <void Function(Map<String, dynamic>)>[
      (d) => d['results'][0]['numbers'][0] = '99',
      (d) => (d['results'] as List).firstWhere(
        (r) => r['report'] != null,
      )['report']['totalPrizesWon'] = 0,
      (d) => (d['results'] as List).firstWhere(
        (r) => r['report'] != null,
      )['report']['countUnit'] = 'people',
      (d) => d['rules'][0]['text'] = 'changed',
      (d) => d['scratch']['sourceTimezone'] = 'America/Denver',
      (d) => d['invented'] = true,
      (d) => d['scratch']['games'][0]['topPrizesRemaining'] = null,
      (d) => d['sources'][0]['sha256'] = 'invalid',
      (d) => d['results'][0]['retrievedAt'] = d['updatedAt'],
      (d) => d['updatedAt'] = '2026-10-25T00:00:00Z',
    ];
    for (final mutate in mutations) {
      final data = fixture();
      mutate(data);
      expect(
        () => NewMexicoCoverageValidator.decode(jsonEncode(data)),
        throwsFormatException,
      );
    }
  });
  test('unpaired Powerball date advancement is rejected', () {
    final data = fixture();
    data['results'][0]['date'] = '2026-10-26';
    expect(
      () => NewMexicoCoverageValidator.decode(jsonEncode(data)),
      throwsFormatException,
    );
  });
  test(
    'valid refreshed capture times and decreased inventory adopted and persisted',
    () async {
      final data = fixture();
      void advance(dynamic v) {
        if (v is Map) {
          for (final k in v.keys.toList()) {
            if (['updatedAt', 'retrievedAt', 'endingRetrievedAt'].contains(k)) {
              v[k] = DateTime.parse(
                fixture()['updatedAt'] as String,
              ).add(const Duration(seconds: 1)).toIso8601String();
            } else {
              advance(v[k]);
            }
          }
        } else if (v is List) {
          for (final item in v) {
            advance(item);
          }
        }
      }

      advance(data);
      data['scratch']['games'][0]['topPrizesRemaining'] -= 1;
      final newer = jsonEncode(data);
      String? saved;
      final loaded = await NewMexicoCoverageLoader(
        readCache: () async => raw,
        writeCache: (s) async {
          saved = s;
        },
        fetchRemote: () async => newer,
      ).load();
      expect(loaded['updatedAt'], data['updatedAt']);
      expect(saved, newer);
    },
  );
  test('network failure preserves cache bytes and original date', () async {
    var writes = 0;
    final loaded = await NewMexicoCoverageLoader(
      readCache: () async => raw,
      writeCache: (_) async {
        writes++;
      },
      fetchRemote: () async => throw const SocketException('controlled'),
    ).load();
    expect(loaded, fixture());
    expect(writes, 0);
  });
  test('remote correction preserves valid cache', () async {
    final changed = fixture();
    changed['results'][0]['specialBall'] = 99;
    var writes = 0;
    final loaded = await NewMexicoCoverageLoader(
      readCache: () async => raw,
      writeCache: (_) async {
        writes++;
      },
      fetchRemote: () async => jsonEncode(changed),
    ).load();
    expect(loaded, fixture());
    expect(writes, 0);
  });
  test(
    'corrupt cache plus unavailable remote falls back to reviewed bundle',
    () async {
      final loaded = await NewMexicoCoverageLoader(
        readCache: () async => '{bad',
        readBundle: () async => raw,
        fetchRemote: () async => throw const SocketException('controlled'),
      ).load();
      expect(loaded, fixture());
    },
  );
  test('cache write failure still returns validated response', () async {
    final loaded = await NewMexicoCoverageLoader(
      readCache: () async => null,
      readBundle: () async => raw,
      fetchRemote: () async => raw,
      writeCache: (_) async => throw const FileSystemException('controlled'),
    ).load();
    expect(loaded, fixture());
  });
}
