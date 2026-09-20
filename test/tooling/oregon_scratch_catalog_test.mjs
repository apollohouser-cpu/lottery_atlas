import test from 'node:test';
import assert from 'node:assert/strict';
import {parseOregonCatalog} from '../../tooling/import_oregon_scratch_catalog.mjs';
const row = {GameNumber: '123', GameNameTitle: 'Example', TicketPrice: 5, TopPrize: 50000, TopPrizesRemaining: 2, DateAvailable: '2026-01-01T00:00:00', GameEndDate: null};
const parse = (rows = [row], more = {}) => parseOregonCatalog({InstantGames: rows, NextItems: 0, ...more}, '2026-09-20');
test('labels unclaimed inventory and source cadence separately from retrieval', () => {
  const c = parse(); assert.equal(c.sourceDate, null); assert.match(c.games[0].inventoryNote, /unclaimed, not store stock/); assert.match(c.updateCadence, /daily/);
});
test('excludes future and ended games using official calendar dates', () => {
  const c = parse([row, {...row, GameNumber:'124', DateAvailable:'2026-09-21T00:00:00'}, {...row, GameNumber:'125', GameEndDate:'2026-09-20T00:00:00'}]);
  assert.deepEqual(c.games.map(g=>g.id), ['123']);
});
test('rejects missing counts rather than converting them to zero', () => {
  for(const value of [null, undefined, '', -1, 1.5]) assert.throws(()=>parse([{...row, TopPrizesRemaining:value}]));
  assert.equal(parse([{...row,TopPrizesRemaining:0}]).games[0].topPrizesRemaining,0);
});
test('rejects invalid dates, duplicate identities and truncated responses', () => {
  assert.throws(()=>parse([{...row, DateAvailable:'2026-02-30T00:00:00'}]));
  assert.throws(()=>parse([row,row])); assert.throws(()=>parse([row],{NextItems:1000}));
});
test('preserves redemption deadline and rejects inverted dates', () => {
  assert.equal(parse([{...row, ValidationEndDate:'2027-09-20T00:00:00'}]).games[0].lastDayToRedeem,'2027-09-20');
  assert.throws(()=>parse([{...row, ValidationEndDate:'2025-01-01T00:00:00'}]));
});
