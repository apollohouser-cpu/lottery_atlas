// Reconciled with Oregon's public ol-table-jackpot-results renderer.
// Current MM/CP use aggregate fields despite their jackpot-oriented API names.
const games = {mm: ['Mega Millions', 'mega-millions'], cp: ['Cash Pop', 'cash-pop'],
  pb: ['Powerball', 'powerball'], mb: ['Megabucks', 'megabucks'],
  wf: ['Win for Life', 'win-for-life'], p4: ['Pick 4', 'pick-4']};

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

function identity(selector, row) {
  if (!Object.hasOwn(games, selector)) throw Error('Unsupported Oregon game');
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
  if (selector === 'p4' && !['13:00:00', '16:00:00', '19:00:00', '22:00:00'].includes(rawTime.slice(11))) {
    throw Error('Invalid Pick 4 session');
  }
  return {
    id: `or-${selector}-${row.DrawNumber}`, game: games[selector][0], gameCode: selector,
    drawNumber: row.DrawNumber, drawDate: displayTime.slice(0, 10),
    sourceDrawDateTime: rawTime, sourceRoundedDrawDateTime: roundedTime,
    drawingTime: ['cp', 'p4'].includes(selector) ? displayTime.slice(11, 16) : null,
    dateBasis: 'Source draw date/time; original wall-clock values retained without UTC conversion.',
    countUnit: 'Oregon source-reported winners; distinct tickets or people not established.',
    winningTickets: null,
    sourceUrl: `https://www.oregonlottery.org/${games[selector][1]}/winning-numbers/`,
  };
}

function count(value) {
  if (!Number.isSafeInteger(value) || value < 0) throw Error('Invalid reported Oregon winners');
  return value;
}

function money(value) {
  if (typeof value !== 'number' || !Number.isFinite(value) || value < 0
      || !Number.isSafeInteger(Math.round(value * 100))
      || Math.abs(value * 100 - Math.round(value * 100)) > 0.00001) {
    throw Error('Invalid Oregon payout dollars');
  }
  return value;
}

export function parseOregonAggregate(selector, row) {
  if (!['mm', 'cp'].includes(selector)) throw Error('Unsupported Oregon aggregate game');
  return {...identity(selector, row), reportedWinners: count(row.OregonJackpotWinners),
    publishedPayoutDollars: money(row.JackpotShareAmount),
    limitations: 'Aggregate report, not jackpot winners or a prize-tier breakdown. No retailer locations or complete claims coverage.'};
}

const powerballMatches = ['5 + Powerball', '5', '4 + Powerball', '4',
  '3 + Powerball', '3', '2 + Powerball', '1 + Powerball', 'Powerball only'];

export function parseOregonTiers(selector, row) {
  if (!['pb', 'mb', 'wf', 'p4'].includes(selector)) throw Error('Unsupported Oregon tier game');
  const report = identity(selector, row);
  if (!Array.isArray(row.OregonShareCounts) || row.OregonShareCounts.length !== 16
      || !Array.isArray(row.ShareAmounts) || row.ShareAmounts.length !== 16) {
    throw Error('Invalid Oregon prize array shape');
  }
  const counts = [count(row.OregonJackpotWinners), ...row.OregonShareCounts.map(count)];
  const amounts = [money(row.JackpotShareAmount), ...row.ShareAmounts.map(money)];
  const expected = {pb: 9, mb: 7, wf: 7, p4: 17}[selector];
  for (let i = 0; i < 17; i++) {
    // Padding is verified, not silently dropped. A new populated tier needs audit.
    if (i < expected ? amounts[i] <= 0 : amounts[i] !== 0 || counts[i] !== 0) {
      throw Error('Unexpected Oregon prize tier or padding');
    }
  }
  if (selector === 'wf' && amounts[0] !== 52000) throw Error('Unverified Win for Life top prize');
  if (selector === 'pb' && ![2, 3, 4, 5, 10].includes(row.Multiplier)) throw Error('Invalid Power Play multiplier');

  let tiers;
  if (selector === 'p4') {
    const grouped = new Map();
    amounts.forEach((amount, i) => {
      const cents = Math.round(amount * 100);
      const group = grouped.get(cents) ?? {prizeDollars: amount, reportedWinners: 0, sourceRows: []};
      group.reportedWinners = count(group.reportedWinners + counts[i]);
      group.sourceRows.push(i + 1);
      grouped.set(cents, group);
    });
    tiers = [...grouped.values()].sort((a, b) => b.prizeDollars - a.prizeDollars)
      .map(tier => ({...tier, prizeText: `$${tier.prizeDollars.toLocaleString('en-US')}`, match: null}));
  } else {
    tiers = amounts.slice(0, expected).map((amount, i) => ({sourceRows: [i + 1],
      reportedWinners: counts[i],
      prizeDollars: selector === 'wf' && i === 0 ? null : amount,
      prizeText: selector === 'wf' && i === 0 ? '$1,000 a week for life' : `$${amount.toLocaleString('en-US')}`,
      match: selector === 'pb' ? powerballMatches[i] : null,
    }));
  }
  return {...report, tiers, multiplier: selector === 'pb' ? row.Multiplier : null,
    limitations: 'Source-reported Oregon prize rows, not distinct tickets or people. No cross-tier total, retailer allocation or complete claims coverage. Power Play overlap is not separately allocated; shared prizes and lifetime prizes retain source meaning. Unverified match/wager labels are omitted.'};
}

export function parseOregonReport(selector, row) {
  return ['mm', 'cp'].includes(selector) ? parseOregonAggregate(selector, row) : parseOregonTiers(selector, row);
}
