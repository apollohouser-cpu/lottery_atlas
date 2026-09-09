/* Imports every game in the Texas Lottery's official current Scratch list. */
import {readFile, writeFile} from 'node:fs/promises';

const sourceUrl =
  'https://www.texaslottery.com/export/sites/lottery/Games/Scratch_Offs/all.html';
const outputPath = process.argv[2];
const compact = (value) => String(value ?? '').replace(/<[^>]+>/g, ' ')
  .replace(/&amp;/g, '&').replace(/&#39;|&apos;/g, "'")
  .replace(/&quot;/g, '"').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ').trim();
const amount = (value) => Number(compact(value).replace(/[^0-9.]/g, ''));

if (!outputPath) {
  console.error('Usage: node tooling/import_texas_scratch_catalog.mjs OUTPUT.json');
  process.exitCode = 1;
} else try {
  const response = await fetch(sourceUrl, {
    headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'},
  });
  if (!response.ok) throw new Error(`Texas catalog returned HTTP ${response.status}`);
  const html = await response.text();
  const games = [];
  for (const row of html.matchAll(/<tr>([\s\S]*?)<\/tr>/gi)) {
    const cells = [...row[1].matchAll(/<td[^>]*>([\s\S]*?)<\/td>/gi)]
      .map((cell) => compact(cell[1]));
    if (cells.length !== 8 || !/^\d+$/.test(cells[0])) continue;
    const id = cells[0];
    const cost = amount(cells[2]);
    const name = cells[4];
    const topPrize = amount(cells[5]);
    const printed = Number(cells[6].replace(/,/g, ''));
    const claimed = cells[7] === '---' ? 0 : Number(cells[7].replace(/,/g, ''));
    const topPrizesRemaining = printed - claimed;
    const detailsPath = row[1].match(/href="([^"]*details\.html_[^"]+)"/i)?.[1];
    if (!id || !name || !cost || !topPrize || !Number.isInteger(printed) ||
        !Number.isInteger(claimed) || topPrizesRemaining < 0 || !detailsPath) {
      throw new Error(`Incomplete Texas Scratch game ${id}`);
    }
    games.push({id, name, cost, topPrize, topPrizesRemaining, detailsPath});
  }
  if (games.length < 70 || new Set(games.map((game) => game.id)).size !== games.length) {
    throw new Error(`Expected a complete unique Texas catalog; found ${games.length}`);
  }
  games.sort((a, b) => a.id.localeCompare(b.id, undefined, {numeric: true}));
  const catalogs = [{
    state: 'Texas', source: sourceUrl,
    games: games.map(({detailsPath: _, ...game}) => game),
  }];
  let previous = null;
  try { previous = JSON.parse(await readFile(outputPath, 'utf8')); } catch (_) {}
  const changed = JSON.stringify(previous?.catalogs) !== JSON.stringify(catalogs);
  const updatedAt = changed ? new Date().toISOString() :
    previous?.updatedAt ?? previous?.retrievedAt ?? new Date().toISOString();
  await writeFile(outputPath, `${JSON.stringify({
    source: 'Texas Lottery official current Scratch ticket list', updatedAt,
    retrievedAt: updatedAt,
    coverage: `All ${games.length} games in the official current Texas Scratch list, including price, top prize, and calculated remaining top prizes.`,
    catalogs,
  }, null, 2)}\n`);
  console.log(`Imported ${games.length} current Texas Scratch games.`);
} catch (error) {
  console.error(`Texas Scratch import stopped: ${error.message}`);
  process.exitCode = 1;
}
