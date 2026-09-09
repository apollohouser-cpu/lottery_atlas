/* Imports exact 2026 Colorado Lottery winner/store records from official reports. */
import {readFile, writeFile} from 'node:fs/promises';

const outputPath = process.argv[2];
const directoryPath = process.argv[3];
const base = 'https://www.coloradolottery.com/en/player-tools';
const games = ['powerball', 'megamillions', 'luckyforlife', 'millionaireforlife',
  'lotto', 'lottoplus', 'cash5', 'pick3', 'scratch', 'pbdoubleplay',
  'secondchancedrawing', 'contest', 'cash5ezmatch'];
const decode = (value) => String(value ?? '').replace(/&nbsp;|&#160;/gi, ' ')
  .replace(/&amp;/gi, '&').replace(/&quot;/gi, '"')
  .replace(/&#39;|&apos;|&rsquo;|&lsquo;/gi, "'")
  .replace(/&#(\d+);/g, (_, code) => String.fromCodePoint(Number(code)));
const compact = (value) => decode(value).replace(/<[^>]+>/g, ' ')
  .replace(/\s+/g, ' ').trim();
const canonical = (value) => compact(value).toUpperCase().replace(/[^A-Z0-9]/g, '');
const slug = (value) => compact(value).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const money = (value) => Number(compact(value).replace(/[^0-9.]/g, ''));
const rows = (html) => [...html.matchAll(/<tr[^>]*>([\s\S]*?)<\/tr>/gi)].map((match) =>
  [...match[1].matchAll(/<td[^>]*>([\s\S]*?)<\/td>/gi)].map((cell) => compact(cell[1])),
).filter((cells) => cells.length);
const officialHtml = async (url) => {
  const response = await fetch(url, {headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'}});
  if (!response.ok) throw new Error(`${url} returned HTTP ${response.status}`);
  return response.text();
};
const date = (value) => {
  const parsed = new Date(`${value.replace(/Sept\./i, 'Sep').replace(/\b([A-Z][a-z]{2,})\./, '$1')} 12:00:00 UTC`);
  return Number.isNaN(parsed.valueOf()) ? null : parsed;
};

if (!outputPath || !directoryPath) {
  console.error('Usage: node tooling/import_colorado_winners.mjs OUTPUT.json RETAILERS.json');
  process.exitCode = 1;
} else try {
  const directoryRoot = JSON.parse(await readFile(directoryPath, 'utf8'));
  const retailers = directoryRoot.directories?.find((item) => item.state === 'Colorado')?.retailers;
  if (!Array.isArray(retailers) || retailers.length < 2800) {
    throw new Error('Complete Colorado retailer directory is missing');
  }
  const retailerByAddress = new Map();
  for (const retailer of retailers) {
    const key = `${canonical(retailer.address)}|${canonical(retailer.city)}`;
    const list = retailerByAddress.get(key) ?? [];
    list.push(retailer); retailerByAddress.set(key, list);
  }
  const activities = []; const excluded = [];
  for (const game of games) {
    // The official Pick 3 since-start report times out server-side. Its 180-day
    // report remains a current daily supplement; the other official game
    // reports establish the complete January-to-current launch window.
    const timeframe = game === 'pick3' ? '180' : 'sincestart';
    const query = `game=${game}&timeframe=${timeframe}`;
    const [winnerHtml, storeHtml] = await Promise.all([
      officialHtml(`${base}/whos-winning/?${query}`),
      officialHtml(`${base}/winning-stores/?${query}`),
    ]);
    const stores = new Map();
    for (const cells of rows(storeHtml)) {
      if (cells.length !== 7) continue;
      const [gameName, store, address, city, zip] = cells;
      const key = `${canonical(gameName)}|${canonical(store)}|${canonical(city)}`;
      const list = stores.get(key) ?? [];
      list.push({gameName, store, address, city, zip}); stores.set(key, list);
    }
    for (const cells of rows(winnerHtml)) {
      if (cells.length !== 6) continue;
      const [gameName, winnerName, amountText, city, store, dateText] = cells;
      const won = date(dateText); const prizeAmount = money(amountText);
      if (!won || won.getUTCFullYear() !== 2026 || !prizeAmount || !store || !city) continue;
      // The official winning-stores report groups every instant ticket under
      // "Scratch", while the dated winner report retains the ticket's name.
      const storeGameName = game === 'scratch' ? 'Scratch' : gameName;
      const storeMatches = stores.get(`${canonical(storeGameName)}|${canonical(store)}|${canonical(city)}`) ?? [];
      if (storeMatches.length !== 1) {
        excluded.push({gameName, winnerName, store, city, date: dateText,
          reason: storeMatches.length ? 'Multiple exact official store rows matched' : 'No exact official store row matched'});
        continue;
      }
      const storeRow = storeMatches[0];
      let matches = retailerByAddress.get(`${canonical(storeRow.address)}|${canonical(storeRow.city)}`) ?? [];
      if (matches.length > 1) matches = matches.filter((item) => canonical(item.name) === canonical(store));
      if (matches.length !== 1) {
        excluded.push({gameName, winnerName, store, city, date: dateText,
          reason: matches.length ? 'Multiple official retailer addresses matched' : 'No official retailer address matched'});
        continue;
      }
      const retailer = matches[0];
      const gameKind = game === 'scratch' ? 'scratch-off' :
        ['powerball', 'megamillions', 'luckyforlife', 'millionaireforlife', 'pbdoubleplay'].includes(game)
          ? (game.startsWith('mega') ? 'mega-millions' : game.startsWith('power') ? 'powerball' : 'state-draw')
          : 'state-draw';
      const iso = won.toISOString();
      activities.push({
        id: `co-${iso.slice(0, 10)}-${slug(gameName)}-${slug(retailer.id)}-${slug(winnerName)}`,
        latitude: retailer.latitude, longitude: retailer.longitude,
        city: retailer.city, county: retailer.county.replace(/ County$/i, ''), state: 'CO',
        game: gameKind, gameName,
        retailerName: retailer.name,
        retailerAddress: `${retailer.address}, ${retailer.city}, CO ${retailer.postalCode}`,
        coordinateSource: retailer.coordinateSource,
        drawDate: iso, winningTickets: 1, prizeAmount,
        sourceUrl: `${base}/whos-winning/?${query}`,
        sourceLabel: `Official Colorado Lottery Who's Winning report · ${gameName} · ${dateText}`,
      });
    }
  }
  const unique = [...new Map(activities.map((item) => [item.id, item])).values()]
    .sort((a, b) => a.drawDate.localeCompare(b.drawDate));
  const months = new Set(unique.map((item) => new Date(item.drawDate).getUTCMonth() + 1));
  const latestMonth = new Date().getUTCFullYear() === 2026 ? new Date().getUTCMonth() + 1 : 12;
  if (unique.length < 300 || [...Array(latestMonth)].some((_, index) => !months.has(index + 1))) {
    throw new Error(`Only ${unique.length} qualifying Colorado records across ${months.size} months`);
  }
  let previous = null;
  try { previous = JSON.parse(await readFile(outputPath, 'utf8')); } catch (_) {}
  const changed = JSON.stringify(previous?.activities) !== JSON.stringify(unique) ||
    JSON.stringify(previous?.excluded) !== JSON.stringify(excluded);
  const updatedAt = changed ? new Date().toISOString() : previous?.updatedAt ?? new Date().toISOString();
  await writeFile(outputPath, `${JSON.stringify({
    source: "Colorado Lottery official Who's Winning, Winning Stores, and retailer API",
    sourceUrl: `${base}/whos-winning/`, updatedAt,
    sourceLastUpdated: unique.at(-1).drawDate,
    coverage: `${unique.length} exact physical retailer-level Colorado Lottery wins from January 1, 2026 through the current official report. Each dated winner row is joined to one exact official winning-store address and one exact official retailer coordinate; unmatched rows are excluded.`,
    activities: unique, excluded,
  }, null, 2)}\n`);
  console.log(`Imported ${unique.length} Colorado winner locations; excluded ${excluded.length}.`);
} catch (error) {
  console.error(`Colorado winner import stopped: ${error.message}`);
  process.exitCode = 1;
}
