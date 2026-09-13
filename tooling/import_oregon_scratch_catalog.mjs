/* Imports every currently for-sale Scratch-it from the Oregon Lottery API. */
import {readFile, writeFile} from 'node:fs/promises';

const sourceUrl = 'https://www.oregonlottery.org/scratch-its/list/';
const apiUrl = 'https://api.oregonlottery.org/gameinfo/v1/instant/games?count=1000';
const outputPath = process.argv[2];

const headers = {
  // These credentials are published by the official public Scratch-it page.
  client_id: 'a007b1b3898e4f87aea756e5a9f327f2',
  client_secret: '09D194c317Ee4E20b260784aD9d57e92',
  'user-agent': 'LotteryAtlasOfficialDataBot/1.0',
};

if (!outputPath) {
  console.error('Usage: node tooling/import_oregon_scratch_catalog.mjs OUTPUT.json');
  process.exitCode = 1;
} else try {
  const response = await fetch(apiUrl, {headers});
  if (!response.ok) throw new Error(`Oregon Scratch API returned HTTP ${response.status}`);
  const body = await response.json();
  const today = new Date();
  const games = (body.InstantGames ?? []).filter((game) => {
    const available = new Date(game.DateAvailable);
    const ended = game.GameEndDate ? new Date(game.GameEndDate) : null;
    return Number.isFinite(available.valueOf()) && available <= today && (!ended || ended > today);
  }).map((game) => ({
    id: String(game.GameNumber), name: String(game.GameNameTitle ?? '').trim(),
    cost: Number(game.TicketPrice), topPrize: Number(game.TopPrize),
    topPrizesRemaining: Number(game.TopPrizesRemaining),
  }));
  if (games.length < 20 || games.some((game) => !game.id || !game.name || !game.cost ||
      !game.topPrize || !Number.isInteger(game.topPrizesRemaining) || game.topPrizesRemaining < 0) ||
      new Set(games.map((game) => game.id)).size !== games.length) {
    throw new Error(`Oregon Scratch catalog was incomplete (${games.length} games)`);
  }
  games.sort((a, b) => a.id.localeCompare(b.id, undefined, {numeric: true}));
  const catalogs = [{state: 'Oregon', source: sourceUrl, games}];
  let previous; try { previous = JSON.parse(await readFile(outputPath, 'utf8')); } catch (_) {}
  const changed = JSON.stringify(previous?.catalogs) !== JSON.stringify(catalogs);
  const updatedAt = changed ? new Date().toISOString() : previous?.updatedAt ?? new Date().toISOString();
  await writeFile(outputPath, `${JSON.stringify({
    source: 'Oregon Lottery official current Scratch-it catalog', updatedAt, retrievedAt: updatedAt,
    coverage: `All ${games.length} currently for-sale Oregon Lottery Scratch-its with official price, top prize, and remaining top-prize count.`, catalogs,
  }, null, 2)}\n`);
  console.log(`Imported ${games.length} current Oregon Scratch-its.`);
} catch (error) {
  console.error(`Oregon Scratch import stopped: ${error.message}`);
  process.exitCode = 1;
}
