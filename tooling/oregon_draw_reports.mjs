// Reconciled with Oregon's public ol-table-jackpot-results renderer.
// Current MM/CP use aggregate fields despite their jackpot-oriented API names.
const games = {mm: ['Mega Millions', 'mega-millions'], cp: ['Cash Pop', 'cash-pop']};

function sourceDateTime(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/.test(value)) {
    throw Error('Invalid Oregon source date/time');
  }
  const parsed = new Date(`${value}Z`);
  if (!Number.isFinite(parsed.getTime()) || parsed.toISOString().slice(0, 19) !== value) {
    throw Error('Invalid Oregon calendar date/time');
  }
  // UTC is used only to validate calendar components, never to convert source time.
  return value;
}

export function parseOregonAggregate(selector, row) {
  if (!Object.hasOwn(games, selector)) throw Error('Unsupported Oregon aggregate game');
  if (!row || row.DrawIsFinal !== true || row.GameVersion !== 0) {
    throw Error('Unfinalized or unsupported Oregon draw version');
  }
  if (!Number.isSafeInteger(row.DrawNumber) || row.DrawNumber <= 0) throw Error('Invalid Oregon draw number');
  const rawTime = sourceDateTime(row.DrawDateTime);
  const roundedTime = sourceDateTime(row.RoundedDrawDateTime);
  const displayTime = selector === 'cp' ? roundedTime : rawTime;
  if (selector === 'mm' && displayTime.slice(0, 10) < '2025-04-08') {
    throw Error('Historical Mega Millions requires its separate schema');
  }
  if (selector === 'cp' && (rawTime.slice(0, 10) !== roundedTime.slice(0, 10)
      || !/^\d{4}-\d{2}-\d{2}T(?:0[7-9]|1\d|2[0-2]):00:00$/.test(roundedTime)
      || ![0, 60000].includes(Date.parse(`${roundedTime}Z`) - Date.parse(`${rawTime}Z`)))) {
    throw Error('Invalid Cash Pop scheduled time');
  }
  const count = row.OregonJackpotWinners;
  const payout = row.JackpotShareAmount;
  if (!Number.isSafeInteger(count) || count < 0) throw Error('Invalid reported Oregon winners');
  if (typeof payout !== 'number' || !Number.isFinite(payout) || payout < 0
      || !Number.isSafeInteger(Math.round(payout * 100))
      || Math.abs(payout * 100 - Math.round(payout * 100)) > 0.00001) {
    throw Error('Invalid Oregon payout dollars');
  }
  return {
    id: `or-${selector}-${row.DrawNumber}`, game: games[selector][0], gameCode: selector,
    drawNumber: row.DrawNumber, drawDate: displayTime.slice(0, 10),
    sourceDrawDateTime: rawTime, sourceRoundedDrawDateTime: roundedTime,
    drawingTime: selector === 'cp' ? displayTime.slice(11, 16) : null,
    dateBasis: 'Source draw date/time; original wall-clock values retained without UTC conversion.',
    reportedWinners: count, countUnit: 'Oregon source-reported winners; distinct tickets or people not established.',
    winningTickets: null, publishedPayoutDollars: payout,
    sourceUrl: `https://www.oregonlottery.org/${games[selector][1]}/winning-numbers/`,
    limitations: 'Aggregate report, not jackpot winners or a prize-tier breakdown. No retailer locations or complete claims coverage.',
  };
}
