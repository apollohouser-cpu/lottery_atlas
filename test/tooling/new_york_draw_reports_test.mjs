import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {parseNewYorkPowerball} from '../../tooling/new_york_draw_reports.mjs';
const fixture = JSON.parse(readFileSync(new URL('./fixtures/new_york_powerball.json', import.meta.url)));
test('NY Powerball variants exclude national metadata and duplicate aliases', () => {
  const raw = structuredClone(fixture);
  raw.national_winners = [{prize_winners: 999999}];
  const report = parseNewYorkPowerball(raw);
  assert.deepEqual(report.tables.map(t => t.tiers.length), [9, 8, 9]);
  assert.equal(report.tables[0].tiers[1].reportedWinners, 0);
  assert.equal(report.tables[0].tiers[2].reportedWinners, 1);
  assert.equal(report.tables[2].tiers.reduce((s,t) => s+t.reportedWinners,0), 4432);
  assert.equal(report.tables[1].tiers[1].prizeLabel, '200000');
  assert.equal(report.sourcePublicationDate, null);
});
test('partial, duplicate and conflicting tables fail instead of zero-fill', () => {
  for (const mutate of [r => r.local_winners.pop(), r => r.local_winners[1]=r.local_winners[0],
    r => r.local_multiplier_winners[0].prize_winners=1,
    r => r.dp_local_winners[0].prize_winners=null]) {
    const raw=structuredClone(fixture); mutate(raw); assert.throws(()=>parseNewYorkPowerball(raw));
  }
});
test('invalid calendar dates and multipliers fail', () => {
  for (const change of [{date:'2026-02-30'}, {multiplier:'0'}, {draw_number:''}]) {
    assert.throws(()=>parseNewYorkPowerball({...fixture,...change}));
  }
});

import {parseNewYorkMegaMillions} from '../../tooling/new_york_draw_reports.mjs';
const mega = JSON.parse(readFileSync(new URL('./fixtures/new_york_mega_millions.json', import.meta.url)));
test('Mega Millions preserves five built-in multiplier groups without national counts', () => {
  const raw=structuredClone(mega); raw.national_winners=[{prize_winners:999999}];
  const report=parseNewYorkMegaMillions(raw);
  assert.deepEqual(report.tables.map(t=>t.tiers.length), [1,8,8,8,8,8]);
  assert.equal(report.tables[1].tiers[2].prizeLabel,'1000');
  assert.equal(report.tables[1].tiers[2].reportedWinners,3);
  assert.equal(report.tables.flatMap(t=>t.tiers).reduce((s,t)=>s+t.reportedWinners,0),17175);
});
test('Mega Millions missing, duplicated, unknown or null multiplier data fails', () => {
  for (const mutate of [r=>r.second_prz_multiplier_winners.pop(),
    r=>r.third_prz_multiplier_winners[1].mm_multiplier_level='2X',
    r=>r.fourth_prz_multiplier_winners[0].mm_multiplier_level='8X',
    r=>r.local_winners[0].prize_winners=null]) {
    const raw=structuredClone(mega);mutate(raw);assert.throws(()=>parseNewYorkMegaMillions(raw));
  }
});
