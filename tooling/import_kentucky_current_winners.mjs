/*
 * Imports the Kentucky Lottery's current official "Have You Heard?" winner
 * notices. Each published notice names the prize, game, retailer, and city.
 * The official Kentucky Lottery retailer finder supplies the retailer's
 * street address and county; the U.S. Census geocoder then provides a map
 * coordinate for that exact published address. Ambiguous retailer names and
 * unmatched addresses are excluded rather than estimated.
 *
 * The notice page is a rolling current feed, not a 2024 archive. This file is
 * intentionally labelled as current coverage only until the Kentucky Lottery
 * publishes a complete historic retailer-level winner source.
 */
import {writeFile} from 'node:fs/promises';

const winnersUrl = 'https://www.kylottery.com/apps/winners/index.html';
const retailerUrl = 'https://www.kylottery.com/webhandlers/CashingAgentsInfo.xhtml';
const censusUrl = 'https://geocoding.geo.census.gov/geocoder/locations/onelineaddress';
const outputPath = process.argv[2];

if (!outputPath) {
  console.error('Usage: node tooling/import_kentucky_current_winners.mjs OUTPUT.json');
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
  const retailersForCity = async (city) => {
    const body = JSON.stringify({id: '', LocationSelect: 'City', city, CashingAgent: 'N'});
    const response = await responseText(retailerUrl, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'user-agent': 'LotteryAtlasOfficialDataBot/1.0',
      },
      body,
    });
    return JSON.parse(response).RETAILERS ?? [];
  };
  const coordinateFor = async (retailer) => {
    const address = `${retailer.ADDRESS1}, ${retailer.CITY}, KY ${retailer.ZIP}`;
    const url = new URL(censusUrl);
    url.searchParams.set('address', address);
    url.searchParams.set('benchmark', 'Public_AR_Current');
    url.searchParams.set('format', 'json');
    const json = JSON.parse(await responseText(url));
    const match = json.result?.addressMatches?.[0];
    if (!match?.coordinates || !Number.isFinite(match.coordinates.y) || !Number.isFinite(match.coordinates.x)) return null;
    return {latitude: match.coordinates.y, longitude: match.coordinates.x};
  };

  try {
    const notices = noticesFrom(await responseText(winnersUrl));
    const retailersByCity = new Map();
    const coordinateByAddress = new Map();
    const activities = [];
    const skipped = new Set();
    for (const [index, notice] of notices.entries()) {
      const cityKey = normalize(notice.city);
      if (!retailersByCity.has(cityKey)) {
        retailersByCity.set(cityKey, await retailersForCity(notice.city));
      }
      const candidates = retailersByCity.get(cityKey).filter((retailer) =>
        normalize(retailer.NAME) === normalize(notice.retailerName));
      if (candidates.length !== 1) {
        skipped.add(`${notice.retailerName} — ${notice.city}`);
        continue;
      }
      const retailer = candidates[0];
      const address = `${retailer.ADDRESS1}, ${retailer.CITY}, KY ${retailer.ZIP}`;
      if (!coordinateByAddress.has(address)) {
        coordinateByAddress.set(address, await coordinateFor(retailer));
      }
      const coordinate = coordinateByAddress.get(address);
      if (!coordinate) {
        skipped.add(`${notice.retailerName} — ${notice.city}`);
        continue;
      }
      activities.push({
        id: `ky-current-${notice.date.toISOString().slice(0, 10)}-${normalize(notice.retailerName)}-${normalize(notice.city)}-${index}`,
        ...coordinate,
        city: retailer.CITY.replace(/\b\w/g, (letter) => letter.toUpperCase()),
        county: `${retailer.COUNTY.replace(/\b\w/g, (letter) => letter.toUpperCase())} County`,
        state: 'KY',
        game: notice.game,
        gameName: notice.gameName,
        retailerName: retailer.NAME,
        retailerAddress: address,
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
      coverage: `Current rolling Kentucky Lottery retailer-level winner notices. ${activities.length} notices were matched to a single official retailer listing and an exact Census geocode. ${skipped.size} published retailer notices were excluded because an exact unique official retailer and coordinate could not be verified. This source does not represent a complete historic Kentucky winner archive.`,
      activities,
    };
    await writeFile(outputPath, `${JSON.stringify(output, null, 2)}\n`);
    console.log(`Imported ${activities.length} Kentucky current winner notices; ${skipped.size} notices were excluded.`);
  } catch (error) {
    console.error(`Kentucky current-winner import stopped: ${error.message}`);
    process.exitCode = 1;
  }
}
