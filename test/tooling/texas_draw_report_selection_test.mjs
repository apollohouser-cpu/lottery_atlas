import test from 'node:test';
import assert from 'node:assert/strict';
import {selectReportDay,validateReportContinuity} from '../../tooling/texas_draw_report_selection.mjs';
const links=(date,n)=>Array.from({length:n},(_,i)=>({drawDate:date,sourceUrl:`https://example.com/${date}/${i}`}));
const reports=date=>['Morning','Day','Evening','Night'].map(drawingSession=>({gameName:'All or Nothing',drawingSession,drawDate:date}));
test('partial latest day retains complete day; complete new day advances',()=>{
 assert.deepEqual(selectReportDay([...links('2026-10-02',2),...links('2026-10-01',4)],true),links('2026-10-01',4));
 assert.deepEqual(selectReportDay([...links('2026-10-02',4),...links('2026-10-01',4)],true),links('2026-10-02',4));
});
test('duplicate links are harmless but conflicting dates and extra sessions fail',()=>{
 const l=links('2026-10-01',4);
 assert.equal(selectReportDay([...l,l[0]],true).length,4);
 assert.throws(()=>selectReportDay([...l,{...l[0],drawDate:'2026-10-02'}],true));
 assert.throws(()=>selectReportDay(links('2026-10-02',5),true));
 assert.throws(()=>selectReportDay(links('2026-10-02',2),true));
 assert.throws(()=>selectReportDay(links('2026-10-02',2)));
});
test('require distinct named sessions, common date, non-regression and retained groups',()=>{
 validateReportContinuity(reports('2026-10-02'),reports('2026-10-01'));
 const old=reports('2026-10-01');
 for(const rows of [old.slice(0,3),[...old.slice(0,3),old[0]],old.map((r,i)=>i? r:{...r,drawingSession:null}),old.map((r,i)=>i?r:{...r,drawDate:'2026-10-02'})]) assert.throws(()=>validateReportContinuity(rows,old));
 assert.throws(()=>validateReportContinuity(old,reports('2026-10-02')));
 assert.throws(()=>validateReportContinuity(old,[...old,{gameName:'Powerball',drawingSession:null,drawDate:'2026-09-30'}]));
});
