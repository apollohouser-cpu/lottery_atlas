// Reviewed official Kentucky Powerball layout. Power Play is a subset, not extra winners.
export function parseKentuckyPowerball(data) {
  if (JSON.stringify(data.GAME_NUMBER)!=='[12]' || JSON.stringify(data.GAME_NAME)!=='["POWERBALL"]' || !Number.isSafeInteger(data.DRAW_ID) || !Number.isSafeInteger(data.DRAW_DATE)) throw Error('Invalid Powerball identity');
  if (!Array.isArray(data.TIER_LIST) || data.TIER_LIST.length!==2) throw Error('Expected separate Powerball and Double Play groups');
  if (data.DOUBLE_PLAY_DRAW_DATE!==data.DRAW_DATE || !Number.isSafeInteger(data.DOUBLE_PLAY_DRAW_ID)) throw Error('Double Play identity/date mismatch');
  const multiplier=data.SPECIAL_ARGS?.POWERPLAY;
  if (![2,3,4,5,10].includes(multiplier)) throw Error('Unknown Power Play multiplier');
  const amount=s=>{if(typeof s!=='string'||!/^\$\s*\d[\d,]*(?:\.00)?$/.test(s)) throw Error('Invalid payout');return Number(s.replace(/[$,\s]/g,''));};
  const groups=data.TIER_LIST.map((rows,index)=>{
    if (!Array.isArray(rows) || rows.length!==9) throw Error('Missing prize tiers');
    const prefix=index?'DOUBLE_PLAY_':'';
    const seen=new Set();let winners=0,payout=0,powerPlayWinners=0;
    for(const r of rows){
      const id=r[prefix+'TIER_ID'],count=r[prefix+'TIER_WINNER_COUNT'],special=r[prefix+'TIER_SPECIAL_DRAW'],base=r[prefix+'TIER_JACKPOT'];
      if(!Number.isSafeInteger(id)||id<1||id>9||seen.has(id)||![count,special,base].every(n=>Number.isSafeInteger(n)&&n>=0)||typeof r[prefix+'TIER_DESCRIPTION']!=='string')throw Error('Invalid tier');
      seen.add(id);
      if(special>count || (index && special!==0))throw Error('Invalid subset');
      if(id===1 && count!==0)throw Error('Top-prize winner requires review');
      winners+=count;powerPlayWinners+=special;
      payout+=base*count + (index ? 0 : base*special*((id===2 ? 2 : multiplier)-1));
    }
    const totals=index?data.DOUBLE_PLAY_SPECIAL_ARGS:data.SPECIAL_ARGS;
    if(winners!==totals?.[prefix+'TOTAL_WINNERS']||payout!==amount(totals?.[prefix+'TOTAL_PRIZE']))throw Error('Tier reconciliation failed');
    return {gameName:index?'Powerball Double Play':'Powerball',reportedWinners:winners,reportedPayout:payout,powerPlayWinners,tiers:structuredClone(rows)};
  });
  const drawDate=new Intl.DateTimeFormat('en-CA',{timeZone:'America/New_York',year:'numeric',month:'2-digit',day:'2-digit'}).format(new Date(data.DRAW_DATE));
  return {drawDate,sourcePublicationDate:null,powerPlayMultiplier:multiplier,reports:groups};
}
