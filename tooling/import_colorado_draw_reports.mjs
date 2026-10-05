import {readFile, writeFile, rename, rm} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';
import {parseColoradoDrawReport} from './colorado_draw_reports.mjs';
export const coloradoReportGames = ['powerball','megamillions','millionaireforlife','lotto','cash5','pick3'];
const origin = 'https://www.coloradolottery.com';
export function coloradoDrawLinks(game, html) {
  const pattern = new RegExp(`^/en/games/${game}/drawings/\\d{4}-\\d{2}-\\d{2}${game==='pick3'?':(MD|EV)':''}/$`);
  return [...new Set([...html.matchAll(/href="([^"]+)"/g)].map(m=>m[1]).filter(p=>pattern.test(p)))].sort().reverse();
}
export async function fetchColoradoGame(game, request) {
  let html = await request(`${origin}/en/games/${game}/drawings/`);
  let links = coloradoDrawLinks(game,html);
  // Early-month history can be empty. Follow only official previous-month links.
  for(let n=0;!links.length && n<2;n++) {
    const month = [...html.matchAll(/href="([^"]+)"/g)].map(m=>m[1]).find(p=>new RegExp(`^/en/games/${game}/drawings/\\d{4}-\\d{2}/$`).test(p));
    if(!month) break;
    html=await request(origin+month);links=coloradoDrawLinks(game,html);
  }
  const reports=[];const seen=new Set();
  while(reports.length<2) {
    const path=links.shift();if(!path || seen.has(path)) throw Error('Insufficient Colorado history: '+game);
    seen.add(path);const body=await request(origin+path);
    const report=parseColoradoDrawReport(game,body,origin+path);
    if(game!=='pick3'||!reports.some(r=>r.drawingSession===report.drawingSession)) reports.push(report);
    const older=coloradoDrawLinks(game,body).filter(p=>p<path&&!seen.has(p));
    links=[...new Set([...links,...older])].sort().reverse();
    if(seen.size>8) throw Error('Missing Colorado drawing session');
  }
  return reports;
}
export function validateColoradoContinuity(previous,reports) {
  const ids=new Set();const slots=new Set();const newest=new Map();
  const names=['Powerball','Mega Millions','Millionaire for Life','Colorado Lotto+','Cash 5','Pick 3'];
  for(const name of names) {
    const rows=reports.filter(r=>r.game===name);
    if(rows.length!==2) throw Error('Incomplete Colorado report family');
    if(name==='Pick 3' && ['Midday','Evening'].some(s=>!rows.some(r=>r.drawingSession===s))) throw Error('Missing Colorado Pick 3 session');
  }
  if(reports.length!==12) throw Error('Unexpected Colorado report count');
  for(const r of reports){
    const key=`${r.game}/${r.drawingSession??''}`;const slot=`${key}/${r.drawDate}`;
    if(ids.has(r.id)||slots.has(slot)) throw Error('Duplicate Colorado report');
    ids.add(r.id);slots.add(slot);
    if(!newest.has(key)||newest.get(key)<r.drawDate)newest.set(key,r.drawDate);
  }
  for(const r of previous) if(!newest.has(`${r.game}/${r.drawingSession??''}`)||newest.get(`${r.game}/${r.drawingSession??''}`)<r.drawDate) throw Error('Colorado game/session date regression');
}
export async function refreshColoradoReports(output,request) {
  let previous=[];
  try {const saved=JSON.parse(await readFile(output,'utf8'));if(!Array.isArray(saved.reports))throw Error('Invalid previous Colorado reports');previous=saved.reports;}catch(e){if(e.code!=='ENOENT')throw e;}
  const reports=[];
  for(const game of coloradoReportGames) reports.push(...await fetchColoradoGame(game,request));
  validateColoradoContinuity(previous,reports);
  const data={schemaVersion:1,state:'Colorado',retrievedAt:new Date().toISOString(),cadence:'Two recent published reports per family; Pick 3 keeps the newest Midday and Evening reports. Scheduled refresh, not a live feed.',coverage:'Colorado source-reported tier winners across six current draw families, separate variants and wager units. EZ Match players and dollars remain separate. No distinct-ticket aggregate or retailer allocation.',reports};
  const temporary=output+'.tmp';
  try{await writeFile(temporary,JSON.stringify(data,null,2)+'\n');await rename(temporary,output);}finally{await rm(temporary,{force:true});}
  return data;
}
if(process.argv[1]&&import.meta.url===pathToFileURL(process.argv[1]).href){
  const output=process.argv[2];
  if(!output)throw Error('Usage: node tooling/import_colorado_draw_reports.mjs OUTPUT.json');
  refreshColoradoReports(output,async url=>{const r=await fetch(url,{headers:{'user-agent':'LotteryAtlasOfficialDataBot/1.0'},signal:AbortSignal.timeout(30000)});if(!r.ok||r.url!==url)throw Error('Colorado source HTTP/redirect error '+r.status);return r.text();}).then(d=>console.log(`Validated ${d.reports.length} Colorado reports`)).catch(e=>{console.error(e.message);process.exitCode=1;});
}
