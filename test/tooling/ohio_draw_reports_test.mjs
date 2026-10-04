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
