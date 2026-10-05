import test from 'node:test';
import assert from 'node:assert/strict';
import {parseOregonAggregate} from '../../tooling/oregon_draw_reports.mjs';

const row = {DrawNumber: 10, DrawIsFinal: true, GameVersion: 0,
  DrawDateTime: '2026-10-04T21:59:00', RoundedDrawDateTime: '2026-10-04T22:00:00',
  OregonJackpotWinners: 14, JackpotShareAmount: 380,
  OregonShareCounts: [999], OutsideJackpotWinners: 9999, ShareAmounts: [1000000]};

test('aggregate fields preserve reported units and exclude misleading tiers/outside counts', () => {
  for (const game of ['mm', 'cp']) {
    const report = parseOregonAggregate(game, row);
    assert.equal(report.reportedWinners, 14);
    assert.equal(report.publishedPayoutDollars, 380);
    assert.equal(report.winningTickets, null);
    assert.equal('tiers' in report, false);
    assert.equal('OutsideJackpotWinners' in report, false);
  }
  assert.equal(parseOregonAggregate('cp', row).drawingTime, '22:00');
  assert.equal(parseOregonAggregate('cp', row).sourceDrawDateTime, row.DrawDateTime);
});

test('unknown, fractional counts and invalid money fail; explicit zero is preserved', () => {
  for (const value of [undefined, null, '1', -1, 1.5, NaN, Infinity]) {
    assert.throws(() => parseOregonAggregate('mm', {...row, OregonJackpotWinners: value}));
  }
  for (const value of [undefined, null, '1', -1, .001, NaN, Infinity]) {
    assert.throws(() => parseOregonAggregate('mm', {...row, JackpotShareAmount: value}));
  }
  assert.equal(parseOregonAggregate('mm', {...row, OregonJackpotWinners: 0, JackpotShareAmount: 0}).reportedWinners, 0);
});

test('unfinalized, historical, invalid dates and mismatched schedules fail closed', () => {
  for (const patch of [{DrawIsFinal: false}, {GameVersion: 1}, {DrawNumber: 0},
    {DrawDateTime: '2026-02-30T22:00:00'}, {DrawDateTime: '2025-04-07T22:00:00'}]) {
    assert.throws(() => parseOregonAggregate('mm', {...row, ...patch}));
  }
  for (const value of ['2026-10-05T07:00:00', '2026-10-04T22:01:00', '2026-10-04T21:00:00']) {
    assert.throws(() => parseOregonAggregate('cp', {...row, RoundedDrawDateTime: value}));
  }
  assert.throws(() => parseOregonAggregate('pb', row));
});
