// Official per-draw Where Sold tables. No inferred locations or all-tier coverage.
import {readFile, writeFile} from 'node:fs/promises';
import {createHash} from 'node:crypto';
import {pathToFileURL} from 'node:url';
export const text = (s) => String(s).replace(/<[^>]*>/g, ' ').replace(/&nbsp;|&#160;/g,' ').replace(/&amp;/g,'&').replace(/&#39;|&apos;/g,"'").replace(/\s+/g,' ').trim();
const key = s => text(s).toUpperCase().replace(/[^A-Z0-9]/g,'');
export function money(s) {
 const m=text(s).match(/^\$([\d,.]+)(?:\s+(Million|Billion))?$/i);
 if(!m) throw Error(`Unrecognized prize: ${text(s)}`);
 const n=Number(m[1].replaceAll(',',''))*(m[2]?.toLowerCase()==='million'?1e6:m[2]?.toLowerCase()==='billion'?1e9:1);
 if(!Number.isSafeInteger(n)||n<=0) throw Error('Invalid prize'); return n;
}
export function parseDraw(html, expectedDate) {
 const date=text(html).match(/Winning Numbers for (\d{2})\/(\d{2})\/(\d{4}) (?:were|are)/);
 if(!date) throw Error('Missing draw date');
 const day=`${date[3]}-${date[1]}-${date[2]}`;
 if(day!==expectedDate) throw Error(`Draw date mismatch ${day}/${expectedDate}`);
 const table=[...html.matchAll(/<table\b[^>]*>([\s\S]*?)<\/table>/gi)].map(m=>m[1]).find(s=>/<caption[^>]*>[^<]*Where Sold/i.test(s));
 if(!table) {
  if(!/There were no [\s\S]{0,80}jackpot or 2nd prize winners/i.test(html)) throw Error(`Missing Where Sold or explicit no-winner statement on ${day}`);
  return [];
 }
 const rows=[];
 for(const m of table.matchAll(/<tr\b[^>]*>([\s\S]*?)<\/tr>/gi)){
  const c=[...m[1].matchAll(/<td\b[^>]*>([\s\S]*?)<\/td>/gi)].map(x=>text(x[1]));
  if(!c.length)continue;
  if(c.length!==7)throw Error('Unexpected Where Sold columns');
  const [tier,name,address,city,zip,,prize]=c;
  if(!tier||!name||!address||!city||!/^\d{5}$/.test(zip))throw Error('Incomplete selling retailer');
  rows.push({tier,name,address,city,zip,prizeAmount:money(prize),date:day});
 }
 if(!rows.length)throw Error('Empty Where Sold table');return rows;
}
export function joinRows(rows, retailers, game, sourceUrl) {
 const activities=[],excluded=[];
 rows.forEach((r,index)=>{
  if(/w\//i.test(r.tier)){excluded.push({...r,game,sourceUrl,reason:'Advertised jackpot may be shared; per-ticket prize not established by this table'});return;}
  const candidates=retailers.filter(x=>key(x.address)===key(r.address)&&key(x.city)===key(r.city)&&x.postalCode===r.zip);
  if(candidates.length!==1){excluded.push({...r,game,sourceUrl,reason:`${candidates.length} exact geocoded address matches`});return;}
  const p=candidates[0];
  const id=createHash('sha256').update(JSON.stringify([game,r,index])).digest('hex').slice(0,24);
  activities.push({id:`tx-draw-${id}`,latitude:p.latitude,longitude:p.longitude,city:r.city,county:p.county.replace(/ County$/i,''),state:'TX',game,gameName:game==='powerball'?'Powerball':'Mega Millions',retailerName:r.name,retailerAddress:`${r.address}, ${r.city}, TX ${r.zip}`,coordinateSource:p.coordinateSource,drawDate:`${r.date}T12:00:00.000Z`,winningTickets:1,prizeAmount:r.prizeAmount,sourceUrl,sourceLabel:`Official Texas Lottery Where Sold · ${r.tier} · draw ${r.date}`});
 });return {activities,excluded};
}
async function get(url){
 let last;
 for(let attempt=0;attempt<3;attempt++)try{
  const r=await fetch(url,{headers:{'user-agent':'LotteryAtlasOfficialDataBot/1.0'},signal:AbortSignal.timeout(45000)});
  if(!r.ok)throw Error(`HTTP ${r.status}: ${url}`); return await r.text();
 }catch(e){last=e;}
 throw last;
}
export async function run(directoryPath, outputPath, year=2026){
 const root=JSON.parse(await readFile(directoryPath,'utf8'));
 const retailers=root.directories.find(x=>x.state==='Texas')?.retailers;
 if(!retailers||retailers.length<10000)throw Error('Missing verified Texas directory');
 const activities=[],excluded=[],reports=[];
 for(const [game,folder] of [['powerball','Powerball'],['mega-millions','Mega_Millions']]){
  const base=`https://www.texaslottery.com/export/sites/lottery/Games/${folder}/Winning_Numbers/`;
  const index=await get(base+'index.html');
  const option=[...index.matchAll(/<option\s+value="([^"]+)"[^>]*>\s*(\d{4})\s*<\/option>/gi)].find(m=>Number(m[2])===year);
  if(!option)throw Error(`Missing ${year} archive for ${game}`);
  const archiveUrl=new URL(option[1],base).href, archive=await get(archiveUrl);
  const links=new Map();
  for(const m of archive.matchAll(/<a\b[^>]*href="([^"]*details\.html[^"]*)"[^>]*>\s*(\d{2})\/(\d{2})\/(\d{4})\s*<\/a>/gi)){
   if(Number(m[4])===year)links.set(new URL(m[1],base).href,`${m[4]}-${m[2]}-${m[3]}`);
  }
  if(links.size<20)throw Error(`Incomplete ${game} archive: ${links.size}`);
  const jobs=[...links];let next=0;const results=[];
  await Promise.all(Array.from({length:4},async()=>{while(next<jobs.length){const [url,day]=jobs[next++];const rows=parseDraw(await get(url),day);results.push({url,day,...joinRows(rows,retailers,game,url),sourceRows:rows.length});}}));
  results.sort((a,b)=>a.day.localeCompare(b.day));
  for(const r of results){activities.push(...r.activities);excluded.push(...r.excluded);reports.push({game,date:r.day,sourceUrl:r.url,sourceRows:r.sourceRows,mappedRows:r.activities.length});}
  console.log(`${game}: inspected ${links.size} draws`);
 }
 activities.sort((a,b)=>a.drawDate.localeCompare(b.drawDate)||a.id.localeCompare(b.id));
 if(!['powerball','mega-millions'].every(g=>activities.some(a=>a.game===g)))throw Error('No exact mapped winners for one game');
 let old;try{old=JSON.parse(await readFile(outputPath,'utf8'));}catch{}
 const changed=JSON.stringify(old?.activities)!==JSON.stringify(activities)||JSON.stringify(old?.reports)!==JSON.stringify(reports)||JSON.stringify(old?.excluded)!==JSON.stringify(excluded);
 const result={source:'Texas Lottery official Powerball and Mega Millions draw-specific Where Sold tables',updatedAt:changed?new Date().toISOString():old.updatedAt,sourceLastUpdated:reports.map(r=>r.date).sort().at(-1)+'T12:00:00.000Z',coverage:`${year} draw pages inspected through the latest source date. Only published Where Sold rows with one exact verified address join are mapped. Other prize tiers and unmatched locations are not mapped; no complete statewide retailer winner count is implied. Dates are draw dates, not claim dates. Prizes are source-listed amounts, not verified cash payouts.`,activities,excluded,reports};
 await writeFile(outputPath,JSON.stringify(result,null,2)+'\n');console.log(`Mapped ${activities.length}; excluded ${excluded.length}.`);
}
if(process.argv[1] && import.meta.url===pathToFileURL(process.argv[1]).href){run(...process.argv.slice(2)).catch(e=>{console.error(e);process.exitCode=1;});}
