// The official past-results renderer labels prizePayout as dollars. Tier
// winnersNumber units are not established, so they are deliberately omitted.
const games = {
  Pick3: ['Pick 3', 'pick-3', 13],
  Pick4: ['Pick 4', 'pick-4', 14],
  Pick5: ['Pick 5', 'pick-5', 25],
  ClassicLotto: ['Classic Lotto', 'classic-lotto', 26],
  RollingCashFive: ['Rolling Cash 5', 'rolling-cash-5', 24],
};

export function parseOhioPayout(game, row) {
  const definition = games[game];
  if (!definition) throw Error('Unsupported Ohio payout game');
  if (!row || row.approved !== true || row.drawGameId !== definition[2]) {
    throw Error('Unapproved or mismatched Ohio draw');
  }
  const date = String(row.drawDate ?? '');
  if (!/^\d{4}-\d{2}-\d{2}T00:00:00$/.test(date) ||
      !Number.isFinite(Date.parse(date + 'Z')) ||
      new Date(date + 'Z').toISOString().slice(0, 10) !== date.slice(0, 10)) {
    throw Error('Invalid Ohio draw date');
  }
  const pick = game.startsWith('Pick');
  if (!(pick ? [1, 2] : [0]).includes(row.modifier)) {
    throw Error('Invalid Ohio drawing session');
  }
  if (!Number.isSafeInteger(row.externalDrawId) || row.externalDrawId <= 0) {
    throw Error('Invalid Ohio draw number');
  }
  if (typeof row.prizePayout !== 'number' || !Number.isFinite(row.prizePayout) ||
      row.prizePayout < 0) throw Error('Missing or invalid Ohio payout');
  return {
    id: `oh-${game}-${row.externalDrawId}-${row.modifier}`,
    game: definition[0],
    drawDate: date.slice(0, 10),
    drawingSession: pick ? (row.modifier === 1 ? 'Midday' : 'Evening') : null,
    drawNumber: String(row.externalDrawId),
    publishedPayoutDollars: row.prizePayout,
    winningTickets: null,
    sourceUrl: `https://www.ohiolottery.com/Games/Draw-Games/${definition[1]}`,
    limitations: 'Published draw payout dollars, not ticket or winner counts. No retailer allocation. Source date has no verified event time. Tier-count units remain unverified.',
  };
}
