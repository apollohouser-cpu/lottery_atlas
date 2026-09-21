import test from 'node:test';
import assert from 'node:assert/strict';
import {fetchColoradoReport} from '../../tooling/colorado_report_pages.mjs';
const url='https://www.coloradolottery.com/en/player-tools/whos-winning/?game=powerball&timeframe=sincestart';
const page=(values,total,next)=>`<p class="results">${total} Results</p>${values.map(v=>`<td>${v}</td>`).join('')}<script>params.set('queried_at', '2026-09-21T12:00:00+00:00')</script>${next?`<a href="?game=powerball&amp;timeframe=sincestart&amp;page=${next}" class="next">Next</a>`:''}`;
const rows=s=>[...s.matchAll(/<td>(.*?)<\/td>/g)].map(m=>m[1]);
test('follows official next page with published snapshot and all rows',async()=>{
 const calls=[];const result=await fetchColoradoReport(url,async u=>{calls.push(new URL(u));return calls.length===1?page(['a','b'],3,2):page(['c'],3);},rows);
 assert.deepEqual(rows(result),['a','b','c']);assert.equal(calls[1].searchParams.get('queried_at'),'2026-09-21T12:00:00+00:00');assert.equal(calls[0].searchParams.get('page_size'),'1000');
});
test('rejects truncated final page',async()=>{await assert.rejects(fetchColoradoReport(url,async()=>page(['a'],3),rows),/incomplete/);});
test('rejects repeated pages',async()=>{await assert.rejects(fetchColoradoReport(url,async()=>page(['a'],3,2),rows),/repeated/);});
test('rejects changed totals and snapshot',async()=>{
 for(const changed of [page(['b'],4),page(['b'],3).replace('12:00:00','13:00:00')]){let n=0;await assert.rejects(fetchColoradoReport(url,async()=>n++?changed:page(['a'],3,2),rows),/changed/);}
});
test('rejects changed report identity and bounds page count',async()=>{
 await assert.rejects(fetchColoradoReport(url,async()=>page(['a'],3,2).replace('game=powerball','game=scratch'),rows),/target/);
 await assert.rejects(fetchColoradoReport(url,async()=>page(['a'],3,2),rows,1),/limit/);
});

import {retainColoradoScratchHistory} from '../../tooling/colorado_report_pages.mjs';
test('historical Scratch records retain provenance and never override current window',()=>{
 const row={id:'co-2026-01-02-test',game:'scratch-off',state:'CO',drawDate:'2026-01-02T12:00:00.000Z',latitude:40,longitude:-105,winningTickets:1,prizeAmount:1000,sourceUrl:url,sourceLabel:'Official source'};
 const prior={sourceUrl:'https://www.coloradolottery.com/en/player-tools/whos-winning/',updatedAt:'2026-09-20T00:00:00Z',activities:[row,{...row,id:'co-2026-09-01-test',drawDate:'2026-09-01T12:00:00.000Z'},{...row,game:'state-draw'}]};
 const kept=retainColoradoScratchHistory(prior,'2026-03-26T12:00:00.000Z');assert.equal(kept.length,1);assert.equal(kept[0].historicalSourceVerifiedAt,prior.updatedAt);
 const again=retainColoradoScratchHistory({...prior,updatedAt:'2026-09-21T00:00:00Z',activities:kept},'2026-03-27T12:00:00.000Z');assert.deepEqual(again,kept);
 assert.throws(()=>retainColoradoScratchHistory({...prior,sourceUrl:'https://example.com'},'2026-03-26'),/provenance/);
});
