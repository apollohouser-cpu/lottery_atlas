// Reviewed Kentucky state-game layouts. These records never establish store locations.
const games = {
  14: {key:'MILLIONAIREFORLIFE', name:'Millionaire For Life', tiers:9},
  13: {key:'CASHBALL', name:'Cash Ball 225', tiers:8},
  16: {key:'PICK3', name:'Pick 3', tiers:10},
  17: {key:'PICK4', name:'Pick 4', tiers:9},
};
const integer = n => Number.isSafeInteger(n) && n >= 0;
const dollars = s => {
  if(typeof s !== 'string' || !/^\$\s*\d[\d,]*(?:\.00)?$/.test(s)) throw Error('Invalid reported payout');
  const n=Number(s.replace(/[$,\s]/g,''));
  if(!integer(n)) throw Error('Unsafe payout');
  return n;
};
export function latestKentuckyStateDraws(history,game,now=Date.now()) {
  if(!games[game] || JSON.stringify(history.GAME_NUMBER)!==JSON.stringify([game]) || !Array.isArray(history.DRAW_HISTORY) || !history.DRAW_HISTORY.length) throw Error('Invalid history');
  const sessions=game===16 || game===17 ? ['MIDDAY','EVENING'] : [null];
  const seen=new Set();
  for(const r of history.DRAW_HISTORY){
    if(!integer(r.DRAW_ID) || !integer(r.DRAW_DATE) || r.DRAW_DATE>now || seen.has(r.DRAW_ID) || !sessions.includes(r.DRAW_TIME ?? null)) throw Error('Invalid history identity/session');
    seen.add(r.DRAW_ID);
  }
  return sessions.map(session=>{
    const rows=history.DRAW_HISTORY.filter(r=>(r.DRAW_TIME??null)===session).sort((a,b)=>b.DRAW_DATE-a.DRAW_DATE);
    if(!rows.length || (rows.length>1 && rows[0].DRAW_DATE===rows[1].DRAW_DATE))throw Error('Missing or ambiguous session');
    return {...rows[0]};
  });
}
export function parseKentuckyStateTiers(data,game) {
  const config=games[game];
  if(!config || JSON.stringify(data.GAME_NUMBER)!==JSON.stringify([game]) || JSON.stringify(data.GAME_NAME)!==JSON.stringify([config.key]) || !integer(data.DRAW_ID) || !integer(data.DRAW_DATE)) throw Error('Invalid game identity');
  const drawingSession=data.DRAW_TIME??null;
  if((game===16 || game===17) ? !['MIDDAY','EVENING'].includes(drawingSession) : drawingSession!==null)throw Error('Invalid session');
  if(!Array.isArray(data.TIER_LIST) || data.TIER_LIST.length!==1 || !Array.isArray(data.TIER_LIST[0]) || data.TIER_LIST[0].length!==config.tiers)throw Error('Unreviewed tier groups');
  let count=0,payout=0;const seen=new Set();
  for(const r of data.TIER_LIST[0]){
    if(!integer(r.TIER_ID)||r.TIER_ID<1||r.TIER_ID>config.tiers||seen.has(r.TIER_ID)||!integer(r.TIER_WINNER_COUNT)||!integer(r.TIER_JACKPOT)||r.TIER_SPECIAL_DRAW!==0||typeof r.TIER_DESCRIPTION!=='string'||!r.TIER_DESCRIPTION.trim())throw Error('Invalid tier');
    seen.add(r.TIER_ID);
    // Source top amounts do not establish cash value for annuity prizes.
    if(game===14 && r.TIER_ID<=2 && r.TIER_WINNER_COUNT!==0)throw Error('Life top-prize payout requires review');
    count+=r.TIER_WINNER_COUNT;payout+=r.TIER_WINNER_COUNT*r.TIER_JACKPOT;
  }
  if(!integer(count)||!integer(payout)||count!==data.SPECIAL_ARGS?.TOTAL_WINNERS||payout!==dollars(data.SPECIAL_ARGS?.TOTAL_PRIZE))throw Error('Tier reconciliation failed');
  let ezTotals=null;
  if(game===13){
    const winners=data.SPECIAL_ARGS.TOTAL_WINNER_EZ;
    if(!integer(winners))throw Error('Invalid EZ totals');
    ezTotals={reportedWinners:winners,reportedPayout:dollars(data.SPECIAL_ARGS.TOTAL_PAYOUT_EZ),coverage:'Separate source-reported EZ totals; no EZ tier breakdown in this response. Not added to Cash Ball base totals.'};
  }
  return {gameNumber:game,gameName:config.name,drawId:data.DRAW_ID,drawingSession,
    drawDate:new Intl.DateTimeFormat('en-CA',{timeZone:'America/New_York',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date(data.DRAW_DATE)),
    sourcePublicationDate:null,reportedWinners:count,reportedPayout:payout,
    prizeBasis:game===14?'Source-listed tier amounts; top annuity/cash basis not established. No top-tier winners in this reviewed report.':'Source-listed tier amounts; not verified cash claims or retailer locations.',
    tiers:data.TIER_LIST[0].map(r=>({...r})),ezTotals};
}
