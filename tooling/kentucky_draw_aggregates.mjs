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
