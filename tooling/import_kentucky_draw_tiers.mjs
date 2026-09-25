import {readFile, writeFile, rename} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';
import {collectKentuckyAggregates,parseKentuckyAggregate} from './kentucky_draw_aggregates.mjs';
import {parseKentuckyTiers} from './kentucky_draw_tiers.mjs';
import {parseKentuckyPowerball} from './kentucky_powerball_tiers.mjs';
import {latestKentuckyStateDraws,parseKentuckyStateTiers} from './kentucky_state_draw_tiers.mjs';

export const sourceUrl = 'https://www.kylottery.com/apps/draw_games/pastwinning.html';
export const endpoint = 'https://www.kylottery.com/webhandlers/WinningNumbers.xhtml';
export const legacyCoverage = 'Latest returned Kentucky draw for Mega Millions and Powerball Xs & Os only. Xs & Os is separate from ordinary Powerball. Other game layouts remain under review. These statewide tier totals are not retailer locations, validated claims, or a complete historical archive. Source publication dates unavailable. Refresh attempted every six hours; agency publication cadence unconfirmed.';
export const fourReportCoverage = legacyCoverage.replace('Mega Millions and Powerball Xs & Os only.', 'Mega Millions, Powerball Xs & Os, Powerball and Double Play. Power Play winners are a subset of Powerball winners.');
export const coverage = 'Latest returned Kentucky draw per reviewed game/session. Power Play is a subset; Double Play and Cash Ball EZ stay separate. Includes both Pick 3 and Pick 4 sessions. Keno, Cash Pop and instant-game layouts are not included. No retailer locations or complete historical claims archive. Source publication dates unavailable. Refresh attempted every six hours; agency publication cadence unconfirmed.';
const names = {26:'Mega Millions',24:'Powerball Xs & Os'};
const dollars = n => '$' + n.toLocaleString('en-US');
export function makeReport(raw, game) {
  const parsed = parseKentuckyTiers(raw, game);
  return {...parsed, gameName:names[game], drawingSession:null, sourceUrl,
    headers:['Match','Base prize','Multiplier','Kentucky winners','Tier payout'],
    tiers:parsed.tiers.map(r=>[
      r.TIER_DESCRIPTION,
      r.TIER_ID === 1 ? 'Jackpot (no KY winners)' : dollars(r.TIER_JACKPOT),
      r.TIER_ID === 1 || game !== 26 ? '—' : `${r.TIER_MULTIPLIER}X`,
      r.TIER_WINNER_COUNT.toLocaleString('en-US'),
      dollars(r.TIER_WINNER_COUNT*r.TIER_JACKPOT*(game === 26 ? r.TIER_MULTIPLIER || 1 : 1)),
    ]),
    reportedTotals:['Total','','',parsed.reportedWinners.toLocaleString('en-US'),dollars(parsed.reportedPayout)],
  };
}
export function makePowerballReports(raw) {
  const parsed=parseKentuckyPowerball(raw);
  return parsed.reports.map((report,i)=>{
    const prefix=i?'DOUBLE_PLAY_':'';
    return {...report,gameNumber:12,drawId:i?raw.DOUBLE_PLAY_DRAW_ID:raw.DRAW_ID,
      drawDate:parsed.drawDate,sourcePublicationDate:null,drawingSession:null,sourceUrl,
      headers:['Match','Base prize','Kentucky winners','Power Play subset','Tier payout'],
      tiers:report.tiers.map(r=>{
        const id=r[prefix+'TIER_ID'],base=r[prefix+'TIER_JACKPOT'],n=r[prefix+'TIER_WINNER_COUNT'],pp=r[prefix+'TIER_SPECIAL_DRAW'];
        return [r[prefix+'TIER_DESCRIPTION'],id===1?'Top prize (no KY winners)':dollars(base),n.toLocaleString('en-US'),i?'—':pp.toLocaleString('en-US'),dollars(base*n+(i?0:base*pp*((id===2?2:parsed.powerPlayMultiplier)-1)))];
      }),
      reportedTotals:['Total','',report.reportedWinners.toLocaleString('en-US'),i?'—':report.powerPlayWinners.toLocaleString('en-US'),dollars(report.reportedPayout)],
      tableNote:i?'Double Play is a separate drawing; its winners are not added to Powerball totals.':`Power Play winners are included in Kentucky winners. Power Play is ${parsed.powerPlayMultiplier}X for this draw; match-five is 2X. Payout includes that subset uplift.`,
    };
  });
}
export function makeStateReport(raw,game) {
  const parsed=parseKentuckyStateTiers(raw,game);
  return {...parsed,sourceUrl,headers:['Match','Source tier amount','Kentucky winners','Tier payout'],
    tiers:parsed.tiers.map(r=>[r.TIER_DESCRIPTION,game===14 && r.TIER_ID<=2?'Top prize basis unverified':dollars(r.TIER_JACKPOT),r.TIER_WINNER_COUNT.toLocaleString('en-US'),dollars(r.TIER_WINNER_COUNT*r.TIER_JACKPOT)]),
    reportedTotals:['Total','',parsed.reportedWinners.toLocaleString('en-US'),dollars(parsed.reportedPayout)],
    tableNote:parsed.prizeBasis+(parsed.ezTotals?` Separate EZ: ${parsed.ezTotals.reportedWinners.toLocaleString('en-US')} reported winners / ${dollars(parsed.ezTotals.reportedPayout)} payout; no EZ tier breakdown. Excluded from base totals.`:''),
  };
}
export function validateKentuckyTierFeed(data) {
  if (![coverage,fourReportCoverage,legacyCoverage].includes(data?.coverage) || !Number.isFinite(Date.parse(data.updatedAt)) || data.sourceUrl !== sourceUrl || data.endpoint !== endpoint) throw Error('Missing feed provenance');
  const stateGames=data.coverage===coverage;
  const expanded=data.coverage!==legacyCoverage;
  if (!Array.isArray(data.reports) || data.reports.length !== (stateGames?10:expanded?4:2) || !Array.isArray(data.sourceReports) || data.sourceReports.length !== (stateGames?9:expanded?3:2)) throw Error('Expected reviewed Kentucky games');
  const expected = [26,24].map((game,i)=>makeReport(data.sourceReports[i],game));
  if(expanded)expected.push(...makePowerballReports(data.sourceReports[2]));
  if(stateGames){
    for(const [i,game] of [14,13,16,16,17,17].entries())expected.push(makeStateReport(data.sourceReports[i+3],game));
    if(JSON.stringify(expected.slice(6).map(r=>r.drawingSession))!==JSON.stringify(['MIDDAY','EVENING','MIDDAY','EVENING']))throw Error('Missing or reordered sessions');
  }
  if (JSON.stringify(data.reports) !== JSON.stringify(expected)) throw Error('Rendered reports differ from reconciled source');
  if(data.aggregateSnapshot){
    const snapshot=data.aggregateSnapshot;
    if(!Number.isFinite(Date.parse(snapshot.updatedAt)) || snapshot.sourceUrl!==sourceUrl || !Array.isArray(snapshot.sourceReports) || snapshot.sourceReports.length!==2)throw Error('Invalid aggregate provenance');
    const aggregates=snapshot.sourceReports.map((raw,i)=>parseKentuckyAggregate(raw,[22,19][i]));
    if(JSON.stringify(aggregates)!==JSON.stringify(snapshot.reports))throw Error('Aggregate reports differ from source');
  }
  return data;
}
async function request(body) {
  const response = await fetch(endpoint,{method:'POST',headers:{'Content-Type':'application/json'},body:JSON.stringify(body),signal:AbortSignal.timeout(45000)});
  if (!response.ok) throw Error(`Kentucky results HTTP ${response.status}`);
  return response.json();
}
export async function collectKentuckyTierFeed({fetchReport=request, previous=null, now=new Date().toISOString()}={}) {
  const sourceReports=[];
  for (const game of [26,24,12]) {
    const history=await fetchReport({gameNumber:game,infoRequest:'11'});
    if (history.GAME_NUMBER?.length !== 1 || history.GAME_NUMBER[0] !== game || !Array.isArray(history.DRAW_HISTORY) || !history.DRAW_HISTORY.length) throw Error('Invalid draw history');
    const seen = new Set();
    for (const draw of history.DRAW_HISTORY) {
      if (!Number.isSafeInteger(draw.DRAW_ID) || !Number.isSafeInteger(draw.DRAW_DATE) || draw.DRAW_DATE > Date.parse(now) || seen.has(draw.DRAW_ID)) throw Error('Invalid or duplicate history draw');
      seen.add(draw.DRAW_ID);
    }
    const sorted=[...history.DRAW_HISTORY].sort((a,b)=>b.DRAW_DATE-a.DRAW_DATE);
    if (sorted.length > 1 && sorted[0].DRAW_DATE === sorted[1].DRAW_DATE) throw Error('Ambiguous latest draw');
    const latest=sorted[0];
    const detail=await fetchReport({gameNumber:String(game),infoRequest:'17',drawNumber:latest.DRAW_ID});
    if (detail.DRAW_ID !== latest.DRAW_ID || detail.DRAW_DATE !== latest.DRAW_DATE || JSON.stringify(detail.SPECIAL_ARGS) !== JSON.stringify(latest.SPECIAL_ARGS)) throw Error('History/detail disagreement');
    const parsed=game===12?{...parseKentuckyPowerball(detail),drawId:detail.DRAW_ID}:parseKentuckyTiers(detail,game);
    const prior=previous?.reports?.find(r=>r.gameNumber===game);
    if (prior && (parsed.drawDate < prior.drawDate || parsed.drawId < prior.drawId)) throw Error('Source regressed; retain previous validated feed');
    sourceReports.push(detail);
  }
  const reports=sourceReports.slice(0,2).map((raw,i)=>makeReport(raw,[26,24][i]));
  reports.push(...makePowerballReports(sourceReports[2]));
  for(const game of [14,13,16,17]){
    const history=await fetchReport({gameNumber:game,infoRequest:'11'});
    for(const latest of latestKentuckyStateDraws(history,game,Date.parse(now))){
      const detail=await fetchReport({gameNumber:String(game),infoRequest:'17',drawNumber:latest.DRAW_ID});
      if(detail.DRAW_ID!==latest.DRAW_ID || detail.DRAW_DATE!==latest.DRAW_DATE || detail.DRAW_TIME!==latest.DRAW_TIME || JSON.stringify(detail.SPECIAL_ARGS)!==JSON.stringify(latest.SPECIAL_ARGS))throw Error('History/detail disagreement');
      const report=makeStateReport(detail,game);
      const prior=previous?.reports?.find(r=>r.gameNumber===game && r.drawingSession===report.drawingSession);
      if(prior && (report.drawDate<prior.drawDate || report.drawId<prior.drawId))throw Error('Source regressed; retain previous validated feed');
      sourceReports.push(detail);reports.push(report);
    }
  }
  const aggregateSnapshot=await collectKentuckyAggregates({fetchReport,previous:previous?.aggregateSnapshot,now});
  const updatedAt=previous && JSON.stringify(previous.reports)===JSON.stringify(reports) ? previous.updatedAt : now;
  return validateKentuckyTierFeed({updatedAt,sourceUrl,endpoint,coverage,reports,sourceReports,aggregateSnapshot});
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const output=process.argv[2];
  if (!output) throw Error('Output required');
  let previous;
  try { previous=validateKentuckyTierFeed(JSON.parse(await readFile(output,'utf8'))); }
  catch (error) { if (error.code !== 'ENOENT') throw error; }
  const data=await collectKentuckyTierFeed({previous});
  // All games must reconcile before replacing this state's previous output.
  await writeFile(output+'.tmp',JSON.stringify(data,null,2)+'\n');
  await rename(output+'.tmp',output);
  console.log('Validated ten Kentucky statewide tables.');
}
