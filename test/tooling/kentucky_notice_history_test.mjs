import test from 'node:test';
import assert from 'node:assert/strict';
import {retainKentuckyNotices} from '../../tooling/kentucky_notice_history.mjs';
const row = (day, id = day) => ({id:`ky-current-${id}`,state:'KY',drawDate:`2026-${day}T12:00:00.000Z`,latitude:37,longitude:-85,retailerName:'Store',retailerAddress:'1 Main St',coordinateSource:'verified',sourceUrl:'https://www.kylottery.com/apps/winners/index.html',winningTickets:1,prizeAmount:10000});
const start='2026-10-20T12:00:00.000Z',end='2026-11-09T12:00:00.000Z';
test('retains older notices and IDs while replacing/removing overlap',()=>{
 const old=row('08-31'), overlap=row('10-21'), removed=row('10-22');
 const previous={sourceLastUpdated:start,activities:[old,overlap,removed]};
 const current=[{...overlap,prizeAmount:20000},row('11-09')];
 const result=retainKentuckyNotices(previous,current,start,end);
 assert.equal(result.length,3); assert.deepEqual(result.find(r=>r.id===old.id),old);
 assert.equal(result.find(r=>r.id===overlap.id).prizeAmount,20000);
 assert.deepEqual(retainKentuckyNotices({activities:result,sourceLastUpdated:end},current,start,end),result);
});
test('fails closed on empty, regressed, invalid or duplicate refresh',()=>{
 assert.throws(()=>retainKentuckyNotices(null,[],start,end));
 assert.throws(()=>retainKentuckyNotices({sourceLastUpdated:'2026-11-10T12:00:00.000Z'},[row('11-09')],start,end));
 assert.throws(()=>retainKentuckyNotices(null,[{...row('11-09'),latitude:null}],start,end));
 assert.throws(()=>retainKentuckyNotices(null,[row('11-09'),row('11-09')],start,end));
});
