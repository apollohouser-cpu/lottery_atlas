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
  for (const game of new Set(previous.map((r) => r.game))) {
    const latest = (items) => items.filter((r) => r.game === game).map((r) => r.drawDate).sort().at(-1);
    if (!latest(reports) || latest(reports) < latest(previous)) fail(`Draw date regression: ${game}`);
  }
}
