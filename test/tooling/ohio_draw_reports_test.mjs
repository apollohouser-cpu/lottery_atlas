import test from 'node:test';
import assert from 'node:assert/strict';
import {parseOhioPayout} from '../../tooling/ohio_draw_reports.mjs';
const row = {approved: true, drawGameId: 13, drawDate: '2026-10-03T00:00:00', modifier: 2, externalDrawId: 100, prizePayout: 123.50, winnersCount: 0, prizes: [{winnersNumber: 99}]};
test('payout dollars never become ticket counts and unknown tier units are omitted', () => {
  const report = parseOhioPayout('Pick3', row);
  assert.equal(report.publishedPayoutDollars, 123.50);
  assert.equal(report.winningTickets, null);
  assert.equal(report.drawingSession, 'Evening');
  assert.equal(report.drawDate, '2026-10-03');
  assert.equal('prizes' in report, false);
  assert.equal('winnersCount' in report, false);
  assert.equal(parseOhioPayout('Pick3', {...row, modifier: 1}).drawingSession, 'Midday');
});
test('zero payout is preserved but absent, negative and unapproved values fail', () => {
  assert.equal(parseOhioPayout('Pick3', {...row, prizePayout: 0}).publishedPayoutDollars, 0);
  for (const value of [undefined, null, -1, NaN, Infinity, '123']) {
    assert.throws(() => parseOhioPayout('Pick3', {...row, prizePayout: value}));
  }
  assert.throws(() => parseOhioPayout('Pick3', {...row, approved: false}));
});
test('invalid calendar dates, identities, sessions and unsupported games fail', () => {
  for (const patch of [{drawDate: '2026-02-30T00:00:00'}, {modifier: 0}, {drawGameId: 14}, {externalDrawId: 0}]) {
    assert.throws(() => parseOhioPayout('Pick3', {...row, ...patch}));
  }
  assert.throws(() => parseOhioPayout('MegaMillions', row));
  const classic = parseOhioPayout('ClassicLotto', {...row, drawGameId: 26, modifier: 0});
  assert.equal(classic.drawingSession, null);
});

import {mkdtemp, readFile, writeFile, rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {refreshOhioReports, validateOhioContinuity} from '../../tooling/import_ohio_draw_reports.mjs';
const gameIds = {Pick3: 13, Pick4: 14, Pick5: 25, ClassicLotto: 26, RollingCashFive: 24};
function payload(game) {
  return {data: [1, 2].map((n) => ({...row, drawGameId: gameIds[game],
    externalDrawId: n, modifier: game.startsWith('Pick') ? n : 0,
    drawDate: game.startsWith('Pick') ? row.drawDate : `2026-10-0${n}T00:00:00`}))};
}
test('refresh keeps prior bytes on each source failure, missing session and regression', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'ohio-payout-'));
  const path = join(dir, 'reports.json');
  try {
    const data = await refreshOhioReports(path, async game => payload(game));
    assert.equal(data.reports.length, 10);
    const before = await readFile(path, 'utf8');
    for (const failed of Object.keys(gameIds)) {
      await assert.rejects(refreshOhioReports(path, async game => {
        if (game === failed) throw Error('source failed');
        return payload(game);
      }));
      assert.equal(await readFile(path, 'utf8'), before);
    }
    await assert.rejects(refreshOhioReports(path, async game => {
      const p = payload(game);
      if (game === 'Pick3') p.data[1].modifier = 1;
      return p;
    }));
    assert.equal(await readFile(path, 'utf8'), before);
    const future = structuredClone(data);
    future.reports[0].drawDate = '2026-10-04';
    await writeFile(path, JSON.stringify(future));
    await assert.rejects(refreshOhioReports(path, async game => payload(game)), /regression/);
    assert.equal(await readFile(path, 'utf8'), JSON.stringify(future));
  } finally {await rm(dir, {recursive: true, force: true});}
});
test('continuity rejects duplicate dates/identities and missing prior game sessions', () => {
  const r = parseOhioPayout('Pick3', row);
  assert.throws(() => validateOhioContinuity([], [r, {...r, id: 'different'}]), /Duplicate/);
  assert.throws(() => validateOhioContinuity([r], []), /regression/);
  assert.throws(() => validateOhioContinuity([r], [{...r, drawNumber: '99'}]), /regression/);
});
