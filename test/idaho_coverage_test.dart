import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/idaho_coverage_loader.dart';
import 'package:lottery_atlas/services/idaho_coverage_validator.dart';

void main() {
  final raw = File('data/idaho_coverage.generated.json').readAsStringSync();
  test('audited typed baseline preserves unknown inventory', () {
    final data = IdahoCoverageValidator.decode(raw);
    expect(data['results'].length, 22);
    expect(
      data['scratch']['unavailableInventoryGames'].single['remainingPrizes'],
      isNull,
    );
  });
  test('changed counts, unknowns and missing components fail closed', () {
    for (final change in <void Function(dynamic)>[
      (d) => d['results'][0]['numbers'][0] = '99',
      (d) =>
          d['scratch']['unavailableInventoryGames'][0]['remainingPrizes'] = 0,
      (d) => d['instantCatalogs'].remove('tabs'),
      (d) => d['sourceEvidence'][0]['url'] = 'https://example.com/source',
    ]) {
      final data = jsonDecode(raw);
      change(data);
      expect(
        () => IdahoCoverageValidator.decode(jsonEncode(data)),
        throwsFormatException,
      );
    }
  });
  test('failed remote retains real cache without write', () async {
    var writes = 0;
    final data = await IdahoCoverageLoader(
      readCache: () async => raw,
      writeCache: (_) async {
        writes++;
      },
      fetchRemote: () async => throw const SocketException('controlled'),
      readBundle: () async => throw StateError('cache expected'),
    ).load();
    expect(data['collectionStartedAt'], jsonDecode(raw)['collectionStartedAt']);
    expect(writes, 0);
  });
  test(
    'invalid cache uses bundle and invalid remote never overwrites',
    () async {
      var writes = 0;
      final data = await IdahoCoverageLoader(
        readCache: () async => '{}',
        writeCache: (_) async {
          writes++;
        },
        fetchRemote: () async => '{}',
        readBundle: () async => raw,
      ).load();
      expect(data['state'], 'Idaho');
      expect(writes, 0);
    },
  );
  test('valid remote survives persistence error', () async {
    final data = await IdahoCoverageLoader(
      readCache: () async => null,
      writeCache: (_) async => throw const FileSystemException('controlled'),
      fetchRemote: () async => raw,
      readBundle: () async => raw,
    ).load();
    expect(data['results'].length, 22);
  });
  test(
    'numeric Scratch decreases adopt without inventing verification date',
    () async {
      final candidate = jsonDecode(raw);
      candidate['scratch']['games'][0]['topPrizesRemaining'] = 1;
      candidate['scratch']['games'][0]['prizeTiers'][0]['remaining'] = 1;
      String? saved;
      final result = await IdahoCoverageLoader(
        readCache: () async => raw,
        writeCache: (value) async {
          saved = value;
        },
        fetchRemote: () async => jsonEncode(candidate),
        readBundle: () async => raw,
      ).load();
      expect(result['scratch']['games'][0]['topPrizesRemaining'], 1);
      expect(result['scratch']['games'][0]['sourceDate'], isNull);
      expect(saved, jsonEncode(candidate));
    },
  );
  test('Scratch structural and count mutations fail closed', () {
    for (final change in <void Function(dynamic)>[
      (d) => d['scratch']['games'][0]['prizeTiers'][1]['remaining'] = -1,
      (d) => d['scratch']['games'][0]['prizeTiers'][1]['remaining'] = 6,
      (d) => d['scratch']['games'][0]['prizeTiers'][1]['remaining'] = 1.5,
      (d) => d['scratch']['games'][0]['prizeTiers'][1]['original'] = 6,
      (d) => d['scratch']['games'][0]['topPrizesRemaining'] = 1,
      (d) => d['scratch']['games'].removeLast(),
      (d) => d['scratch']['games'][0]['sourceDate'] = '2026-10-23',
    ]) {
      final candidate = jsonDecode(raw);
      change(candidate);
      expect(
        () => IdahoCoverageValidator.decode(jsonEncode(candidate)),
        throwsFormatException,
      );
    }
  });
  test(
    'remote cannot increase counts relative to newer retained cache',
    () async {
      final cached = jsonDecode(raw);
      cached['scratch']['games'][0]['prizeTiers'][1]['remaining'] = 3;
      var writes = 0;
      final result = await IdahoCoverageLoader(
        readCache: () async => jsonEncode(cached),
        writeCache: (_) async {
          writes++;
        },
        fetchRemote: () async => raw,
        readBundle: () async => raw,
      ).load();
      expect(result['scratch']['games'][0]['prizeTiers'][1]['remaining'], 3);
      expect(writes, 0);
    },
  );
  test(
    'Raffle promotion advances independently of unavailable final result',
    () async {
      final candidate = jsonDecode(raw);
      candidate['raffle']['dailyPromotions'].add({
        'date': '2026-10-22',
        'ticketNumber': '000001',
      });
      final result = await IdahoCoverageLoader(
        readCache: () async => raw,
        writeCache: (_) async {},
        fetchRemote: () async => jsonEncode(candidate),
        readBundle: () async => raw,
      ).load();
      expect(result['raffle']['dailyPromotions'].length, 2);
      expect(result['raffle']['finalResult'], isNull);
    },
  );
  test(
    'Raffle invalid dates, ticket ranges and final inference fail closed',
    () {
      for (final row in [
        {'date': '2026-10-21', 'ticketNumber': '000001'},
        {'date': '2026-10-24', 'ticketNumber': '000001'},
        {'date': '2026-10-32', 'ticketNumber': '000001'},
        {'date': '2026-10-22', 'ticketNumber': '000000'},
        {'date': '2026-10-22', 'ticketNumber': '500001'},
        {'date': '2026-10-22', 'ticketNumber': '1'},
        {'date': '2026-10-22', 'ticketNumber': 1},
      ]) {
        final candidate = jsonDecode(raw);
        candidate['raffle']['dailyPromotions'].add(row);
        expect(
          () => IdahoCoverageValidator.decode(jsonEncode(candidate)),
          throwsFormatException,
        );
      }
      final candidate = jsonDecode(raw);
      candidate['raffle']['finalResult'] = '012426';
      expect(
        () => IdahoCoverageValidator.decode(jsonEncode(candidate)),
        throwsFormatException,
      );
    },
  );
  test('Raffle future date uses Boise collection calendar', () {
    final candidate = jsonDecode(raw);
    candidate['collectionStartedAt'] = '2026-10-23T00:30:00Z';
    candidate['raffle']['dailyPromotions'].add({
      'date': '2026-10-23',
      'ticketNumber': '000001',
    });
    expect(
      () => IdahoCoverageValidator.decode(jsonEncode(candidate)),
      throwsFormatException,
    );
  });
  test('Raffle retained promotions cannot disappear or change', () async {
    final cached = jsonDecode(raw);
    cached['raffle']['dailyPromotions'].add({
      'date': '2026-10-22',
      'ticketNumber': '000001',
    });
    for (final correction in [false, true]) {
      final candidate = jsonDecode(correction ? jsonEncode(cached) : raw);
      if (correction) {
        candidate['raffle']['dailyPromotions'][1]['ticketNumber'] = '000002';
      }
      var writes = 0;
      final result = await IdahoCoverageLoader(
        readCache: () async => jsonEncode(cached),
        writeCache: (_) async {
          writes++;
        },
        fetchRemote: () async => jsonEncode(candidate),
        readBundle: () async => raw,
      ).load();
      expect(
        result['raffle']['dailyPromotions'],
        cached['raffle']['dailyPromotions'],
      );
      expect(writes, 0);
    }
  });
  dynamic advance() {
    final data = jsonDecode(raw);
    final groups = <String, List<dynamic>>{};
    for (final r in data['results']) {
      groups.putIfAbsent(r['group'], () => []).add(r);
    }
    final rows = <dynamic>[];
    for (final group in groups.values) {
      group.sort((a, b) => (b['drawDate'] as String).compareTo(a['drawDate']));
      final latest = group.first;
      final newer = jsonDecode(jsonEncode(latest));
      newer['drawDate'] = '2026-10-23';
      newer['sourceUrl'] = newer['sourceUrl'].replaceAll(
        latest['drawDate'],
        '2026-10-23',
      );
      if (newer['report'] != null) {
        newer['report']['sourceUrl'] = newer['sourceUrl'];
        if (newer['report'].containsKey('drawDate')) {
          newer['report']['drawDate'] = '2026-10-23';
        }
      }
      rows.addAll([newer, latest]);
    }
    data['results'] = rows;
    return data;
  }

  test(
    'all eleven draw groups advance with exact reports and Pick gaps',
    () async {
      final next = advance();
      String? saved;
      final result = await IdahoCoverageLoader(
        readCache: () async => raw,
        writeCache: (s) async {
          saved = s;
        },
        fetchRemote: () async => jsonEncode(next),
        readBundle: () async => raw,
      ).load();
      expect(result['results'], next['results']);
      expect(saved, jsonEncode(next));
    },
  );
  test('draw and report shape mutations reject on advancing windows', () {
    for (final change in <void Function(dynamic)>[
      (d) => d['results'][0]['numbers'][1] = d['results'][0]['numbers'][0],
      (d) => d['results'][0]['multiplier'] = 6,
      (d) => d['results'][0]['sourceUrl'] += '/wrong',
      (d) => d['results'][0]['report']['sourceLabel'] = 'National Winners',
      (d) => d['results'][0]['report']['tiers'][0]['publishedWinnerCount'] = -1,
      (d) =>
          d['results'][0]['report']['tiers'][0]['publishedWinnerCount'] = 1.5,
      (d) => d['results'][0]['report']['tiers'][0]['sourceTier'] = 'base',
      (d) => d['results'][0]['report']['tiers'].removeLast(),
      (d) => d['results'].removeLast(),
      (d) => d['results'][0]['drawDate'] = '2026-10-24',
    ]) {
      final candidate = advance();
      change(candidate);
      expect(
        () => IdahoCoverageValidator.decode(jsonEncode(candidate)),
        throwsFormatException,
      );
    }
  });
  test('draw correction and date regression retain newer cache', () async {
    final cached = advance();
    for (final correction in [false, true]) {
      final candidate = correction
          ? jsonDecode(jsonEncode(cached))
          : jsonDecode(raw);
      if (correction) {
        candidate['results'][0]['report']['tiers'][0]['publishedWinnerCount'] =
            12;
      }
      var writes = 0;
      final result = await IdahoCoverageLoader(
        readCache: () async => jsonEncode(cached),
        writeCache: (_) async {
          writes++;
        },
        fetchRemote: () async => jsonEncode(candidate),
        readBundle: () async => raw,
      ).load();
      expect(result['results'], cached['results']);
      expect(writes, 0);
    }
  });
  test('exact-date previously missing report may become available', () {
    final candidate = jsonDecode(raw);
    final rows = candidate['results'] as List;
    final latest = rows.firstWhere((r) => r['group'] == 'millionaire-for-life');
    final older = rows.lastWhere((r) => r['group'] == 'millionaire-for-life');
    older['report'] = jsonDecode(jsonEncode(latest['report']));
    older['report']['drawDate'] = older['drawDate'];
    older['reportGap'] = null;
    expect(
      IdahoCoverageValidator.decode(jsonEncode(candidate))['results'],
      rows,
    );
  });
  test(
    'session, multiplier, image and dated report identities remain strict',
    () {
      for (final change in <void Function(List)>[
        (rs) =>
            rs.firstWhere((r) => r['group'] == 'mega-millions')['multiplier'] =
                2,
        (rs) => rs.firstWhere((r) => r['group'] == 'pick-3-day')['session'] =
            'night',
        (rs) => rs.firstWhere((r) => r['group'] == 'pick-4-day')['numbers'][0] =
            '01',
        (rs) => rs.firstWhere(
          (r) => r['group'] == 'powerball-xs-os',
        )['imageUrls'][0] = 'https://example.com/logo.png',
        (rs) => rs.firstWhere(
          (r) => r['group'] == 'millionaire-for-life',
        )['report']['drawDate'] = '2026-10-22',
        (rs) => rs.firstWhere(
          (r) => r['group'] == 'powerball-double-play',
        )['multiplier'] = 2,
      ]) {
        final candidate = advance();
        change(candidate['results']);
        expect(
          () => IdahoCoverageValidator.decode(jsonEncode(candidate)),
          throwsFormatException,
        );
      }
    },
  );
}
