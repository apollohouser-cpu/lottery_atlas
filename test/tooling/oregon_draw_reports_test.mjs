import test from 'node:test';
import assert from 'node:assert/strict';
import {parseOregonAggregate, parseOregonTiers} from '../../tooling/oregon_draw_reports.mjs';

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

function tierRow(game) {
  const size = {pb: 8, mb: 6, wf: 6, p4: 16}[game];
  return {...row, DrawDateTime: '2026-10-04T22:00:00', Multiplier: 2,
    JackpotShareAmount: game === 'wf' ? 52000 : 300,
    OregonShareCounts: Array.from({length: 16}, (_, i) => i < size ? 1 : 0),
    ShareAmounts: Array.from({length: 16}, (_, i) => i < size ? 100 : 0)};
}

test('tier reports preserve shared cents, weekly prize, multiplier context and explicit zero counts', () => {
  const mb = tierRow('mb'); mb.ShareAmounts[0] = 3008.8; mb.OregonShareCounts[0] = 0;
  const report = parseOregonTiers('mb', mb);
  assert.equal(report.tiers.length, 7);
  assert.equal(report.tiers[1].prizeDollars, 3008.8);
  assert.equal(report.tiers[1].reportedWinners, 0);
  assert.equal(report.tiers[1].match, null);
  const wf = parseOregonTiers('wf', tierRow('wf'));
  assert.equal(wf.tiers[0].prizeDollars, null);
  assert.equal(wf.tiers[0].prizeText, '$1,000 a week for life');
  const pb = parseOregonTiers('pb', tierRow('pb'));
  assert.equal(pb.tiers.length, 9);
  assert.equal(pb.multiplier, 2);
  assert.equal(pb.tiers[1].prizeDollars, 100); // Do not multiply or synthesize awards.
  assert.equal(pb.tiers[1].reportedWinners, 1);
  assert.equal('reportedWinners' in pb, false); // No cross-tier sum.
  assert.equal('OutsideJackpotWinners' in pb, false);
});

test('Pick 4 groups identical monetary prizes and retains four source sessions', () => {
  for (const hour of ['13', '16', '19', '22']) {
    const report = parseOregonTiers('p4', {...tierRow('p4'), DrawDateTime: `2026-10-04T${hour}:00:00`});
    assert.equal(report.drawingTime, `${hour}:00`);
    assert.equal(report.tiers.length, 2);
    assert.equal(report.tiers[1].reportedWinners, 16);
    assert.equal(report.tiers[1].sourceRows.length, 16);
    assert.equal(report.winningTickets, null);
  }
});

test('tier shape, hidden populated padding, missing values and changed prize semantics fail', () => {
  for (const patch of [{OregonShareCounts: []}, {ShareAmounts: []}, {Multiplier: 0},
    {ShareAmounts: [...Array(15).fill(100), null]}]) {
    assert.throws(() => parseOregonTiers('pb', {...tierRow('pb'), ...patch}));
  }
  const padding = tierRow('pb'); padding.OregonShareCounts[15] = 1;
  assert.throws(() => parseOregonTiers('pb', padding));
  const money = tierRow('mb'); money.ShareAmounts[0] = '3008.80';
  assert.throws(() => parseOregonTiers('mb', money));
  assert.throws(() => parseOregonTiers('wf', {...tierRow('wf'), JackpotShareAmount: 1000000}));
  assert.throws(() => parseOregonTiers('p4', {...tierRow('p4'), DrawDateTime: '2026-10-04T23:00:00'}));
  assert.throws(() => parseOregonTiers('mm', tierRow('pb')));
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

import {mkdtemp, readFile, writeFile, rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {refreshOregonReports, oregonReportGames} from '../../tooling/import_oregon_draw_reports.mjs';
function history(game) {
  const times = game === 'cp' ? Array.from({length: 16}, (_, i) => i + 7) : game === 'p4' ? [13, 16, 19, 22] : [19];
  return [3, 4].flatMap(day => times.map((hour, i) => ({...(['mm', 'cp'].includes(game) ? row : tierRow(game)),
    DrawNumber: day * 100 + i, DrawDateTime: `2026-10-0${day}T${String(hour).padStart(2, '0')}:00:00`,
    RoundedDrawDateTime: `2026-10-0${day}T${String(hour).padStart(2, '0')}:00:00`})));
}
test('atomic six-source refresh preserves every session and baseline bytes on each failure', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'oregon-reports-')); const file = join(dir, 'reports.json');
  try {
    const data = await refreshOregonReports(file, async game => history(game));
    assert.equal(data.reports.length, 48);
    const baseline = await readFile(file, 'utf8');
    for (const failed of oregonReportGames) {
      await assert.rejects(refreshOregonReports(file, async game => {
        if (game === failed) throw Error('Source failed');
        return history(game);
      }));
      assert.equal(await readFile(file, 'utf8'), baseline);
    }
    for (const change of ['missing-session', 'duplicate', 'date-regression', 'draw-regression', 'changed-identity']) {
      await assert.rejects(refreshOregonReports(file, async game => {
        const rows = history(game);
        if (game !== 'p4') return rows;
        if (change === 'missing-session') return rows.filter(r => !r.DrawDateTime.includes('13:00'));
        if (change === 'duplicate') rows.push({...rows[0]});
        if (change === 'date-regression') for (const r of rows) {r.DrawDateTime = r.DrawDateTime.replace('10-04', '10-02');}
        if (change === 'draw-regression') for (const r of rows) r.DrawNumber -= 100;
        if (change === 'changed-identity') for (const r of rows) r.DrawNumber += 1;
        return rows;
      }));
      assert.equal(await readFile(file, 'utf8'), baseline);
    }
    await writeFile(file, '{broken');
    await assert.rejects(refreshOregonReports(file, async game => history(game)));
    assert.equal(await readFile(file, 'utf8'), '{broken');
  } finally { await rm(dir, {recursive: true, force: true}); }
});

test('zero shared-prize/zero-count source row is omitted as renderer does; inconsistent rows fail', () => {
  const mb = tierRow('mb'); mb.ShareAmounts[1] = 0; mb.OregonShareCounts[1] = 0;
  const r = parseOregonTiers('mb', mb);
  assert.equal(r.tiers.length, 6);
  assert.deepEqual(r.tiers.map(t => t.sourceRows[0]), [1, 2, 4, 5, 6, 7]);
  mb.OregonShareCounts[1] = 1;
  assert.throws(() => parseOregonTiers('mb', mb));
});
