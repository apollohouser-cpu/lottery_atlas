/* Imports the Minnesota Lottery's currently listed Scratch Games. */
import {readFile, writeFile} from 'node:fs/promises';

const sourceUrl = 'https://www.mnlottery.com/games/scratch';
const outputPath = process.argv[2];
if (!outputPath) {
  console.error('Usage: node tooling/import_minnesota_scratch_catalog.mjs OUTPUT.json');
  process.exitCode = 1;
} else try {
  const fetchHtml = async (url) => {
    for (let attempt = 1; attempt <= 4; attempt++) {
      try {
        const response = await fetch(url, {headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'}});
        if (response.ok) return response.text();
        if (response.status !== 429 && response.status < 500) {
          throw new Error(`${url} returned HTTP ${response.status}`);
        }
        if (attempt === 4) throw new Error(`${url} returned HTTP ${response.status}`);
        console.warn(`${url} returned HTTP ${response.status}; retrying`);
      } catch (error) {
        if (attempt === 4 || /returned HTTP (?!429|5\d\d)/.test(error.message)) throw error;
        console.warn(`${url} request attempt ${attempt} failed: ${error.message}`);
      }
      await new Promise((resolve) => setTimeout(resolve, attempt * 1000));
    }
  };
  const plain = (html) => html.replace(/<[^>]*>/g, ' ').replace(/&amp;/g, '&')
    .replace(/&nbsp;|&#160;/g, ' ').replace(/&#0?39;|&apos;/g, "'")
    .replace(/&quot;/g, '"').replace(/\s+/g, ' ').trim();
  const listing = await fetchHtml(sourceUrl);
  const cards = [...listing.matchAll(/<div class="cell game[^\"]*" data-game-id="(\d+)">([\s\S]*?)(?=<div class="cell game|<\/div>\s*<\/div>\s*<\/section>)/g)]
    .map(([, entryId, body]) => {
      const url = body.match(/<a href="(https:\/\/www\.mnlottery\.com\/games\/scratch\/[^\"]+)"/)?.[1];
      const name = plain(body.match(/<h2 class="h3 card--lottery-headline">([\s\S]*?)<\/h2>/)?.[1] ?? '');
      const cost = Number(plain(body.match(/<h3 class="h2 lottery-details">\$([^<]+)<\/h3>/)?.[1] ?? ''));
      return {entryId, url, name, cost};
    });
  if (cards.length < 30 || cards.some(({url, name, cost}) => !url || !name || !cost) ||
      new Set(cards.map(({entryId}) => entryId)).size !== cards.length) {
    throw new Error(`Minnesota Scratch listing incomplete (${cards.length} parsed)`);
  }
  const games = [];
  for (let offset = 0; offset < cards.length; offset += 3) {
    const batch = await Promise.all(cards.slice(offset, offset + 3).map(async (card) => {
      const detail = await fetchHtml(card.url);
      const prizeTable = detail.match(/<table class="bulletin-matrix-table[^\"]*">([\s\S]*?)<\/table>/)?.[1] ?? '';
      const prizeAmounts = [...prizeTable.matchAll(/<tr>\s*<td>([\s\S]*?)<\/td>/g)]
        .map(([, cell]) => Number(plain(cell).match(/\$([\d,]+)/)?.[1]?.replace(/,/g, '')))
        .filter(Number.isFinite);
      const topPrize = Math.max(0, ...prizeAmounts);
      // Ticket image filenames use the Lottery's four-digit game number.
      const imageNumber = detail.match(/(?:Full-Ticket-Images|Game-Minis|Game-Rules)\/(?:Scratch-Tickets\/|Scratch\/)?(?:MN-)?(\d{4})[-_]/)?.[1];
      if (!imageNumber || !topPrize || !detail.includes('Number of Prizes')) {
        throw new Error(`Missing official game number or top prize: ${card.url}`);
      }
      return {id: imageNumber, name: card.name, cost: card.cost, topPrize};
    }));
    games.push(...batch);
  }
  if (new Set(games.map(({id}) => id)).size !== games.length) {
    throw new Error('Minnesota Scratch listing has duplicate game numbers');
  }
  games.sort((a, b) => a.id.localeCompare(b.id));
  const catalogs = [{state: 'Minnesota', source: sourceUrl, games}];
  let previous;
  try { previous = JSON.parse(await readFile(outputPath, 'utf8')); } catch (_) {}
  const changed = JSON.stringify(previous?.catalogs) !== JSON.stringify(catalogs);
  const updatedAt = changed ? new Date().toISOString() : previous?.updatedAt ?? new Date().toISOString();
  await writeFile(outputPath, `${JSON.stringify({
    source: 'Minnesota Lottery official listed Scratch Games', updatedAt,
    retrievedAt: new Date().toISOString(),
    coverage: `All ${games.length} Scratch Games listed on the official current page; price and printed top prize, not claims or prizes remaining.`,
    catalogs,
  }, null, 2)}\n`);
  console.log(`Imported ${games.length} listed Minnesota Scratch Games.`);
} catch (error) {
  console.error(`Minnesota Scratch import stopped: ${error.message}`);
  process.exitCode = 1;
}
