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
