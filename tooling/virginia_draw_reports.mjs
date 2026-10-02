// Dated official reports; kept separate from retailer winner releases.
export const tableGames = {
  1075: {code: 'millionaire-for-life', name: 'Millionaire for Life', path: 'millionaireforlife', matches: ['5 + 1', '5', '4 + 1', '4', '3 + 1', '3', '2 + 1', '2', '1 + 1']},
  1070: {code: 'bank-a-million', name: 'Bank a Million', path: 'bankamillion', matches: ['6', '5 + 1', '5', '4 + 1', '4', '3 + 1', '3', '2 + 1']},
};
const fail = (message) => { throw new Error(message); };
export function parseTableReports(payload, gameId) {
  const game = tableGames[gameId];
  if (!game || !Array.isArray(payload.data) || !payload.data.length) fail('Missing supported draw data');
  const seen = new Set();
  const reports = payload.data.map((draw) => {
    const date = draw.DrawDate?.match(/^(\d{4}-\d{2}-\d{2})T00:00:00$/)?.[1];
    if (draw.DrawGameId !== Number(gameId) || !date ||
        new Date(`${date}T00:00:00Z`).toISOString().slice(0, 10) !== date || seen.has(date)) fail('Invalid or duplicate draw identity');
    seen.add(date);
    if (draw.DailyDrawDetails?.length !== 1) fail('Unexpected report sessions');
    const data = draw.DailyDrawDetails[0].DrawData;
    // A dated draw can exist before its prize report has been published.
    if (Array.isArray(data?.Values) && data.Values.length === 0) return null;
    if (JSON.stringify(data?.Headings) !== JSON.stringify(['Match', 'Prize Winners', 'Prize Amount']) ||
        data.Values?.length !== game.matches.length) fail('Unexpected tier schema');
    if (Number(gameId) === 1075 && !data.WinnerLocation?.includes('This table shows Virginia wins.')) fail('Missing Virginia jurisdiction statement');
    const tiers = data.Values.map((tier, i) => {
      if (tier.Matches !== game.matches[i] || !/^(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)$/.test(tier.Winners) ||
          typeof tier.PrizeAmounts !== 'string' || !tier.PrizeAmounts.startsWith('$')) fail('Invalid match, count or prize');
      const count = Number(tier.Winners.replaceAll(',', ''));
      if (!Number.isSafeInteger(count)) fail('Unsafe count');
      return {match: tier.Matches, winnerCount: count, prizeDescription: tier.PrizeAmounts};
    });
    const totalWinners = tiers.reduce((n, tier) => n + tier.winnerCount, 0);
    if (!Number.isSafeInteger(totalWinners)) fail('Unsafe total');
    return {game: game.code, gameName: game.name, drawDate: date, jurisdiction: 'Virginia',
      sourceUrl: `https://www.valottery.com/data/draw-games/${game.path}`,
      sourceNote: data.WinnerLocation || null, countUnit: 'source-reported prize winners',
      tiers, totalWinners, totalPayout: null,
      limitations: 'Dated draw report, not claims or retailer locations. Counts are not verified distinct tickets. Prize descriptions retain source payment and tax terms; no total payout is inferred.'};
  }).filter(Boolean);
  if (!reports.length) fail('No published tier reports');
  return reports;
}
export function assertNoReportRegression(previous, reports) {
  for (const game of new Set(previous.map((r) => `${r.game}/${r.session ?? ""}`))) {
    const latest = (items) => items.filter((r) => `${r.game}/${r.session ?? ""}` === game).map((r) => r.drawDate).sort().at(-1);
    if (!latest(reports) || latest(reports) < latest(previous)) fail(`Draw date regression: ${game}`);
  }
}

export const pickGames = {
  1050: {code: 'pick-3', name: 'Pick 3', flag: 'bIsFireBallPick3'},
  1040: {code: 'pick-4', name: 'Pick 4', flag: 'bIsFireBallPick4'},
  1035: {code: 'pick-5', name: 'Pick 5', flag: 'bIsFireBallPick5'},
};
export function parsePickReports(payload, gameId) {
  const game = pickGames[gameId];
  if (!game || !Array.isArray(payload.data) || !payload.data.length) fail('Missing supported Pick data');
  const seen = new Set();
  const reports = [];
  const dollars = (value) => {
    if (typeof value !== 'string' || !/^(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)$/.test(value)) fail('Invalid prize dollars');
    const result = Number(value.replaceAll(',', ''));
    if (!Number.isSafeInteger(result)) fail('Unsafe prize dollars');
    return result;
  };
  for (const draw of payload.data) {
    const date = draw.DrawDate?.match(/^(\d{4}-\d{2}-\d{2})T00:00:00$/)?.[1];
    if (draw.DrawGameId !== Number(gameId) || !date ||
        new Date(`${date}T00:00:00Z`).toISOString().slice(0, 10) !== date ||
        !Array.isArray(draw.DailyDrawDetails) || !draw.DailyDrawDetails.length) fail('Invalid Pick identity');
    for (const detail of draw.DailyDrawDetails) {
      const session = {'Day Drawing Details': 'Day', 'Night Drawing Details': 'Night'}[detail.Title];
      const key = `${date}/${session}`;
      if (!session || seen.has(key) || detail[game.flag] !== true) fail('Invalid Pick session');
      seen.add(key);
      const data = detail.DrawData;
      // Null amounts are unpublished, not zero; partially populated reports fail.
      if (data?.TotalPrizes == null && data?.TotalFireballPrizes == null) continue;
      const base = dollars(data?.TotalPrizes);
      const fireball = dollars(data?.TotalFireballPrizes);
      if (!Number.isSafeInteger(base + fireball)) fail('Unsafe combined payout');
      reports.push({game: game.code, gameName: game.name, drawDate: date, session,
        jurisdiction: 'Virginia', sourceUrl: `https://www.valottery.com/data/draw-games/${game.code.replace('-', '')}`,
        sourceNote: 'Official totals include online and retail wins.',
        countUnit: null, totalWinners: null, tiers: [],
        components: [{name: 'Base', payout: base}, {name: 'FIREBALL', payout: fireball}],
        totalPayout: base + fireball,
        limitations: 'Session prize dollars, not winner counts or claims. No tier-count breakdown or retailer allocation is supplied. Base and FIREBALL totals include online and retail wins.'});
    }
  }
  if (!reports.length) fail('No published Pick reports');
  return reports;
}
