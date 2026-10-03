// Parse official NY report fields, never national summary metadata or locations.
const levels = ['Jackpot', 'Second', 'Third', 'Fourth', 'Fifth', 'Sixth', 'Seventh', 'Eighth', 'Ninth'];
function tiers(rows, expected) {
  if (!Array.isArray(rows) || rows.length !== expected.length) throw Error('Incomplete NY tiers');
  const byLevel = new Map();
  for (const row of rows) {
    if (!expected.includes(row.prize_levels) || byLevel.has(row.prize_levels)) throw Error('Unexpected or duplicate NY tier');
    if (!Number.isSafeInteger(row.prize_winners) || row.prize_winners < 0) throw Error('Invalid NY winner count');
    if (typeof row.prize_amount !== 'string' || !row.prize_amount.trim()) throw Error('Missing NY prize label');
    byLevel.set(row.prize_levels, {
      tier: row.prize_levels, reportedWinners: row.prize_winners,
      prizeLabel: row.prize_amount,
    });
  }
  return expected.map(level => byLevel.get(level));
}
export function parseNewYorkPowerball(row) {
  if (row?.game !== 'Powerball' || !/^\d{4}-\d{2}-\d{2}$/.test(row.date ?? '') ||
      new Date(row.date + 'T00:00:00Z').toISOString().slice(0, 10) !== row.date) throw Error('Invalid NY Powerball provenance');
  if (!/^\d+$/.test(row.draw_number ?? '') || !/^0?[2345]$|^10$/.test(row.multiplier ?? '')) throw Error('Invalid NY Powerball draw or multiplier');
  const base = tiers(row.local_winners, levels);
  const powerPlay = tiers(row.power_play_local_winners, levels.slice(1).map(x => x + ' - Powerplay'));
  // The API duplicates Power Play under a legacy key; validate, never add twice.
  const alias = tiers(row.local_multiplier_winners, levels.slice(1).map(x => x + ' - Powerplay'));
  if (JSON.stringify(alias) !== JSON.stringify(powerPlay)) throw Error('Conflicting Power Play aliases');
  const doublePlay = tiers(row.dp_local_winners, levels.map(x => x + ' - Double Play'));
  return {gameName: 'Powerball', drawDate: row.date, drawNumber: row.draw_number,
    multiplier: row.multiplier, sourceUrl: 'https://nylottery.ny.gov/all-winning-numbers/?nid=21',
    sourcePublicationDate: null, jurisdiction: 'New York',
    countUnit: 'Source-reported NY winners; distinct tickets not established',
    limitation: 'Statewide report, not retailer claims. National winner counts and locations are excluded. Prize labels are preserved; no aggregate payout inferred. Zero jackpot prize label does not establish jackpot value.',
    tables: [{variant: 'Base', tiers: base}, {variant: 'Power Play', tiers: powerPlay}, {variant: 'Double Play', tiers: doublePlay}]};
}

export function parseNewYorkMegaMillions(row) {
  if (row?.game !== 'Mega Millions' || !/^\d{4}-\d{2}-\d{2}$/.test(row.date ?? '') ||
      new Date(row.date + 'T00:00:00Z').toISOString().slice(0, 10) !== row.date ||
      !/^\d+$/.test(row.draw_number ?? '')) throw Error('Invalid NY Mega Millions provenance');
  const jackpot = tiers(row.local_winners, ['Jackpot']);
  const multipliers = ['2X', '3X', '4X', '5X', '10X'];
  const nonJackpot = [];
  for (const level of levels.slice(1)) {
    const rows = row[level.toLowerCase() + '_prz_multiplier_winners'];
    if (!Array.isArray(rows) || rows.length !== 5) throw Error('Incomplete Mega Millions multipliers');
    const seen = new Set();
    for (const entry of rows) {
      if (!multipliers.includes(entry.mm_multiplier_level) || seen.has(entry.mm_multiplier_level)) throw Error('Invalid or duplicate Mega Millions multiplier');
      seen.add(entry.mm_multiplier_level);
      // National summary counts, locations and empty prize_levels are not identities.
      const parsed = tiers([{...entry, prize_levels: level}], [level])[0];
      nonJackpot.push({...parsed, multiplier: entry.mm_multiplier_level});
    }
  }
  return {gameName: 'Mega Millions', drawDate: row.date, drawNumber: row.draw_number,
    sourceUrl: 'https://nylottery.ny.gov/all-winning-numbers/?nid=16',
    sourcePublicationDate: null, jurisdiction: 'New York',
    countUnit: 'Source-reported NY winners; distinct tickets not established',
    limitation: 'Built-in multipliers are already included in source prize labels. National summary counts and locations excluded. No aggregate payout inferred; zero jackpot prize label is not a jackpot valuation.',
    tables: [{variant: 'Jackpot', tiers: jackpot},
      ...multipliers.map(multiplier => ({variant: 'Built-in ' + multiplier,
        tiers: nonJackpot.filter(t => t.multiplier === multiplier)}))]};
}

const stateTierGames = {
  LOTTO: {id: 26, levels: ['Jackpot', 'Second', 'Third', 'Fourth', 'Fifth']},
  'Take 5': {id: 36, levels: ['First', 'Second', 'Third', 'Fourth']},
  'Millionaire For Life': {id: 374901, levels: ['First', ...levels.slice(1)]},
};
export function parseNewYorkStateTiers(row) {
  const game = stateTierGames[row?.game];
  if (!game || !/^\d{4}-\d{2}-\d{2}$/.test(row.date ?? '') ||
      new Date(row.date + 'T00:00:00Z').toISOString().slice(0, 10) !== row.date ||
      !/^\d+$/.test(row.draw_number ?? '')) throw Error('Invalid NY state report provenance');
  if (row.game === 'Take 5' && !['Midday', 'Evening'].includes(row.draw_time)) throw Error('Unknown Take 5 session');
  const parsed = tiers(row.local_winners, game.levels);
  if (row.game === 'Take 5' && parsed[3].prizeLabel !== 'FREE PLAY') throw Error('Missing Take 5 free-play tier');
  if (row.game === 'Millionaire For Life' &&
      (parsed[0].prizeLabel !== '$1 Million a Year for Life' || parsed[1].prizeLabel !== '$100,000 a Year for Life')) throw Error('Changed MFL annual prize wording');
  return {gameName: row.game, drawDate: row.date, drawNumber: row.draw_number,
    drawingSession: row.game === 'Take 5' ? row.draw_time : null,
    sourceUrl: 'https://nylottery.ny.gov/all-winning-numbers/?nid=' + game.id,
    sourcePublicationDate: null, jurisdiction: 'New York',
    countUnit: 'Source-reported NY winners; distinct tickets not established',
    limitation: 'Statewide report, not retailer claims. Literal source prize labels retain free plays and annual payments. Zero jackpot label is not jackpot value; no aggregate payout inferred. National summary fields excluded.',
    tables: [{variant: 'Base', tiers: parsed}]};
}
