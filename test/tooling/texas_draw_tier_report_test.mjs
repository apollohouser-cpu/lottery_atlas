import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {parseTierReport} from '../../tooling/texas_draw_tier_report.mjs';
const html=readFileSync(new URL('./fixtures/texas-powerball-prize-tiers.html',import.meta.url),'utf8');
const metadata={gameName:'Powerball',drawDate:'2026-08-08',sourceUrl:'https://www.texaslottery.com/export/sites/lottery/Games/Powerball/Winning_Numbers/details.html_1158378741.html'};
test('Power Play subset stays separate from statewide reported winner total',()=>{
 const r=parseTierReport(html,metadata);
 assert.equal(r.reportedTotals[2],'142,985');
 assert.equal(r.reportedTotals[5],'52,801');
 assert.deepEqual(r.winnerColumns,[2,5]);
 assert.equal(r.tiers[1][2],'1');assert.equal(r.tiers[1][5],'1');
 assert.equal(r.sourcePublicationDate,null);
 assert.equal(r.totalWinningTickets,undefined);
 assert.equal(r.activities,undefined);
});
test('wrong dates, wrong games, malformed counts and changed table shapes fail closed',()=>{
 assert.throws(()=>parseTierReport(html,{...metadata,drawDate:'2026-08-09'}));
 assert.throws(()=>parseTierReport(html,{...metadata,gameName:'Mega Millions'}));
 assert.throws(()=>parseTierReport(html.replace('142,985','142,986'),metadata));
 assert.throws(()=>parseTierReport(html.replace('52,801','unavailable'),metadata));
 assert.throws(()=>parseTierReport(html.replace('<td>1</td>','<td colspan="2">1</td>'),metadata));
});
test('Lotto Extra totals remain separate, including the Extra-only two-number tier',()=>{
 const source=readFileSync(new URL('./fixtures/texas-lotto-where-sold.html',import.meta.url),'utf8');
 const r=parseTierReport('<h1>Lotto Texas Winning Numbers Details</h1>'+source,{gameName:'Lotto Texas',drawDate:'2026-09-05',sourceUrl:'https://www.texaslottery.com/export/sites/lottery/Games/Lotto_Texas/Winning_Numbers/details.html_1158379699.html'});
 assert.equal(r.reportedTotals[2],'12,449');assert.equal(r.reportedTotals[5],'39,843');
 const extraOnly=r.tiers.find(row=>row[0]==='2 of 6');
 assert.equal(extraOnly[2],'N/A');assert.equal(extraOnly[5],'35,446');
 assert.equal(r.totalWinningTickets,undefined);
});
test('Mega Millions multiplier partitions reconcile without being added to total winners',()=>{
 const source=readFileSync(new URL('./fixtures/texas-mega-millions-prize-tiers.html',import.meta.url),'utf8');
 const meta={gameName:'Mega Millions',drawDate:'2026-01-16',sourceUrl:'https://www.texaslottery.com/report'};
 const r=parseTierReport(source,meta);
 assert.deepEqual(r.winnerColumns,[2,4,6,8,10,12]);
 assert.equal(r.reportedTotals[2],'20,913');assert.equal(r.reportedTotals[4],'9,682');
 assert.equal(r.tiers[1][1],'$1 Million');assert.equal(r.tiers[1][3],'$2 Million');
 assert.throws(()=>parseTierReport(source.replace('<td>415</td>','<td>416</td>').replace('9,682','9,683'),meta),/Multiplier counts/);
});
