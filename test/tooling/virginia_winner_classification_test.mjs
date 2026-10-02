import {test} from 'node:test';
import assert from 'node:assert/strict';
import {gameFrom} from '../../tooling/virginia_winner_classification.mjs';
const catalog = [{name: 'BINGO MULTIPLIER'}];
test('Print n Play is not a same-name Scratcher', () => {
  for (const title of ["Print 'n Play Bingo Multiplier", 'Print ‘n Play Bingo Multiplier']) {
    assert.equal(gameFrom({Title: title}, '', catalog), null);
  }
});
test('unknown news cannot default to Scratch', () => {
  assert.equal(gameFrom({Title: 'Winner receives prize'}, '', catalog), null);
});
test('explicit historic Scratch and current catalog titles remain supported', () => {
  assert.equal(gameFrom({Title: 'Winner playing Retired Riches scratcher'}, '', []).game, 'scratch-off');
  assert.equal(gameFrom({Title: 'BINGO MULTIPLIER winner'}, '', catalog).game, 'scratch-off');
});
test('current and historical draw identities remain distinct', () => {
  assert.equal(gameFrom({Title: 'Cash4Life winner'}, '', []).gameName, 'Cash4Life');
  assert.equal(gameFrom({Title: 'Millionaire for Life winner'}, '', []).gameName, 'Millionaire for Life');
});
