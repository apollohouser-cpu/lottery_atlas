import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {collectKentuckyTierFeed,validateKentuckyTierFeed} from '../../tooling/import_kentucky_draw_tiers.mjs';
const fixtures = Object.fromEntries([[26,'mega-millions'],[24,'powerball-xo']].map(([g,n])=>[g,JSON.parse(readFileSync(new URL(`./fixtures/kentucky-${n}-tiers.json`,import.meta.url)))]));
const fetchReport=async body=>{
 const detail=structuredClone(fixtures[body.gameNumber]);
 return body.infoRequest==='11' ? {GAME_NUMBER:detail.GAME_NUMBER,DRAW_HISTORY:[{DRAW_ID:detail.DRAW_ID,DRAW_DATE:detail.DRAW_DATE,SPECIAL_ARGS:detail.SPECIAL_ARGS}]} : detail;
};
test('Kentucky feed preserves unchanged dates and keeps game identities separate',async()=>{
 const first=await collectKentuckyTierFeed({fetchReport,now:'2026-09-25T15:00:00Z'});
 const second=await collectKentuckyTierFeed({fetchReport,previous:first,now:'2026-09-26T15:00:00Z'});
 assert.equal(second.updatedAt,first.updatedAt);
 assert.deepEqual(second.reports.map(r=>r.gameName),['Mega Millions','Powerball Xs & Os']);
 assert.equal(second.reports[0].reportedTotals[3],'2,465');
 assert.equal(second.reports[0].reportedTotals[4],'$49,433');
 assert.equal(second.reports[0].tiers[0][1],'Jackpot (no KY winners)');
 const changed=structuredClone(first);changed.reports[0].tiers[1][3]='99';
 assert.throws(()=>validateKentuckyTierFeed(changed));
});
test('Kentucky import rejects a detail for the wrong draw and retains input',async()=>{
 const previous=await collectKentuckyTierFeed({fetchReport});
 const snapshot=JSON.stringify(previous);
 await assert.rejects(collectKentuckyTierFeed({previous,fetchReport:async body=>{const d=await fetchReport(body);if(body.infoRequest==='17')d.DRAW_ID++;return d;}}),/disagreement/);
 assert.equal(JSON.stringify(previous),snapshot);
});
test('Kentucky import rejects regression and future history dates',async()=>{
 const previous=await collectKentuckyTierFeed({fetchReport});
 previous.reports[0].drawDate='2026-09-29';
 await assert.rejects(collectKentuckyTierFeed({previous,fetchReport}),/regressed/);
 await assert.rejects(collectKentuckyTierFeed({fetchReport,now:'2026-09-01T00:00:00Z'}),/history draw/);
});
