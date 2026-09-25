import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {parseKentuckyPowerball} from '../../tooling/kentucky_powerball_tiers.mjs';
const fixture=()=>JSON.parse(readFileSync(new URL('./fixtures/kentucky-powerball-tiers.json',import.meta.url)));
test('Kentucky Power Play counts are subsets; Double Play remains separate',()=>{
 const d=parseKentuckyPowerball(fixture());assert.equal(d.drawDate,'2026-09-23');
 assert.equal(d.reports[0].reportedWinners,7152);assert.equal(d.reports[0].powerPlayWinners,1324);assert.equal(d.reports[0].reportedPayout,55894);
 assert.equal(d.reports[1].reportedWinners,704);assert.equal(d.reports[1].reportedPayout,7032);
});
test('Powerball rejects missing tiers, impossible subsets and altered totals',()=>{
 for(const mutate of [d=>d.TIER_LIST[0].pop(),d=>d.TIER_LIST[0][1].TIER_SPECIAL_DRAW=1,d=>d.SPECIAL_ARGS.TOTAL_WINNERS++,d=>d.DOUBLE_PLAY_DRAW_DATE++,d=>d.TIER_LIST[1][2].DOUBLE_PLAY_TIER_SPECIAL_DRAW=1]){
  const d=fixture();mutate(d);assert.throws(()=>parseKentuckyPowerball(d));
 }
});
