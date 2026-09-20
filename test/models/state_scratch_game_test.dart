import 'package:flutter_test/flutter_test.dart';
import 'package:lottery_atlas/models/state_scratch_game.dart';

void main() {
  test('accepts a complete published Scratch-Off ticket', () {
    final game = StateScratchGame.fromJson(<String, dynamic>{
      'stateName': 'Arizona',
      'id': '123',
      'name': 'Desert Cash',
      'cost': 10,
      'topPrize': 1000000,
      'topPrizesRemaining': 2,
    });

    expect(game.stateName, 'Arizona');
    expect(game.topPrize, 1000000);
    expect(game.topPrizesRemaining, 2);
  });

  test(
    'preserves special prize labels and source notes through cache JSON',
    () {
      final game = StateScratchGame.fromJson(<String, dynamic>{
        'stateName': 'Washington',
        'id': '2004',
        'name': 'Keys and Cash',
        'cost': 10,
        'topPrize': 25000,
        'topPrizeLabel': 'BRONCO',
        'topPrizesRemaining': 2,
        'inventoryNote':
            'Prize inventory as of 2026-09-19; store availability unverified.',
      });
      final restored = StateScratchGame.fromJson(game.toJson());
      expect(restored.topPrizeLabel, 'BRONCO');
      expect(restored.topPrizesRemaining, 2);
      expect(restored.inventoryNote, game.inventoryNote);
    },
  );

  test('rejects a catalog ticket without its verified price', () {
    expect(
      () => StateScratchGame.fromJson(<String, dynamic>{
        'stateName': 'Arizona',
        'id': '123',
        'name': 'Desert Cash',
        'topPrize': 1000000,
      }),
      throwsFormatException,
    );
  });
}
