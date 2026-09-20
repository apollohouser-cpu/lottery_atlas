/* Imports current Oregon Scratch-its; inventory is not winner activity. */
import {readFile, writeFile} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';
import {fetchSourceJson} from './source_json_fetch.mjs';
const sourceUrl = 'https://www.oregonlottery.org/scratch-its/list/';
const apiUrl = 'https://api.oregonlottery.org/gameinfo/v1/instant/games?count=1000';
const headers = {
  // These credentials are published by the official public Scratch-it page.
  client_id: 'a007b1b3898e4f87aea756e5a9f327f2',
  client_secret: '09D194c317Ee4E20b260784aD9d57e92',
  'user-agent': 'LotteryAtlasOfficialDataBot/1.0',
};

function calendarDate(value) {
  if (typeof value !== 'string' || !/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}$/.test(value)) {
    throw new Error('Missing or invalid official game date');
  }
  const day = value.slice(0, 10);
  const parsed = new Date(`${day}T00:00:00Z`);
  if (!Number.isFinite(parsed.valueOf()) || parsed.toISOString().slice(0, 10) !== day) {
    throw new Error('Invalid calendar date');
  }
  return day;
}

export function parseOregonCatalog(body, today) {
  calendarDate(`${today}T00:00:00`);
  if (!Array.isArray(body?.InstantGames) || body.NextItems !== 0 || body.InstantGames.length >= 1000) {
    throw new Error('Incomplete Oregon API response or unhandled pagination');
  }
  const ids = new Set();
  const games = [];
  for (const row of body.InstantGames) {
    if (!row || typeof row.GameNumber !== 'string' || !/^\d+$/.test(row.GameNumber) || ids.has(row.GameNumber)) {
      throw new Error('Missing or duplicate official game number');
    }
    ids.add(row.GameNumber);
    const start = calendarDate(row.DateAvailable);
    const end = row.GameEndDate ? calendarDate(row.GameEndDate) : null;
    if (end && end < start) throw new Error('Game end precedes availability');
    if (start > today || (end && end <= today)) continue;
    if (typeof row.GameNameTitle !== 'string' || !row.GameNameTitle.trim() ||
        !Number.isSafeInteger(row.TicketPrice) || row.TicketPrice <= 0 ||
        !Number.isSafeInteger(row.TopPrize) || row.TopPrize <= 0 ||
        !Number.isSafeInteger(row.TopPrizesRemaining) || row.TopPrizesRemaining < 0) {
      throw new Error('Invalid current game name, price or prize inventory');
    }
    const redeem = row.ValidationEndDate ? calendarDate(row.ValidationEndDate) : null;
    if (redeem && (redeem < start || (end && redeem < end))) throw new Error('Invalid redemption deadline');
    games.push({stateName: 'Oregon', id: row.GameNumber, name: row.GameNameTitle.trim(),
      cost: row.TicketPrice, topPrize: row.TopPrize, topPrizesRemaining: row.TopPrizesRemaining,
      startDate: start, ...(end ? {gameEndDate: end} : {}), ...(redeem ? {lastDayToRedeem: redeem} : {}),
      inventoryNote: `Retrieved ${today}; source updates daily, publication timestamp unavailable. Remaining means unclaimed, not store stock.${redeem ? ` Redeem by ${redeem}.` : ''}`,
    });
  }
  if (!games.length) throw new Error('No current Oregon games');
  games.sort((a, b) => a.id.localeCompare(b.id, undefined, {numeric: true}));
  return {state: 'Oregon', source: sourceUrl, retrievedDate: today, sourceDate: null,
    updateCadence: 'Source updates once daily; checked every six hours.',
    coverage: 'API-listed Scratch-its available by retrieval date and before their game end date. Unclaimed top prizes only, not claims, all-tier winning tickets or retailer availability.', games};
}

async function main(outputPath) {
  if (!outputPath) throw new Error('Usage: node tooling/import_oregon_scratch_catalog.mjs OUTPUT.json');
  const body = await fetchSourceJson(apiUrl, {fetchImpl: (url, options) =>
    fetch(url, {...options, headers: {...options.headers, ...headers}})});
  const today = new Intl.DateTimeFormat('en-CA', {timeZone: 'America/Los_Angeles'}).format(new Date());
  const catalog = parseOregonCatalog(body, today);
  if (catalog.games.length < 20) throw new Error('Unexpectedly small current Oregon catalog');
  let previous;
  try { previous = JSON.parse(await readFile(outputPath, 'utf8')); } catch (error) {
    if (error.code !== 'ENOENT') throw error;
  }
  const catalogs = [catalog];
  const updatedAt = JSON.stringify(previous?.catalogs) === JSON.stringify(catalogs)
    ? previous.updatedAt : new Date().toISOString();
  await writeFile(outputPath, `${JSON.stringify({source: 'Oregon Lottery official Scratch-it inventory', updatedAt, catalogs}, null, 2)}\n`);
  console.log(`Validated ${catalog.games.length} current Oregon Scratch-its.`);
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main(process.argv[2]).catch(error => {console.error(`Oregon Scratch import stopped: ${error.message}`); process.exitCode = 1;});
}
