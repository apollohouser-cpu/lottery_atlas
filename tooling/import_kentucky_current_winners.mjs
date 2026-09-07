/*
 * Imports the Kentucky Lottery's current official "Have You Heard?" winner
 * notices. Each published notice names the prize, game, retailer, and city.
 * The separately generated official Kentucky retailer directory supplies the
 * street address, county, and coordinate that already passed strict Census or
 * ArcGIS address verification. Ambiguous retailer names and unmatched
 * addresses are excluded rather than estimated.
 *
 * The notice page is a rolling current feed, not a 2024 archive. This file is
 * intentionally labelled as current coverage only until the Kentucky Lottery
 * publishes a complete historic retailer-level winner source.
 */
import {readFile, writeFile} from 'node:fs/promises';

const winnersUrl = 'https://www.kylottery.com/apps/winners/index.html';
const outputPath = process.argv[2];
const retailerDirectoryPath = process.argv[3];

if (!outputPath || !retailerDirectoryPath) {
  console.error(
    'Usage: node tooling/import_kentucky_current_winners.mjs OUTPUT.json RETAILERS.json',
  );
  process.exitCode = 1;
} else {
  const normalize = (value) => value.toLowerCase().replace(/&nbsp;/g, ' ')
    .replace(/[^a-z0-9]/g, '');
  const text = (value) => value.replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&')
    .replace(/&#8217;|[’]/g, "'").replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ').trim();
  const responseText = async (url, options = {}) => {
    const response = await fetch(url, {
      headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'},
      ...options,
    });
    if (!response.ok) throw new Error(`${url} returned HTTP ${response.status}`);
    return response.text();
  };
  const prizeFrom = (headline) => {
    const match = headline.match(/\$([\d,]+(?:\.\d+)?)\s*(million\b|billion\b)?/i);
    if (!match) return null;
    const amount = Number(match[1].replaceAll(',', ''));
    if (!Number.isFinite(amount)) return null;
    if (match[2]?.toLowerCase() === 'million') return amount * 1000000;
    if (match[2]?.toLowerCase() === 'billion') return amount * 1000000000;
    return amount;
  };
  const gameFrom = (headline) => {
    if (/powerball/i.test(headline)) return {game: 'powerball', gameName: 'Powerball'};
    if (/mega\s+millions/i.test(headline)) return {game: 'mega-millions', gameName: 'Mega Millions'};
    if (/scratch-?off/i.test(headline)) return {game: 'scratch-off', gameName: headline.replace(/\s+winner!?$/i, '').trim()};
    return {game: 'state-draw', gameName: headline.replace(/\s+winner!?$/i, '').trim()};
  };
  const dateFrom = (raw) => {
    const parts = raw.trim().split('.').map(Number);
    if (parts.length !== 3 || parts.some((part) => !Number.isFinite(part))) return null;
    const [month, day, year] = parts;
    return new Date(Date.UTC(2000 + year, month - 1, day, 12));
  };
  const noticesFrom = (html) => {
    const notices = [];
    const blocks = html.matchAll(/<article class="klc-grid-col-md-4[\s\S]*?<\/article>/g);
    for (const blockMatch of blocks) {
      const block = blockMatch[0];
      const date = dateFrom(text(block.match(/<h3>(.*?)<\/h3>/s)?.[1] ?? ''));
      if (!date) continue;
      const pattern = /<strong>(.*?)<\/strong><\/p>\s*<p>(.*?)<\/p>/gs;
      for (const match of block.matchAll(pattern)) {
        const headline = text(match[1]);
        const sale = text(match[2]);
        const retailer = sale.match(/ticket sold(?:\s+at)?\s+(.+?)\s+in\s+(.+?),\s*KY/i);
        const prizeAmount = prizeFrom(headline);
        if (!retailer || !prizeAmount) continue;
        notices.push({
          date,
          headline,
          prizeAmount,
          retailerName: retailer[1].trim(),
          city: retailer[2].trim(),
          ...gameFrom(headline),
        });
      }
    }
    return notices;
  };
  try {
    const notices = noticesFrom(await responseText(winnersUrl));
    const directory = JSON.parse(await readFile(retailerDirectoryPath, 'utf8'));
    const verifiedRetailers = directory.directories?.find(
      (entry) => entry.state === 'Kentucky',
    )?.retailers;
    if (!Array.isArray(verifiedRetailers) || verifiedRetailers.length < 3000) {
      throw new Error(
        'The verified Kentucky retailer directory is missing or incomplete',
      );
    }
    const retailersByNameAndCity = new Map();
    for (const retailer of verifiedRetailers) {
      const key = `${normalize(retailer.name)}|${normalize(retailer.city)}`;
      const matches = retailersByNameAndCity.get(key) ?? [];
      matches.push(retailer);
      retailersByNameAndCity.set(key, matches);
    }
    const activities = [];
    const skipped = new Set();
    for (const [index, notice] of notices.entries()) {
      const key = `${normalize(notice.retailerName)}|${normalize(notice.city)}`;
      const candidates = retailersByNameAndCity.get(key) ?? [];
      if (candidates.length !== 1) {
        skipped.add(`${notice.retailerName} — ${notice.city}`);
        continue;
      }
      const retailer = candidates[0];
      if (
        !Number.isFinite(retailer.latitude) ||
        !Number.isFinite(retailer.longitude) ||
        !retailer.coordinateSource
      ) {
        skipped.add(`${notice.retailerName} — ${notice.city}`);
        continue;
      }
      const address =
        `${retailer.address}, ${retailer.city}, KY ${retailer.postalCode}`;
      activities.push({
        id: `ky-current-${notice.date.toISOString().slice(0, 10)}-${normalize(notice.retailerName)}-${normalize(notice.city)}-${index}`,
        latitude: retailer.latitude,
        longitude: retailer.longitude,
        city: retailer.city,
        county: retailer.county,
        state: 'KY',
        game: notice.game,
        gameName: notice.gameName,
        retailerName: retailer.name,
        retailerAddress: address,
        coordinateSource: retailer.coordinateSource,
        drawDate: notice.date.toISOString(),
        winningTickets: 1,
        prizeAmount: notice.prizeAmount,
        sourceUrl: winnersUrl,
        sourceLabel: `Official Kentucky Lottery Have You Heard? · ${notice.date.toLocaleDateString('en-US', {month: 'short', day: 'numeric', year: 'numeric', timeZone: 'UTC'})}`,
      });
    }
    activities.sort((left, right) => left.id.localeCompare(right.id));
    const latest = activities.map((activity) => activity.drawDate).sort().at(-1) ?? null;
    const output = {
      source: 'Kentucky Lottery official current winner notices and retailer finder',
      updatedAt: latest,
      sourceLastUpdated: latest,
      coverage: `Current rolling Kentucky Lottery retailer-level winner notices. ${activities.length} notices were matched to one official retailer listing with a previously verified precise coordinate. ${skipped.size} published retailer notices were excluded because an exact unique official retailer and coordinate could not be verified. This source does not represent a complete historic Kentucky winner archive.`,
      activities,
    };
    await writeFile(outputPath, `${JSON.stringify(output, null, 2)}\n`);
    console.log(`Imported ${activities.length} Kentucky current winner notices; ${skipped.size} notices were excluded.`);
  } catch (error) {
    console.error(`Kentucky current-winner import stopped: ${error.message}`);
    process.exitCode = 1;
  }
}
