import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/montana_coverage_contract.dart';
import 'package:lottery_atlas/services/montana_coverage_loader.dart';
import 'package:lottery_atlas/services/montana_coverage_validator.dart';

void main() {
  const raw = montanaCoverageContractJson;
  Map<String, dynamic> data() => jsonDecode(raw);
  test('bundle and published feed validate all groups and product gaps', () {
    final d = MontanaCoverageValidator.decode(
      File('data/montana_coverage.generated.json').readAsStringSync(),
    );
    expect(d['results'].length, 14);
    expect(d['catalogs']['scratch']['entries'].length, 57);
    expect(d['catalogs']['treasure-play']['entries'].length, 12);
  });
  test(
    'reject malformed identities, provenance, rules and inferred availability',
    () {
      final mutations = <void Function(Map<String, dynamic>)>[
        (d) => d['results'][0]['numbers'][0] = 99,
        (d) => d['results'][0]['drawId'] = 1,
        (d) => d['results'][0]['reportStatus'] = 'available',
        (d) => d['results'][0]['drawDate'] = '2026-02-30',
        (d) => d['results'][0]['multiplier'] = true,
        (d) => d['results'][2]['multiplier'] = 2,
        (d) => d['results'][0]['sourceRetrievedAt'] = d['updatedAt'],
        (d) => d['rules'][0]['sections'].clear(),
        (d) => d['sources'][0]['sha256'] = 'bad',
        (d) => d['sources'][0]['url'] = 'https://example.com/',
        (d) => d['status']['retiredGames'].clear(),
        (d) => d['catalogs']['scratch']['entries'][0]['salesStatus'] = 'active',
        (d) => d['catalogs']['scratch']['entries'].removeLast(),
        (d) =>
            d['catalogs']['treasure-play']['entries'][0]['advertisedJackpot']['amountText'] =
                '\$1.50',
        (d) => d['endings']['rows'].clear(),
        (d) => d['raffle']['resultStatus'] = 'available',
        (d) => d['privateId'] = 'unexpected',
      ];
      for (final mutate in mutations) {
        final d = data();
        mutate(d);
        expect(
          () => MontanaCoverageValidator.decode(jsonEncode(d)),
          throwsA(anything),
        );
      }
    },
  );
  test('advertised estimates can rise or fall without schedule changes', () {
    for (final amount in ['\$0', '\$25,000', '\$40,000']) {
      final d = data();
      d['catalogs']['treasure-play']['entries'][0]['advertisedJackpot']['amountText'] =
          amount;
      expect(
        MontanaCoverageValidator.decode(
          jsonEncode(d),
        )['catalogs']['treasure-play']['entries'][0]['advertisedJackpot']['amountText'],
        amount,
      );
    }
  });
  test(
    'synthetic daily date advancement accepts and cached regression rejects',
    () async {
      final d = data();
      const stamp = '2026-10-28T15:00:00+00:00';
      d['updatedAt'] = stamp;
      for (final source in d['sources']) {
        source['retrievedAt'] = stamp;
      }
      for (final rule in d['rules']) {
        rule['retrievedAt'] = stamp;
      }
      for (final row in d['results']) {
        row['sourceRetrievedAt'] = stamp;
      }
      for (final kind in ['scratch', 'treasure-play']) {
        d['catalogs'][kind]['retrievedAt'] = stamp;
      }
      d['status']['retrievedAt'] = stamp;
      d['raffle']['retrievedAt'] = stamp;
      d['endings']['sourceRetrievedAt'] = stamp;
      d['results'][13] = jsonDecode(jsonEncode(d['results'][12]));
      d['results'][12]['drawDate'] = '2026-10-28';
      final advanced = jsonEncode(d);
      expect(
        MontanaCoverageValidator.decode(advanced)['results'][12]['drawDate'],
        '2026-10-28',
      );
      var writes = 0;
      final loader = MontanaCoverageLoader(
        readCache: () async => advanced,
        fetchRemote: () async => raw,
        writeCache: (_) async {
          writes++;
        },
      );
      expect((await loader.load())['updatedAt'], stamp);
      expect(writes, 0);
    },
  );
  test('failure retains cache without writing', () async {
    var writes = 0;
    final loader = MontanaCoverageLoader(
      readCache: () async => raw,
      fetchRemote: () async => throw const SocketException('controlled'),
      writeCache: (_) async {
        writes++;
      },
    );
    expect((await loader.load())['updatedAt'], data()['updatedAt']);
    expect(writes, 0);
  });
  test('corrupt cache and remote use bundle', () async {
    final loader = MontanaCoverageLoader(
      readCache: () async => '{}',
      readBundle: () async => raw,
      fetchRemote: () async => '{}',
    );
    expect((await loader.load())['results'].length, 14);
  });
  test('valid remote survives write failure', () async {
    final loader = MontanaCoverageLoader(
      readCache: () async => raw,
      fetchRemote: () async => raw,
      writeCache: (_) async => throw StateError('disk'),
    );
    expect((await loader.load())['results'].length, 14);
  });
  test(
    'cached estimate update accepts valid remote and persists exact bytes',
    () async {
      final d = data();
      d['catalogs']['treasure-play']['entries'][0]['advertisedJackpot']['amountText'] =
          '\$40,000';
      final next = jsonEncode(d);
      String? written;
      final loader = MontanaCoverageLoader(
        readCache: () async => raw,
        fetchRemote: () async => next,
        writeCache: (v) async {
          written = v;
        },
      );
      await loader.load();
      expect(written, next);
    },
  );
  test('correction to same draw is rejected and old cache remains', () async {
    final d = data();
    final numbers = d['results'][0]['numbers'] as List;
    numbers[0] = numbers[0] == 1 ? 2 : 1;
    var writes = 0;
    final loader = MontanaCoverageLoader(
      readCache: () async => raw,
      fetchRemote: () async => jsonEncode(d),
      writeCache: (_) async {
        writes++;
      },
    );
    expect((await loader.load())['results'], data()['results']);
    expect(writes, 0);
  });
}
