/* Imports every retail Scratch-Off game from the official New York Lottery API. */
import {readFile, writeFile} from 'node:fs/promises';

const apiUrl =
  'https://nylottery.ny.gov/drupal-api/api/v2/scratch_off_data?_format=json';
const sourceUrl = 'https://nylottery.ny.gov/scratch-off-games/';
const outputPath = process.argv[2];

if (!outputPath) {
  console.error('Usage: node tooling/import_new_york_scratch_catalog.mjs OUTPUT.json');
  process.exitCode = 1;
} else {
  const compact = (value) => String(value ?? '').replace(/\s+/g, ' ').trim();
  const money = (value) => {
    const normalized = compact(value).replaceAll(',', '').replaceAll('*', '');
    const match = normalized.match(/\$?([\d.]+)\s*([KMB])?/i);
    if (!match) return null;
    const multiplier = {K: 1e3, M: 1e6, B: 1e9}[match[2]?.toUpperCase()] ?? 1;
    const result = Number(match[1]) * multiplier;
    return Number.isFinite(result) && result > 0 ? Math.round(result) : null;
  };
  const integer = (value) => {
    const result = Number(String(value ?? '').replaceAll(',', '').trim());
    return Number.isInteger(result) && result >= 0 ? result : null;
  };
  const existingOutput = async () => {
    try {
      return JSON.parse(await readFile(outputPath, 'utf8'));
    } catch (_) {
      return null;
    }
  };
  const fetchJson = async () => {
    let lastError;
    for (let attempt = 1; attempt <= 4; attempt++) {
      try {
        const response = await fetch(apiUrl, {
          headers: {
            accept: 'application/json',
            'user-agent': 'LotteryAtlasOfficialDataBot/1.0',
          },
        });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        return await response.json();
      } catch (error) {
        lastError = error;
        if (attempt < 4) {
          await new Promise((resolve) => setTimeout(resolve, attempt * 750));
        }
      }
    }
    throw new Error(`Official Scratch-Off API failed: ${lastError.message}`);
  };

  try {
    const payload = await fetchJson();
    const rows = payload?.rows;
    if (!Array.isArray(rows) || rows.length < 80) {
      throw new Error(`Only ${rows?.length ?? 0} current Scratch-Off games were returned`);
    }
    const ids = new Set();
    const games = rows.map((row) => {
      const id = compact(row.game_number);
      const name = compact(row.title);
      const cost = money(row.ticket_price);
      const topPrize = money(row.top_prize_amount);
      const topPrizesRemaining = integer(row.top_prize_remaining);
      if (
        !id || !ids.add(id) || !name || cost === null || topPrize === null ||
        topPrizesRemaining === null
      ) {
        throw new Error(`Incomplete or duplicate official Scratch-Off game ${id || '?'}`);
      }
      return {
        id,
        name,
        cost,
        topPrize,
        topPrizesRemaining,
        ...(compact(row.top_prize_amount) !== `$${topPrize.toLocaleString('en-US')}`
          ? {topPrizeLabel: compact(row.top_prize_amount)}
          : {}),
      };
    }).sort((left, right) => left.id.localeCompare(right.id));

    const sourceDates = rows.map((row) => Number(row.last_updated))
      .filter((value) => Number.isFinite(value) && value > 0)
      .map((value) => new Date(value * 1000).toISOString());
    if (sourceDates.length !== rows.length) {
      throw new Error('One or more official games is missing its last-updated timestamp');
    }
    const sourceLastUpdated = sourceDates.sort().at(-1);
    const catalogs = [{state: 'New York', source: sourceUrl, games}];
    const existing = await existingOutput();
    const changed = JSON.stringify(existing?.catalogs ?? null) !== JSON.stringify(catalogs);
    const updatedAt = changed
      ? new Date().toISOString()
      : existing?.updatedAt ?? new Date().toISOString();
    const output = {
      source: 'New York Lottery official Scratch-Off game-data API',
      updatedAt,
      sourceLastUpdated,
      coverage:
        `All ${games.length} retail Scratch-Off games returned by the official ` +
        'New York Lottery API, including ticket price, advertised top prize, ' +
        'and current remaining top-prize count.',
      catalogs,
    };
    await writeFile(outputPath, `${JSON.stringify(output, null, 2)}\n`);
    console.log(`Imported ${games.length} current New York Scratch-Off games.`);
  } catch (error) {
    console.error(`New York Scratch-Off import stopped: ${error.message}`);
    process.exitCode = 1;
  }
}
