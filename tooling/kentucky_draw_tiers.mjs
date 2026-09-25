// Reviewed Kentucky-only payout response layouts; no retailer locations inferred.
export function parseKentuckyTiers(data, expectedGame) {
  const games = {26:'MEGAMILLIONS',24:'POWERBALLXO'};
  if (!games[expectedGame] || data.GAME_NUMBER?.length !== 1 || data.GAME_NUMBER[0] !== expectedGame || data.GAME_NAME?.[0] !== games[expectedGame]) throw Error('Unreviewed or mismatched game');
  if (!Number.isSafeInteger(data.DRAW_ID) || !Number.isSafeInteger(data.DRAW_DATE)) throw Error('Missing draw identity');
  const date = new Date(data.DRAW_DATE);
  const drawDate = new Intl.DateTimeFormat('en-CA',{timeZone:'America/New_York',year:'numeric',month:'2-digit',day:'2-digit'}).format(date);
  if (!Array.isArray(data.TIER_LIST) || data.TIER_LIST.length !== 1 || !Array.isArray(data.TIER_LIST[0]) || !data.TIER_LIST[0].length) throw Error('Unreviewed tier groups');
  const rows = data.TIER_LIST[0];
  const keys = new Set();
  let winners = 0, payout = 0;
  for (const r of rows) {
    const multiplier = expectedGame === 26 ? r.TIER_MULTIPLIER : 1;
    if (!Number.isSafeInteger(r.TIER_ID) || !Number.isSafeInteger(r.TIER_WINNER_COUNT) || r.TIER_WINNER_COUNT < 0 || !Number.isSafeInteger(r.TIER_JACKPOT) || r.TIER_JACKPOT < 0 || r.TIER_SPECIAL_DRAW !== 0 || typeof r.TIER_DESCRIPTION !== 'string' || !r.TIER_DESCRIPTION.trim()) throw Error('Invalid tier');
    if (expectedGame === 26 && !(r.TIER_ID === 1 ? multiplier === 0 : [2,3,4,5,10].includes(multiplier))) throw Error('Unreviewed multiplier');
    const key = `${r.TIER_ID}:${multiplier}`;
    if (keys.has(key)) throw Error('Duplicate tier/multiplier');
    keys.add(key);
    // Jackpot winners need separate annuity/cash treatment, not a guessed value.
    if (r.TIER_ID === 1 && r.TIER_WINNER_COUNT !== 0) throw Error('Jackpot winner requires separate review');
    winners += r.TIER_WINNER_COUNT;
    payout += r.TIER_WINNER_COUNT * r.TIER_JACKPOT * (multiplier || 1);
  }
  const rawPayout = data.SPECIAL_ARGS?.TOTAL_PRIZE;
  if (typeof rawPayout !== 'string' || !/^\$\s*\d[\d,]*$/.test(rawPayout)) throw Error('Invalid reported payout');
  if (winners !== data.SPECIAL_ARGS.TOTAL_WINNERS || payout !== Number(rawPayout.replace(/[$,\s]/g,''))) throw Error('Tier reconciliation failed');
  return {gameNumber:expectedGame,drawId:data.DRAW_ID,drawDate,sourcePublicationDate:null,
    coverage:'Kentucky statewide reported tier winners and payouts for this draw; not retailer locations or a complete historical claims archive. Base prize and multiplier remain separate.',
    reportedWinners:winners,reportedPayout:payout,tiers:rows.map(r=>({...r}))};
}
