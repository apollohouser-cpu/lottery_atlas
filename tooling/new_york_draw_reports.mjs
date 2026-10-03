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
