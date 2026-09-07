/*
 * Imports retailer-level Kentucky winners retained on official Kentucky
 * Lottery pages for 2024 and 2025. Only a winner whose published retailer
 * name resolves to exactly one precisely geocoded entry in the official
 * statewide directory is emitted. The retained pages are not a complete
 * claims archive, so the output states its limited coverage explicitly.
 */
import {readFile, writeFile} from 'node:fs/promises';

const krogerWinnersUrl =
  'https://www.kylottery.com/apps/landingpages/KrogerLanding';
const historyUrl =
  'https://www.kylottery.com/apps/about_us/news.html';
const outputPath = process.argv[2];
const retailerDirectoryPath = process.argv[3];

if (!outputPath || !retailerDirectoryPath) {
  console.error(
    'Usage: node tooling/import_kentucky_historical_winners.mjs OUTPUT.json RETAILERS.json',
  );
  process.exitCode = 1;
} else {
  const decodeEntities = (value) => value
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&quot;/gi, '"')
    .replace(/&#39;|&apos;/gi, "'")
    .replace(/&#8217;|&rsquo;/gi, '’')
    .replace(/&#(\d+);/g, (_, code) => String.fromCodePoint(Number(code)));
  const text = (value) => decodeEntities(value)
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  const normalize = (value) => text(value).toLowerCase()
    .replace(/[^a-z0-9]/g, '');
  const slug = (value) => text(value).toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
  const responseText = async (url) => {
    const response = await fetch(url, {
      headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'},
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
    if (/powerball/i.test(headline)) {
      return {game: 'powerball', gameName: 'Powerball'};
    }
    if (/mega\s+millions/i.test(headline)) {
      return {game: 'mega-millions', gameName: 'Mega Millions'};
    }
    if (/scratch-?off/i.test(headline)) {
      const name = headline
        .replace(/^\$[\d,]+(?:\.\d+)?\s+/, '')
        .replace(/\s+scratch-?off\s+winner!?\s*$/i, '')
        .trim();
      return {game: 'scratch-off', gameName: name};
    }
    return {
      game: 'state-draw',
      gameName: headline.replace(/\s+winner!?\s*$/i, '').trim(),
    };
  };
  const dotDate = (raw) => {
    const [month, day, year] = raw.split('.').map(Number);
    if (![month, day, year].every(Number.isFinite)) return null;
    return new Date(Date.UTC(2000 + year, month - 1, day, 12));
  };
  const namedDate = (raw) => {
    const parsed = new Date(`${raw.replace('.', '')} 12:00:00 UTC`);
    return Number.isNaN(parsed.valueOf()) ? null : parsed;
  };

  try {
    const directory = JSON.parse(await readFile(retailerDirectoryPath, 'utf8'));
    const verifiedRetailers = directory.directories?.find(
      (entry) => entry.state === 'Kentucky',
    )?.retailers;
    if (!Array.isArray(verifiedRetailers) || verifiedRetailers.length < 3000) {
      throw new Error(
        'The verified Kentucky retailer directory is missing or incomplete',
      );
    }
    const retailersByName = new Map();
    for (const retailer of verifiedRetailers) {
      const key = normalize(retailer.name);
      const matches = retailersByName.get(key) ?? [];
      matches.push(retailer);
      retailersByName.set(key, matches);
    }

    const candidates = [];
    const krogerHtml = await responseText(krogerWinnersUrl);
    const krogerPattern = /<h3[^>]*>[\s\S]*?(\d{1,2}\.\d{1,2}\.\d{2})[\s\S]*?<\/h3>\s*<p[^>]*>([\s\S]*?)<\/p>\s*<p[^>]*>([\s\S]*?)<\/p>/g;
    for (const match of krogerHtml.matchAll(krogerPattern)) {
      const date = dotDate(match[1]);
      if (!date || date.getUTCFullYear() !== 2024) continue;
      const headline = text(match[2]);
      const sale = text(match[3]);
      const retailerMatch = sale.match(/Ticket sold at (.+?) in (.+?),\s*KY/i);
      const prizeAmount = prizeFrom(headline);
      if (!retailerMatch || prizeAmount === null) continue;
      candidates.push({
        date,
        headline,
        prizeAmount,
        retailerName: retailerMatch[1].trim(),
        city: retailerMatch[2].trim(),
        sourceUrl: krogerWinnersUrl,
        ...gameFrom(headline),
      });
    }

    const historyText = text(await responseText(historyUrl));
    const historyMatch = historyText.match(
      /Friday,\s*([A-Z][a-z]{2}\.\s+\d{1,2},\s+2025)[\s\S]{0,250}?\$([\d,]+)\s+winning\s+([A-Za-z ]+?)\s+ticket[\s\S]{0,100}?purchased at\s+(.+?)\s+in\s+(.+?),\s*Ky\./i,
    );
    if (historyMatch) {
      const date = namedDate(historyMatch[1]);
      const prizeAmount = Number(historyMatch[2].replaceAll(',', ''));
      const headline = `$${historyMatch[2]} ${historyMatch[3]} Winner`;
      if (date && Number.isFinite(prizeAmount)) {
        candidates.push({
          date,
          headline,
          prizeAmount,
          retailerName: historyMatch[4].trim(),
          city: historyMatch[5].trim(),
          sourceUrl: historyUrl,
          ...gameFrom(headline),
        });
      }
    }

    const activities = [];
    const skipped = [];
    for (const candidate of candidates) {
      const retailers = retailersByName.get(normalize(candidate.retailerName)) ?? [];
      if (retailers.length !== 1) {
        skipped.push(`${candidate.retailerName} — ${candidate.city}`);
        continue;
      }
      const retailer = retailers[0];
      if (
        !Number.isFinite(retailer.latitude) ||
        !Number.isFinite(retailer.longitude) ||
        !retailer.coordinateSource
      ) {
        skipped.push(`${candidate.retailerName} — ${candidate.city}`);
        continue;
      }
      const day = candidate.date.toISOString().slice(0, 10);
      activities.push({
        id: `ky-retained-${day}-${slug(candidate.retailerName)}-${slug(candidate.gameName)}`,
        latitude: retailer.latitude,
        longitude: retailer.longitude,
        city: retailer.city,
        county: retailer.county,
        state: 'KY',
        game: candidate.game,
        gameName: candidate.gameName,
        retailerName: retailer.name,
        retailerAddress:
          `${retailer.address}, ${retailer.city}, KY ${retailer.postalCode}`,
        coordinateSource: retailer.coordinateSource,
        drawDate: candidate.date.toISOString(),
        winningTickets: 1,
        prizeAmount: candidate.prizeAmount,
        sourceUrl: candidate.sourceUrl,
        sourceLabel:
          `Official Kentucky Lottery retained winner listing · ${day}`,
      });
    }
    activities.sort((left, right) => left.id.localeCompare(right.id));
    if (activities.length < 8) {
      throw new Error(
        `Expected at least 8 retained 2024–2025 winners, verified ${activities.length}; ` +
        `unmatched: ${skipped.join(', ') || 'none'}`,
      );
    }
    const latest = activities.map((activity) => activity.drawDate).sort().at(-1);
    const output = {
      source:
        'Kentucky Lottery official retained 2024–2025 retailer winner listings',
      updatedAt: latest,
      sourceLastUpdated: latest,
      coverage:
        `${activities.length} retailer-level winners retained on official Kentucky ` +
        'Lottery pages for 2024–2025, each matched to one precisely geocoded official ' +
        'directory retailer. These retained pages are not a complete claims archive.',
      activities,
    };
    await writeFile(outputPath, `${JSON.stringify(output, null, 2)}\n`);
    console.log(
      `Imported ${activities.length} retained Kentucky 2024–2025 winners; ` +
      `${skipped.length} ambiguous entries excluded.`,
    );
  } catch (error) {
    console.error(`Kentucky historical-winner import stopped: ${error.message}`);
    process.exitCode = 1;
  }
}
