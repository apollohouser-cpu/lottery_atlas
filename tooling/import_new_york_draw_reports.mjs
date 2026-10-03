import {readFile,writeFile,rename} from 'node:fs/promises';
import {parseNewYorkPowerball,parseNewYorkMegaMillions,parseNewYorkStateTiers,parseNewYorkSharesOrPick10,parseNewYorkQuickDraw,assertNewYorkReportContinuity} from './new_york_draw_reports.mjs';
const output=process.argv[2];
if(!output)throw Error('Usage: node tooling/import_new_york_draw_reports.mjs OUTPUT.json');
let previous=[];
try{previous=JSON.parse(await readFile(output,'utf8')).reports;if(!Array.isArray(previous))throw Error('Invalid previous NY reports');}
catch(error){if(error.code!=='ENOENT')throw error;}
const parsers={21:parseNewYorkPowerball,16:parseNewYorkMegaMillions,26:parseNewYorkStateTiers,36:parseNewYorkStateTiers,374901:parseNewYorkStateTiers,41:parseNewYorkSharesOrPick10,46:parseNewYorkSharesOrPick10,56:parseNewYorkSharesOrPick10,400:parseNewYorkQuickDraw};
const reports=[];
for(const [id,parse] of Object.entries(parsers)){
 const response=await fetch('https://nylottery.ny.gov/drupal-api/api/v2/winning_numbers?_format=json&nid='+id+'&page=0',{headers:{'user-agent':'LotteryAtlasOfficialDataBot/1.0',accept:'application/json'},signal:AbortSignal.timeout(45000)});
 if(!response.ok)throw Error('NY reports HTTP '+response.status);
 const payload=await response.json();
 if(!Array.isArray(payload.rows)||payload.rows.length<5)throw Error('Insufficient NY report history');
 const parsed=payload.rows.slice(0,5).map(parse);
 if(['36','41','46'].includes(id)&&new Set(parsed.map(r=>r.drawingSession)).size!==2)throw Error('Missing NY day/evening session');
 reports.push(...parsed);
}
assertNewYorkReportContinuity(previous,reports);
const data={schemaVersion:1,state:'New York',retrievedAt:new Date().toISOString(),sourcePublicationDate:null,
 cadence:'Recent per-draw official reports; scheduled app refresh, not a live four-minute feed.',
 additionalSources:[
 {gameName:'Cash4Life',sourceUrl:'https://nylottery.ny.gov/all-winning-numbers/?nid=31',limitations:'Historical reports; not a current recurring schedule.'},
 {gameName:'Erie Canal Million Dollar Raffle',sourceUrl:'https://nylottery.ny.gov/erie-canal-million-dollar-raffle/',limitations:'Historical October 26, 2025 event; official correction supersedes October 25 ticket misprint. No ticket-number or retailer rows imported.'}],reports};
await writeFile(output+'.tmp',JSON.stringify(data,null,2)+'\n');await rename(output+'.tmp',output);
console.log('Validated '+reports.length+' New York reports');
