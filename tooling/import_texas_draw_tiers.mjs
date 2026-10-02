import {readFile,writeFile} from 'node:fs/promises';
import {parseTierReport} from './texas_draw_tier_report.mjs';
import {selectReportDay,validateReportContinuity} from './texas_draw_report_selection.mjs';
const output=process.argv[2];
if(!output)throw Error('Output path required');
async function get(url){const r=await fetch(url,{signal:AbortSignal.timeout(45000)});if(!r.ok)throw Error(`HTTP ${r.status}`);return r.text();}
const reports=[];
for(const folder of ['Powerball','Mega_Millions','Lotto_Texas','Texas_Two_Step','Cash_Five','All_or_Nothing']){
 const base=`https://www.texaslottery.com/export/sites/lottery/Games/${folder}/Winning_Numbers/`;
 const index=await get(base+'index.html');
 const links=[...index.matchAll(/<a\b[^>]*href="([^"]*details\.html[^"]*)"[^>]*>\s*(\d{2})\/(\d{2})\/(\d{4})\s*<\/a>/gi)].map(m=>({sourceUrl:new URL(m[1],base).href,drawDate:`${m[4]}-${m[2]}-${m[3]}`}));
 if(!links.length)throw Error(`No report links: ${folder}`);
 const current=selectReportDay(links,folder==='All_or_Nothing');
 for(const metadata of current){reports.push(parseTierReport(await get(metadata.sourceUrl),{...metadata,gameName:folder.replaceAll('_',' ')}));}
}
reports.sort((a,b)=>a.gameName.localeCompare(b.gameName)||a.sourceUrl.localeCompare(b.sourceUrl));
let old;try{old=JSON.parse(await readFile(output,'utf8'));}catch{}
validateReportContinuity(reports,old?.reports ?? []);
const updatedAt=JSON.stringify(old?.reports)===JSON.stringify(reports)?old.updatedAt:new Date().toISOString();
await writeFile(output,JSON.stringify({updatedAt,coverage:'Latest available draw per game; All or Nothing uses the latest complete day of four named sessions, retaining that dated day while newer sessions are incomplete. Pick 3 and Daily 4 tables are not included in this view. These statewide tables do not establish selling locations or validated claims. Source publication dates unavailable. Refresh attempted every six hours; agency publication cadence unconfirmed.',reports},null,2)+'\n');
console.log(`Validated ${reports.length} Texas statewide prize tables.`);
