import test from 'node:test';
import assert from 'node:assert/strict';
import {newYorkReleaseDate as parse} from '../../tooling/new_york_release_date.mjs';
test('release without explicit drawing uses publication provenance', () => {
 assert.deepEqual(parse({date:'2026-10-02'}, 'claimed a prize'), {date:'2026-10-02T12:00:00.000Z',kind:'publication'});
});
test('explicit draw and year rollover retain draw provenance', () => {
 assert.deepEqual(parse({date:'2026-01-02'},'for the December 31 drawing'),{date:'2025-12-31T12:00:00.000Z',kind:'draw'});
 assert.equal(parse({date:'2026-10-02'},'in the September 30, 2026 drawing').date,'2026-09-30T12:00:00.000Z');
});
test('invalid calendar dates and future explicit draws are not verified draw dates', () => {
 for(const text of ['for the February 31, 2026 drawing','for the October 4, 2026 drawing','for the Smarch 1 drawing']) assert.equal(parse({date:'2026-10-02'},text).kind,'publication');
 assert.equal(parse({date:'2026-02-31'},''),null);
});
