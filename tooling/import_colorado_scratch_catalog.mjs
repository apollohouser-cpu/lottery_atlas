/* Imports every game in the live Colorado Lottery Scratch catalog. */
import {readFile, writeFile} from 'node:fs/promises';

const sourceUrl =
  'https://www.coloradolottery.com/en/games/scratch/?sort_by=top_prizes_remaining';
const outputPath = process.argv[2];

const compact = (value) => String(value ?? '').replace(/<[^>]+>/g, ' ')
  .replace(/&amp;/g, '&').replace(/&#39;|&apos;/g, "'")
  .replace(/&quot;/g, '"').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ').trim();
const money = (value) => Number(compact(value).replace(/[^0-9.]/g, ''));

if (!outputPath) {
  console.error('Usage: node tooling/import_colorado_scratch_catalog.mjs OUTPUT.json');
  process.exitCode = 1;
} else try {
  const response = await fetch(sourceUrl, {
    headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'},
  });
  if (!response.ok) throw new Error(`Colorado catalog returned HTTP ${response.status}`);
  const html = await response.text();
  const games = [];
  const cards = html.matchAll(
    /<li class="pulse[^>]*>[\s\S]*?<a[^>]+href="([^"]*\/game\/[^"/]+-(\d+)\/?)"[\s\S]*?<div class="hover">([\s\S]*?)<\/div>\s*<\/a>\s*<\/li>/gi,
  );
  for (const match of cards) {
    const body = match[3];
    const name = compact(body.match(/<p class="title">([\s\S]*?)<\/p>/i)?.[1]);
    const cost = money(body.match(/Ticket Price:\s*<strong>([\s\S]*?)<\/strong>/i)?.[1]);
    const topPrize = money(body.match(/Top Prize:\s*<strong>([\s\S]*?)<\/strong>/i)?.[1]);
    const remaining = Number(compact(
      body.match(/Top Prizes Remaining:\s*<strong>([\s\S]*?)<\/strong>/i)?.[1],
    ).replace(/,/g, ''));
    if (!name || !cost || !topPrize || !Number.isInteger(remaining) || remaining < 0) {
      throw new Error(`Incomplete Colorado Scratch game ${match[2]}`);
    }
    games.push({id: match[2], name, cost, topPrize, topPrizesRemaining: remaining});
  }
  if (games.length < 80 || new Set(games.map((game) => game.id)).size !== games.length) {
    throw new Error(`Expected a complete unique Colorado catalog; found ${games.length}`);
  }
  games.sort((a, b) => a.id.localeCompare(b.id, undefined, {numeric: true}));
  const catalogs = [{state: 'Colorado', source: sourceUrl, games}];
  let previous = null;
  try { previous = JSON.parse(await readFile(outputPath, 'utf8')); } catch (_) {}
  const changed = JSON.stringify(previous?.catalogs) !== JSON.stringify(catalogs);
  const updatedAt = changed ? new Date().toISOString() :
    previous?.updatedAt ?? previous?.retrievedAt ?? new Date().toISOString();
  await writeFile(outputPath, `${JSON.stringify({
    source: 'Colorado Lottery official live Scratch catalog',
    updatedAt, retrievedAt: updatedAt,
    coverage: `All ${games.length} games displayed in the official live Colorado Lottery Scratch catalog, including price, top prize, and remaining top prizes.`,
    catalogs,
  }, null, 2)}\n`);
  console.log(`Imported ${games.length} current Colorado Scratch games.`);
} catch (error) {
  console.error(`Colorado Scratch import stopped: ${error.message}`);
  process.exitCode = 1;
}
