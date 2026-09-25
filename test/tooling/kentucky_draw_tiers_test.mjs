import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {parseKentuckyTiers} from '../../tooling/kentucky_draw_tiers.mjs';
const fixture = name => JSON.parse(readFileSync(new URL(`./fixtures/kentucky-${name}-tiers.json`,import.meta.url)));
test('Kentucky Mega Millions tiers reconcile separately from locations',()=>{
 const result=parseKentuckyTiers(fixture('mega-millions'),26);
 assert.equal(result.drawDate,'2026-09-22');assert.equal(result.reportedWinners,2465);assert.equal(result.reportedPayout,49433);
 assert.equal(result.sourcePublicationDate,null);assert.equal(result.tiers.find(r=>r.TIER_WINNER_COUNT===1 && r.TIER_ID===4).TIER_MULTIPLIER,3);
});
test('Xs and Os stays a distinct game with Kentucky-only tier totals',()=>{
 const result=parseKentuckyTiers(fixture('powerball-xo'),24);
 assert.equal(result.drawDate,'2026-09-20');assert.equal(result.reportedWinners,831);assert.equal(result.reportedPayout,14738);
});
test('unknown groups, mismatched totals and jackpot winners fail closed',()=>{
 for (const mutate of [d=>d.GAME_NUMBER=[24],d=>d.TIER_LIST[0].splice(1,1),d=>d.TIER_LIST.push([]),d=>d.TIER_LIST[0][1].TIER_WINNER_COUNT++,d=>d.TIER_LIST[0].push(d.TIER_LIST[0][1]),d=>d.TIER_LIST[0][0].TIER_WINNER_COUNT=1]) {
  const d=fixture('mega-millions');mutate(d);assert.throws(()=>parseKentuckyTiers(d,26));
 }
});
