import test from 'node:test';
import assert from 'node:assert/strict';
import {retainTexasRetiredClaims} from '../../tooling/texas_retired_claim_history.mjs';
const url=n=>`https://www.texaslottery.com/export/sites/lottery/Games/Scratch_Offs/retailerswhosoldtopprizes.html_${n}.html`;
const urls=new Set(Array.from({length:70},(_,i)=>url(i)));
const row=(n,id)=>({id:'tx-claim-'+id.repeat(64),state:'TX',game:'scratch-off',sourceUrl:url(n),sourceLabel:'Official report as of 2026-09-23',drawDate:'2026-01-12T12:00:00.000Z',latitude:30,longitude:-97,retailerAddress:'1 Main St',coordinateSource:'verified',winningTickets:1,prizeAmount:1000});
test('keeps closed games but honors current report corrections/removals',()=>{
 const old=row(99,'a'), removed=row(1,'b'), current=row(2,'c');
 const r=retainTexasRetiredClaims({activities:[old,removed]},[current],urls);
 assert.equal(r.length,2); assert.equal(r.find(x=>x.id===old.id).drawDate,old.drawDate);
 assert.ok(r.find(x=>x.id===old.id).sourceLabel.includes('Archived game report'));
 assert.deepEqual(retainTexasRetiredClaims({activities:r},[current],urls),r);
});
test('rejects incomplete catalog and malformed archived records',()=>{
 assert.throws(()=>retainTexasRetiredClaims(null,[row(2,'c')],new Set()));
 assert.throws(()=>retainTexasRetiredClaims({activities:[{...row(99,'a'),id:'raw-ticket'}]},[row(2,'c')],urls));
});
