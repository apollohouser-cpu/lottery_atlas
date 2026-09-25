import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {latestKentuckyStateDraws,parseKentuckyStateTiers} from '../../tooling/kentucky_state_draw_tiers.mjs';
const fixture=n=>JSON.parse(readFileSync(new URL(`./fixtures/kentucky-${n}-tiers.json`,import.meta.url)));
test('six state reports reconcile; Cash Ball EZ stays separate',()=>{
 for(const [name,game,count,payout,session] of [
  ['millionaire-for-life',14,958,10569,null],['cash-ball',13,2637,9778,null],
  ['pick-3-midday',16,983,91340,'MIDDAY'],['pick-3-evening',16,434,52200,'EVENING'],
  ['pick-4-midday',17,22,6900,'MIDDAY'],['pick-4-evening',17,180,113100,'EVENING']]){
  const r=parseKentuckyStateTiers(fixture(name),game);assert.equal(r.reportedWinners,count);assert.equal(r.reportedPayout,payout);assert.equal(r.drawingSession,session);assert.equal(r.drawDate,'2026-09-24');
  if(game===13){assert.equal(r.ezTotals.reportedWinners,685);assert.equal(r.ezTotals.reportedPayout,2219);}
 }
});
test('both Pick sessions selected even when calendar date ties',()=>{
 const rows=['pick-3-evening','pick-3-midday'].map(fixture);
 const history={GAME_NUMBER:[16],DRAW_HISTORY:rows};
 assert.deepEqual(latestKentuckyStateDraws(history,16).map(r=>r.DRAW_ID),[22607,22608]);
 assert.throws(()=>latestKentuckyStateDraws({...history,DRAW_HISTORY:rows.slice(0,1)},16));
 assert.throws(()=>latestKentuckyStateDraws({...history,DRAW_HISTORY:[...rows,{...rows[0],DRAW_ID:22609}]},16));
});
test('state parser rejects missing tiers, totals, sessions and annuity winners',()=>{
 for(const mutate of [d=>d.TIER_LIST[0].pop(),d=>d.SPECIAL_ARGS.TOTAL_WINNERS++,d=>d.DRAW_TIME='NIGHT',d=>d.TIER_LIST[0][0].TIER_SPECIAL_DRAW=1]){
  const d=fixture('pick-3-midday');mutate(d);assert.throws(()=>parseKentuckyStateTiers(d,16));
 }
 const d=fixture('millionaire-for-life');d.TIER_LIST[0][0].TIER_WINNER_COUNT=1;assert.throws(()=>parseKentuckyStateTiers(d,14),/requires review/);
 const cash=fixture('cash-ball');delete cash.SPECIAL_ARGS.TOTAL_PAYOUT_EZ;assert.throws(()=>parseKentuckyStateTiers(cash,13));
});
