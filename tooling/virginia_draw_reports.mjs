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

export function parseCash5Reports(payload) {
  if (!Array.isArray(payload.data) || !payload.data.length) fail('Missing Cash 5 data');
  const seen = new Set();
  const number = (value) => {
    if (typeof value !== 'string' || !/^(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)$/.test(value)) fail('Invalid Cash 5 number');
    const n = Number(value.replaceAll(',', ''));
    if (!Number.isSafeInteger(n)) fail('Unsafe Cash 5 number');
    return n;
  };
  const reports = payload.data.map((draw) => {
    const date = draw.DrawDate?.match(/^(\d{4}-\d{2}-\d{2})T00:00:00$/)?.[1];
    if (draw.DrawGameId !== 1030 || !date ||
        new Date(`${date}T00:00:00Z`).toISOString().slice(0, 10) !== date || seen.has(date)) fail('Invalid Cash 5 identity');
    seen.add(date);
    if (draw.DailyDrawDetails?.length !== 1) fail('Unexpected Cash 5 sessions');
    const detail = draw.DailyDrawDetails[0];
    if (detail.bIsC5EZMatch !== true) fail('Missing Cash 5 report flag');
    const data = detail.DrawData;
    if (data?.TotalPrizes == null && data?.TotalEZMatchPrizes == null &&
        [1, 2, 3, 4].every(i => detail[`Prize${i}`] == null)) return null;
    const tiers = [1, 2, 3, 4].map((i) => {
      const match = detail[`Prize${i}`]?.match(/^(\d[\d,]*) Plays matched ([2-5]) of 5 \/ paying \$(\d[\d,]*)$/);
      if (!match || Number(match[2]) !== 6 - i) fail('Invalid Cash 5 tier');
      return {match: `${match[2]} of 5`, winnerCount: number(match[1]),
        prizeDescription: `$${match[3]}`, prizeAmount: number(match[3])};
    });
    const base = number(data?.TotalPrizes);
    const ezMatch = number(data?.TotalEZMatchPrizes);
    const calculated = tiers.reduce((sum, t) => sum + t.winnerCount * t.prizeAmount, 0);
    const totalWinners = tiers.reduce((sum, t) => sum + t.winnerCount, 0);
    if (!Number.isSafeInteger(calculated) || calculated !== base ||
        !Number.isSafeInteger(base + ezMatch) || !Number.isSafeInteger(totalWinners)) fail('Cash 5 payout mismatch');
    return {game: 'cash-5', gameName: 'Cash 5 with EZ Match', drawDate: date,
      jurisdiction: 'Virginia', sourceUrl: 'https://www.valottery.com/data/draw-games/cash5',
      sourceNote: 'Official totals include online and retail wins.',
      countUnit: 'base-game winning plays only', tiers, totalWinners,
      components: [{name: 'Cash 5 base', payout: base}, {name: 'EZ Match', payout: ezMatch}],
      totalPayout: base + ezMatch,
      limitations: 'Winning-play count covers Cash 5 base only; EZ Match supplies prize dollars without a winner count. Includes online and retail wins. Not claims or distinct tickets; no retailer allocation.'};
  }).filter(Boolean);
  if (!reports.length) fail('No published Cash 5 reports');
  return reports;
}

export function parseCashPopReports(payload) {
  if (!Array.isArray(payload.data) || !payload.data.length) fail('Missing Cash Pop data');
  const sessions = {Coffee: 'Coffee Break', Lunch: 'Lunch Break', Rush: 'Rush Hour', Prime: 'Prime Time', After: 'After Hours'};
  const seen = new Set();
  const reports = [];
  for (const draw of payload.data) {
    const date = draw.DrawDate?.match(/^(\d{4}-\d{2}-\d{2})T\d{2}:\d{2}:\d{2}$/)?.[1];
    if (draw.DrawGameId !== 40 || !date || new Date(`${date}T00:00:00Z`).toISOString().slice(0, 10) !== date ||
        draw.DailyDrawDetails?.length !== 1) fail('Invalid Cash Pop identity');
    const detail = draw.DailyDrawDetails[0];
    if (detail.bIsCashPop !== true) fail('Missing Cash Pop flag');
    for (const [suffix, session] of Object.entries(sessions)) {
      const available = detail[`bIsPrizes${suffix}`];
      if (typeof available !== 'boolean') fail('Missing Cash Pop availability');
      if (!available) continue;
      const key = `${date}/${session}`;
      if (seen.has(key)) fail('Duplicate Cash Pop session');
      seen.add(key);
      const value = detail.DrawData?.[`TotalPrizes${suffix}`];
      if (typeof value !== 'string' || !/^(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)$/.test(value)) fail('Invalid Cash Pop dollars');
      const payout = Number(value.replaceAll(',', ''));
      if (!Number.isSafeInteger(payout)) fail('Unsafe Cash Pop dollars');
      reports.push({game: 'cash-pop', gameName: 'Cash Pop', drawDate: date, session,
        jurisdiction: 'Virginia', sourceUrl: 'https://www.valottery.com/data/draw-games/cashpop',
        sourceNote: null, countUnit: null, tiers: [], totalWinners: null,
        totalPayout: payout, components: [{name: session, payout}],
        limitations: 'Official session prize dollars only; no tier breakdown, winner count, distinct-ticket count or retailer allocation is supplied. Unpublished sessions are omitted, not zero.'});
    }
  }
  if (!reports.length) fail('No published Cash Pop reports');
  return reports;
}
