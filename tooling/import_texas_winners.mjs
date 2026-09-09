/* Imports exact 2026 Texas Scratch top-prize selling retailers. */
import {readFile, writeFile} from 'node:fs/promises';

const catalogPath = process.argv[2];
const directoryPath = process.argv[3];
const outputPath = process.argv[4];
const base = 'https://www.texaslottery.com';
const compact = (value) => String(value ?? '').replace(/<[^>]+>/g, ' ')
  .replace(/&amp;/g, '&').replace(/&#39;|&apos;/g, "'").replace(/&nbsp;/g, ' ')
  .replace(/\s+/g, ' ').trim();
const canonical = (value) => compact(value).toUpperCase().replace(/[^A-Z0-9]/g, '');
const slug = (value) => compact(value).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const date = (value) => {
  const match = value.match(/^(\d{2})\/(\d{2})\/(\d{2})$/);
  return match ? new Date(Date.UTC(2000 + Number(match[3]), Number(match[1]) - 1, Number(match[2]), 12)) : null;
};

if (!catalogPath || !directoryPath || !outputPath) {
  console.error('Usage: node tooling/import_texas_winners.mjs CATALOG.json RETAILERS.json OUTPUT.json');
  process.exitCode = 1;
} else try {
  const catalogRoot = JSON.parse(await readFile(catalogPath, 'utf8'));
  const games = catalogRoot.catalogs?.find((item) => item.state === 'Texas')?.games;
  const directoryRoot = JSON.parse(await readFile(directoryPath, 'utf8'));
  const retailers = directoryRoot.directories?.find((item) => item.state === 'Texas')?.retailers;
  if (!Array.isArray(games) || games.length < 70 || !Array.isArray(retailers) || retailers.length < 10000) {
    throw new Error('Complete Texas catalog or retailer directory is missing');
  }
  const byAddress = new Map();
  for (const retailer of retailers) {
    const key = `${canonical(retailer.address)}|${canonical(retailer.city)}|${retailer.postalCode}`;
    const list = byAddress.get(key) ?? []; list.push(retailer); byAddress.set(key, list);
  }
  const currentHtml = await (await fetch(
    'https://www.texaslottery.com/export/sites/lottery/Games/Scratch_Offs/all.html',
    {headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'}},
  )).text();
  const detailsByGame = new Map([...currentHtml.matchAll(
    /href="([^"]*details\.html_([^"]+))"[^>]*>(\d+)<\/a>/gi,
  )].map((match) => [match[3], match[1].replace('details.html_', 'retailerswhosoldtopprizes.html_')]));
  const activities = []; const excluded = [];
  let next = 0;
  const worker = async () => {
    while (next < games.length) {
      const game = games[next++]; const path = detailsByGame.get(game.id);
      if (!path) continue;
      const sourceUrl = new URL(path, base).toString();
      const response = await fetch(sourceUrl, {headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'}});
      // Texas creates this report only after a top prize has been fully
      // processed. A 404 therefore means there is no qualifying location yet.
      if (response.status === 404) continue;
      if (!response.ok) throw new Error(`Texas game ${game.id} report returned HTTP ${response.status}`);
      const html = await response.text();
      for (const match of html.matchAll(/<tr>([\s\S]*?)<\/tr>/gi)) {
        const cells = [...match[1].matchAll(/<td[^>]*>([\s\S]*?)<\/td>/gi)].map((cell) => compact(cell[1]));
        if (cells.length !== 7) continue;
        const claimed = date(cells[0]);
        if (!claimed || claimed.getUTCFullYear() !== 2026) continue;
        const [_, name, address, city, zip] = cells;
        let candidates = byAddress.get(`${canonical(address)}|${canonical(city)}|${compact(zip).slice(0, 5)}`) ?? [];
        if (candidates.length > 1) candidates = candidates.filter((row) => canonical(row.name) === canonical(name));
        if (candidates.length !== 1) {
          excluded.push({gameId: game.id, gameName: game.name, date: cells[0], retailerName: name,
            retailerAddress: address, city, postalCode: zip,
            reason: candidates.length ? 'Multiple exact official retailer rows matched' : 'No exact geocoded official retailer row matched'});
          continue;
        }
        const retailer = candidates[0]; const iso = claimed.toISOString();
        activities.push({
          id: `tx-${iso.slice(0, 10)}-${game.id}-${slug(retailer.id)}-${slug(cells[5])}-${slug(cells[6])}`,
          latitude: retailer.latitude, longitude: retailer.longitude, city: retailer.city,
          county: retailer.county.replace(/ County$/i, ''), state: 'TX', game: 'scratch-off',
          gameName: game.name, retailerName: retailer.name,
          retailerAddress: `${retailer.address}, ${retailer.city}, TX ${retailer.postalCode}`,
          coordinateSource: retailer.coordinateSource, drawDate: iso, winningTickets: 1,
          prizeAmount: game.topPrize, sourceUrl,
          sourceLabel: `Official Texas Lottery top-prize selling retailer · Game ${game.id} · ${cells[0]}`,
        });
      }
    }
  };
  await Promise.all(Array.from({length: 8}, worker));
  const unique = [...new Map(activities.map((item) => [item.id, item])).values()]
    .sort((a, b) => a.drawDate.localeCompare(b.drawDate));
  if (unique.length < 100) throw new Error(`Only ${unique.length} exact 2026 Texas winners qualified`);
  let previous = null;
  try { previous = JSON.parse(await readFile(outputPath, 'utf8')); } catch (_) {}
  const changed = JSON.stringify(previous?.activities) !== JSON.stringify(unique) ||
    JSON.stringify(previous?.excluded) !== JSON.stringify(excluded);
  const updatedAt = changed ? new Date().toISOString() : previous?.updatedAt ?? new Date().toISOString();
  await writeFile(outputPath, `${JSON.stringify({
    source: 'Texas Lottery official Scratch top-prize selling-retailer reports',
    sourceUrl: 'https://www.texaslottery.com/export/sites/lottery/Games/Scratch_Offs/all.html',
    updatedAt, sourceLastUpdated: unique.at(-1).drawDate,
    coverage: `${unique.length} exact physical retailer-level 2026 Texas Scratch top-prize claims. Every record joins one official dated selling-store address to the official statewide retailer roster; unmatched or ungeocoded rows are excluded.`,
    activities: unique, excluded,
  }, null, 2)}\n`);
  console.log(`Imported ${unique.length} Texas winner locations; excluded ${excluded.length}.`);
} catch (error) {
  console.error(`Texas winner import stopped: ${error.message}`); process.exitCode = 1;
}
