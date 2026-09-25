import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {validateTexasTierFeed} from '../../tooling/publish_texas_draw_tiers.mjs';
const fixture = () => JSON.parse(readFileSync(new URL('../../data/texas_draw_tiers.generated.json', import.meta.url)));
test('reviewed Texas feed validates without mutation',()=>{
 const data=fixture(), before=JSON.stringify(data);
 validateTexasTierFeed(data);assert.equal(JSON.stringify(data),before);
});
test('publication rejects missing sessions, bad origins, dates and totals',()=>{
 for (const mutate of [d=>d.reports.pop(), d=>d.reports[0]=d.reports[1], d=>d.reports[0].sourceUrl='https://example.com/report', d=>d.reports[0].drawDate='2026-02-30', d=>d.reports[0].reportedTotals[2]='9999999', d=>d.reports[0].winnerColumns=[]]) {
  const data=fixture();mutate(data);assert.throws(()=>validateTexasTierFeed(data));
 }
});
