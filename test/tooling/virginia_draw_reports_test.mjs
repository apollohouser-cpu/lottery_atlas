import {test} from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {parseTableReports, assertNoReportRegression} from '../../tooling/virginia_draw_reports.mjs';
const fixture = (name) => JSON.parse(readFileSync(new URL(`./fixtures/virginia/${name}.json`, import.meta.url)));
test('official Virginia count tables preserve annual and tax wording', () => {
  const m = parseTableReports(fixture('millionaireforlife'), 1075)[0];
  assert.equal(m.totalWinners, 2254);
  assert.equal(m.tiers[0].prizeDescription, '$1,000,000 a year for life');
  assert.equal(m.totalPayout, null);
  const b = parseTableReports(fixture('bankamillion'), 1070)[0];
  assert.equal(b.totalWinners, 8423);
  assert.equal(b.tiers[0].prizeDescription, '$1,000,000 after taxes');
});
test('reject changed jurisdiction, malformed counts, tiers and duplicate dates', () => {
  for (const mutate of [p => p.data[0].DailyDrawDetails[0].DrawData.WinnerLocation = null,
    p => p.data[0].DailyDrawDetails[0].DrawData.Values[0].Winners = '1,2',
    p => p.data[0].DailyDrawDetails[0].DrawData.Values.pop(),
    p => p.data.push(p.data[0])]) {
    const p = fixture('millionaireforlife'); mutate(p);
    assert.throws(() => parseTableReports(p, 1075));
  }
});
test('reject unsupported national data and per-game date regression', () => {
  assert.throws(() => parseTableReports(fixture('millionaireforlife'), 20));
  const reports = parseTableReports(fixture('millionaireforlife'), 1075);
  assert.throws(() => assertNoReportRegression(reports, reports.slice(1)));
  assert.throws(() => assertNoReportRegression(reports, []));
  assert.doesNotThrow(() => assertNoReportRegression(reports, reports));
});
test('unpublished tier arrays are unavailable, not zero winner reports', () => {
  const p = fixture('millionaireforlife');
  p.data[0].DailyDrawDetails[0].DrawData.Values = [];
  assert.equal(parseTableReports(p, 1075).length, 1);
  p.data[1].DailyDrawDetails[0].DrawData.Values = [];
  assert.throws(() => parseTableReports(p, 1075));
});

import {parsePickReports} from '../../tooling/virginia_draw_reports.mjs';
test('Pick sessions preserve dollar totals and never invent counts', () => {
  for (const [name, id] of [['pick3', 1050], ['pick4', 1040], ['pick5', 1035]]) {
    const reports = parsePickReports(fixture(name), id);
    assert.equal(reports.length, 3);
    assert.equal(reports[0].totalWinners, null);
    assert.equal(reports[0].tiers.length, 0);
    assert.equal(reports[2].session, 'Night');
  }
  const p = parsePickReports(fixture('pick3'), 1050)[0];
  assert.deepEqual(p.components, [{name: 'Base', payout: 72675}, {name: 'FIREBALL', payout: 13260}]);
  assert.equal(p.totalPayout, 85935);
});
test('Pick rejects malformed or partial dollars, duplicate sessions and wrong game', () => {
  for (const mutate of [p => p.data[0].DailyDrawDetails[0].DrawData.TotalPrizes = '1,2',
    p => p.data[0].DailyDrawDetails[0].DrawData.TotalFireballPrizes = null,
    p => p.data[0].DailyDrawDetails.push(p.data[0].DailyDrawDetails[0]),
    p => p.data[0].DrawGameId = 1040]) {
    const p = fixture('pick3'); mutate(p);
    assert.throws(() => parsePickReports(p, 1050));
  }
});
test('Pick date preservation is per session and null totals remain unavailable', () => {
  const p = fixture('pick3');
  const all = parsePickReports(p, 1050);
  assert.throws(() => assertNoReportRegression(all, all.filter(r => r.session === 'Day')));
  p.data[0].DailyDrawDetails[0].DrawData.TotalPrizes = null;
  p.data[0].DailyDrawDetails[0].DrawData.TotalFireballPrizes = null;
  assert.equal(parsePickReports(p, 1050).length, 2);
});

import {parseCash5Reports} from '../../tooling/virginia_draw_reports.mjs';
test('Cash 5 reconciles base plays and payout, keeping EZ Match count unknown', () => {
  const r = parseCash5Reports(fixture('cash5'))[0];
  assert.equal(r.totalWinners, 5431);
  assert.equal(r.countUnit, 'base-game winning plays only');
  assert.deepEqual(r.components, [{name: 'Cash 5 base', payout: 8519}, {name: 'EZ Match', payout: 8070}]);
  assert.equal(r.totalPayout, 16589);
  assert.equal(r.tiers[0].prizeDescription, '$419,000');
});
test('Cash 5 rejects inconsistent totals, malformed tiers and missing EZ Match', () => {
  for (const mutate of [p => p.data[0].DailyDrawDetails[0].DrawData.TotalPrizes = '8,520',
    p => p.data[0].DailyDrawDetails[0].Prize2 = '8 Plays matched 3 of 5 / paying $200',
    p => p.data[0].DailyDrawDetails[0].DrawData.TotalEZMatchPrizes = null]) {
    const p = fixture('cash5'); mutate(p);
    assert.throws(() => parseCash5Reports(p));
  }
});

import {parseCashPopReports} from '../../tooling/virginia_draw_reports.mjs';
test('Cash Pop publication flags distinguish unavailable sessions from zero', () => {
  const p = fixture('cashpop');
  const reports = parseCashPopReports(p);
  assert.equal(reports.length, 9);
  assert.equal(reports[0].totalPayout, 35895);
  assert.equal(reports[0].totalWinners, null);
  assert.equal(reports.filter(r => r.drawDate === '2026-10-01').length, 4);
  p.data[0].DailyDrawDetails[0].bIsPrizesAfter = true;
  assert.equal(parseCashPopReports(p).find(r => r.drawDate === '2026-10-01' && r.session === 'After Hours').totalPayout, 0);
});
test('Cash Pop rejects unknown availability and malformed published dollars', () => {
  for (const mutate of [p => p.data[0].DailyDrawDetails[0].bIsPrizesAfter = null,
    p => p.data[0].DailyDrawDetails[0].DrawData.TotalPrizesCoffee = '$35,895',
    p => p.data.push(p.data[0])]) {
    const p = fixture('cashpop'); mutate(p);
    assert.throws(() => parseCashPopReports(p));
  }
});
