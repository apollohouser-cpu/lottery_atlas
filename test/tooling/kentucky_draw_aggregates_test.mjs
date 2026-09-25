import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {latestKentuckyAggregateDraw,parseKentuckyAggregate} from '../../tooling/kentucky_draw_aggregates.mjs';
const read=n=>JSON.parse(readFileSync(new URL(`./fixtures/kentucky-${n}-aggregate.json`,import.meta.url)));
test('Keno and Cash Pop preserve unlocated aggregate-only scope',()=>{
 for(const [name,game] of [['keno',22],['cash-pop',19]]){
  const source=read(name),r=parseKentuckyAggregate(source,game);
  assert.equal(r.drawId,source.DRAW_ID);assert.equal(r.reportedWinners,source.SPECIAL_ARGS.TOTAL_WINNERS);
  assert.equal(r.reportedPayout,Number(source.SPECIAL_ARGS.TOTAL_PRIZE.replace(/[$,\s]/g,'')));
  assert.equal(r.drawTime,null);assert.equal(r.tiers,null);
 }
});
test('multiple draws on one date select highest verified draw ID, not first date tie',()=>{
 const latest=read('keno');const earlier={...latest,DRAW_ID:latest.DRAW_ID-1};
 assert.equal(latestKentuckyAggregateDraw({GAME_NUMBER:[22],DRAW_HISTORY:[earlier,latest]},22).DRAW_ID,latest.DRAW_ID);
 assert.equal(latestKentuckyAggregateDraw({GAME_NUMBER:[22],DRAW_HISTORY:[latest,earlier]},22).DRAW_ID,latest.DRAW_ID);
 for(const rows of [[latest,latest],[latest,{...earlier,DRAW_DATE:latest.DRAW_DATE+86400000}]])assert.throws(()=>latestKentuckyAggregateDraw({GAME_NUMBER:[22],DRAW_HISTORY:rows},22));
});
test('aggregates reject unreviewed tiers and invalid amounts',()=>{
 for(const mutate of [d=>d.TIER_LIST=[[{}]],d=>d.SPECIAL_ARGS.TOTAL_WINNERS=-1,d=>d.SPECIAL_ARGS.TOTAL_PRIZE='$NaN',d=>d.GAME_NAME=['POWERBALL']]){
  const d=read('keno');mutate(d);assert.throws(()=>parseKentuckyAggregate(d,22));
 }
});
