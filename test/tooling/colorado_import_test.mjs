import test from 'node:test';import assert from 'node:assert/strict';
import {readFile,mkdtemp,writeFile,rm} from 'node:fs/promises';import {tmpdir} from 'node:os';import {join} from 'node:path';
import {refreshColoradoReports,validateColoradoContinuity,coloradoReportGames,coloradoDrawLinks,fetchColoradoGame} from '../../tooling/import_colorado_draw_reports.mjs';
const origin='https://www.coloradolottery.com';
async function pages(){
 const map=new Map();
 for(const game of coloradoReportGames){
  const dates=game==='pick3'?['2026-10-03:MD','2026-10-03:EV']:game==='megamillions'?['2026-10-02','2026-10-01']:['2026-10-03','2026-10-02'];
  map.set(`${origin}/en/games/${game}/drawings/`,dates.map(d=>`<a href="/en/games/${game}/drawings/${d}/">report</a>`).join(''));
  for(const [i,date]of dates.entries()){
   let s=await readFile(new URL(`./fixtures/colorado/${game==='pick3'?(i?'pick3-ev':'pick3-md'):game}.html`,import.meta.url),'utf8');
   if(i&&game!=='pick3') s=game==='megamillions'?s.replace('Friday, 10/2/26','Thursday, 10/1/26'):s.replace('Saturday, 10/3/26','Friday, 10/2/26').replace('10/3/2026 EZ MATCH','10/2/2026 EZ MATCH');
   map.set(`${origin}/en/games/${game}/drawings/${date}/`,s);
  }
 }
 return map;
}
test('All six families commit together; each source failure preserves prior bytes',async()=>{
 const dir=await mkdtemp(join(tmpdir(),'co-reports-'));const output=join(dir,'reports.json');
 try{const map=await pages();const request=async u=>{assert.ok(map.has(u),u);return map.get(u);};
 const data=await refreshColoradoReports(output,request);assert.equal(data.reports.length,12);
 const baseline=await readFile(output,'utf8');
 for(const game of coloradoReportGames){await assert.rejects(refreshColoradoReports(output,async u=>{if(u.includes('/'+game+'/'))throw Error('source failure');return request(u);}));assert.equal(await readFile(output,'utf8'),baseline);}
 const corrupt=new Map(map);const u=`${origin}/en/games/cash5/drawings/2026-10-03/`;corrupt.set(u,corrupt.get(u).replace('>5 of 5','>invalid'));
 await assert.rejects(refreshColoradoReports(output,async u=>corrupt.get(u)));assert.equal(await readFile(output,'utf8'),baseline);
 const future=structuredClone(data);future.reports[0].drawDate='2026-10-10';await writeFile(output,JSON.stringify(future));
 await assert.rejects(refreshColoradoReports(output,request),/regression/);assert.equal(await readFile(output,'utf8'),JSON.stringify(future));
 }finally{await rm(dir,{recursive:true,force:true});}
});
test('Continuity rejects missing families, sessions and duplicate identities',async()=>{
 const map=await pages();const dir=await mkdtemp(join(tmpdir(),'co-continuity-'));
 try{const {reports}=await refreshColoradoReports(join(dir,'r.json'),async u=>map.get(u));
 assert.throws(()=>validateColoradoContinuity([],reports.slice(1)));
 const duplicate=structuredClone(reports);duplicate[1]=duplicate[0];assert.throws(()=>validateColoradoContinuity([],duplicate),/Duplicate/);
 const sessions=structuredClone(reports);sessions.at(-1).drawingSession='Midday';assert.throws(()=>validateColoradoContinuity([],sessions),/session/);
 assert.deepEqual(coloradoDrawLinks('cash5','<a href="https://evil.test/en/games/cash5/drawings/2026-10-03/">bad</a>'),[]);
 }finally{await rm(dir,{recursive:true,force:true});}
});

test('Cash 5 skips only unpublished add-on dates, bounded and without date regression',async()=>{
 const map=await pages();const index=`${origin}/en/games/cash5/drawings/`;
 const latest=index+'2026-10-04/';const old=map.get(index+'2026-10-03/');
 const absent=old.replace('Saturday, 10/3/26','Sunday, 10/4/26').split('\n').filter(l=>!/EZ Match|EZ MATCH|players won/.test(l)).join('\n');
 map.set(index,`<a href="/en/games/cash5/drawings/2026-10-04/">new</a>`+map.get(index));map.set(latest,absent);
 const rows=await fetchColoradoGame('cash5',async u=>map.get(u));
 assert.deepEqual(rows.map(r=>r.drawDate),['2026-10-03','2026-10-02']);
 assert.equal(rows[0].ezMatch.reportedPlayers,1105);
 for(const bad of [absent.replace('>5 of 5','>invalid'),absent+'EZ MATCH broken',absent.replace('Sunday, 10/4/26','Monday, 10/5/26')]){
  map.set(latest,bad);await assert.rejects(fetchColoradoGame('cash5',async u=>map.get(u)));
 }
 map.set(latest,absent);
 const dir=await mkdtemp(join(tmpdir(),'co-complete-'));const output=join(dir,'r.json');
 try {
  const data=await refreshColoradoReports(output,async u=>map.get(u));
  data.reports.find(r=>r.game==='Cash 5').drawDate='2026-10-04';
  const baseline=JSON.stringify(data);await writeFile(output,baseline);
  await assert.rejects(refreshColoradoReports(output,async u=>map.get(u)),/regression/);
  assert.equal(await readFile(output,'utf8'),baseline);
 }finally{await rm(dir,{recursive:true,force:true});}
 let calls=0;
 const history=Array.from({length:10},(_,i)=>`<a href="/en/games/cash5/drawings/2026-10-${String(14-i).padStart(2,'0')}/">d</a>`).join('');
 await assert.rejects(fetchColoradoGame('cash5',async u=>{
  if(u===index)return history;
  calls++;const day=Number(u.match(/10-(\d+)\//)[1]);const date=new Date(`2026-10-${String(day).padStart(2,'0')}`);
  return absent.replace('Sunday, 10/4/26',`${date.toLocaleDateString('en-US',{weekday:'long',timeZone:'UTC'})}, 10/${day}/26`);
 }),/search limit/);
 assert.equal(calls,8);
});
