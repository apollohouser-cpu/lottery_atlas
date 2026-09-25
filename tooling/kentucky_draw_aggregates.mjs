// Keno/Cash Pop expose draw totals but no prize-tier breakdown in reviewed responses.
const games={22:['KENO','Keno'],19:['CASHPOP','Cash Pop']};
const integer=n=>Number.isSafeInteger(n)&&n>=0;
export function latestKentuckyAggregateDraw(history,game,now=Date.now()) {
  if(!games[game] || JSON.stringify(history.GAME_NUMBER)!==JSON.stringify([game]) || !Array.isArray(history.DRAW_HISTORY) || !history.DRAW_HISTORY.length)throw Error('Invalid history');
  const rows=[...history.DRAW_HISTORY].sort((a,b)=>a.DRAW_ID-b.DRAW_ID);
  let prior;
  for(const r of rows){
    if(!integer(r.DRAW_ID)||!integer(r.DRAW_DATE)||r.DRAW_DATE>now || (prior && (r.DRAW_ID===prior.DRAW_ID || r.DRAW_DATE<prior.DRAW_DATE)))throw Error('Ambiguous draw ordering');
    prior=r;
  }
  // Official results code indexes rows by draw ID and reverses that order.
  return {...rows.at(-1)};
}
export function parseKentuckyAggregate(data,game) {
  if(!games[game] || JSON.stringify(data.GAME_NUMBER)!==JSON.stringify([game]) || JSON.stringify(data.GAME_NAME)!==JSON.stringify([games[game][0]]) || !integer(data.DRAW_ID)||!integer(data.DRAW_DATE))throw Error('Invalid game identity');
  if(JSON.stringify(data.TIER_LIST)!=='[[]]')throw Error('Unexpected tier layout requires review');
  const winners=data.SPECIAL_ARGS?.TOTAL_WINNERS, raw=data.SPECIAL_ARGS?.TOTAL_PRIZE;
  if(!integer(winners)||typeof raw!=='string'||!/^\$\s*\d[\d,]*\.\d{2}$/.test(raw))throw Error('Invalid aggregate totals');
  const payout=Number(raw.replace(/[$,\s]/g,''));
  if(!Number.isFinite(payout)||payout<0||!Number.isSafeInteger(Math.round(payout*100)))throw Error('Unsafe payout');
  return {gameNumber:game,gameName:games[game][1],drawId:data.DRAW_ID,
    drawDate:new Intl.DateTimeFormat('en-CA',{timeZone:'America/New_York',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date(data.DRAW_DATE)),
    drawTime:null,sourcePublicationDate:null,reportedWinners:winners,reportedPayout:payout,
    tiers:null,coverage:'Source-reported totals for this draw only. Prize tiers, exact draw time and retailer locations are unavailable in this response. These totals cannot be independently reconciled against tiers. Not a daily total, complete history or live feed.'};
}

// Preparation collector: aggregate snapshots stay separate from reconciled tier reports.
export async function collectKentuckyAggregates({fetchReport, previous=null, now=new Date().toISOString()}) {
  if(typeof fetchReport!=='function'||!Number.isFinite(Date.parse(now)))throw Error('Invalid collection options');
  const reports=[], sourceReports=[];
  for(const game of [22,19]){
    const history=await fetchReport({gameNumber:game,infoRequest:'11'});
    const latest=latestKentuckyAggregateDraw(history,game,Date.parse(now));
    const detail=await fetchReport({gameNumber:String(game),infoRequest:'17',drawNumber:latest.DRAW_ID});
    if(detail.DRAW_ID!==latest.DRAW_ID || detail.DRAW_DATE!==latest.DRAW_DATE || JSON.stringify(detail.SPECIAL_ARGS)!==JSON.stringify(latest.SPECIAL_ARGS))throw Error('Aggregate history/detail disagreement');
    const report=parseKentuckyAggregate(detail,game);
    const prior=previous?.reports?.find(r=>r.gameNumber===game);
    if(prior && (report.drawDate<prior.drawDate || report.drawId<prior.drawId))throw Error('Aggregate source regressed; retain previous snapshot');
    reports.push(report);sourceReports.push(detail);
  }
  return {
    updatedAt:previous && JSON.stringify(previous.reports)===JSON.stringify(reports)?previous.updatedAt:now,
    sourceUrl:'https://www.kylottery.com/apps/draw_games/pastwinning.html',
    cadence:'Atlas refresh attempts every six hours; not a live four-minute results service. Agency publication cadence unconfirmed.',
    reports,sourceReports,
  };
}
