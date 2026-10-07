import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/services/missouri_draw_reports_loader.dart';

void main() {
  final raw = File(
    'data/missouri_draw_reports.generated.json',
  ).readAsStringSync();
  test(
    'valid report bundle preserves variants and fractional source units',
    () async {
      final d = await MissouriDrawReportsLoader(
        readCache: () async => null,
        fetchRemote: () async => throw Exception('offline'),
        readBundle: () async => raw,
      ).load();
      expect((d['reports'] as List).length, 28);
      expect(
        (d['reports'] as List)
            .where((r) => r['family'] == 'pick4')
            .first['playBasisCents'],
        50,
      );
    },
  );
  test('bad remote cannot replace valid cache', () async {
    final bad = jsonDecode(raw);
    bad['reports'][0]['sourceUrl'] = 'https://example.com/';
    bool wrote = false;
    final d = await MissouriDrawReportsLoader(
      readCache: () async => raw,
      fetchRemote: () async => jsonEncode(bad),
      writeCache: (_) async {
        wrote = true;
      },
      readBundle: () async => throw Exception('must use cache'),
    ).load();
    expect(d['updatedAt'], jsonDecode(raw)['updatedAt']);
    expect(wrote, false);
  });
  test(
    'regression keeps cache and successful refresh tolerates write failure',
    () async {
      final bad = jsonDecode(raw);
      bad['updatedAt'] = '2020-01-01T00:00:00Z';
      final d = await MissouriDrawReportsLoader(
        readCache: () async => raw,
        fetchRemote: () async => jsonEncode(bad),
      ).load();
      expect(d['updatedAt'], jsonDecode(raw)['updatedAt']);
      final fresh = await MissouriDrawReportsLoader(
        readCache: () async => null,
        fetchRemote: () async => raw,
        writeCache: (_) async => throw Exception('disk'),
      ).load();
      expect(fresh['stateCode'], 'MO');
    },
  );
  test(
    'invalid bundle rejects missing session and changed monetary units',
    () async {
      for (final change in ['session', 'amount']) {
        final bad = jsonDecode(raw);
        if (change == 'session') {
          bad['reports'].removeLast();
        } else {
          bad['reports']
                  .firstWhere(
                    (r) => r['family'] == 'pick4',
                  )['variants'][1]['tiers']
                  .last['sourceAmountCents'] =
              751;
        }
        await expectLater(
          MissouriDrawReportsLoader(
            readCache: () async => null,
            fetchRemote: () async => throw Exception('offline'),
            readBundle: () async => jsonEncode(bad),
          ).load(),
          throwsFormatException,
        );
      }
    },
  );
}
