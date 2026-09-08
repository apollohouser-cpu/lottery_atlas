/*
 * Imports physical New York Lottery winner activity from 2024 through today.
 * Scratch-Off claims come from the official winner archive. Draw-ticket sales
 * come from official press releases. A map point is emitted only when the
 * published selling address resolves exactly to the official active-retailer
 * directory; online, unmatched, and ambiguous records are excluded.
 */
import {readFile, writeFile} from 'node:fs/promises';

const winnersApiUrl =
  'https://nylottery.ny.gov/drupal-api/api/winners?_format=json';
const pressApiUrl =
  'https://nylottery.ny.gov/drupal-api/api/press?_format=json';
const sourceUrl = 'https://nylottery.ny.gov/winners/';
const outputPath = process.argv[2];
const retailerDirectoryPath = process.argv[3];
const scratchCatalogPath = process.argv[4];

if (!outputPath || !retailerDirectoryPath || !scratchCatalogPath) {
  console.error(
    'Usage: node tooling/import_new_york_winners.mjs OUTPUT.json RETAILERS.json SCRATCH.json',
  );
  process.exitCode = 1;
} else {
  const decodeEntities = (value) => String(value ?? '')
    .replace(/&nbsp;|&#160;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&quot;/gi, '"')
    .replace(/&#39;|&apos;|&rsquo;|&lsquo;/gi, "'")
    .replace(/&ldquo;|&rdquo;/gi, '"')
    .replace(/&ndash;|&mdash;/gi, '-')
    .replace(/&#(\d+);/g, (_, code) => String.fromCodePoint(Number(code)));
  const compact = (value) => decodeEntities(value)
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  const paragraphs = (html) => decodeEntities(html)
    .replace(/<\/(?:p|li|div)>/gi, '\n')
    .replace(/<br\s*\/?>/gi, '\n')
    .replace(/<[^>]+>/g, ' ')
    .split(/\n|•/)
    .map((line) => line.replace(/\s+/g, ' ').trim())
    .filter(Boolean);
  const canonical = (value) => compact(value).toLowerCase()
    .normalize('NFKD').replace(/[\u0300-\u036f]/g, '')
    .replace(/\b(north)\b/g, 'n')
    .replace(/\b(south)\b/g, 's')
    .replace(/\b(east)\b/g, 'e')
    .replace(/\b(west)\b/g, 'w')
    .replace(/\b(avenue|ave\.)\b/g, 'ave')
    .replace(/\b(street|st\.)\b/g, 'st')
    .replace(/\b(road|rd\.)\b/g, 'rd')
    .replace(/\b(boulevard|blvd\.)\b/g, 'blvd')
    .replace(/\b(highway|hwy\.)\b/g, 'hwy')
    .replace(/\b(parkway|pkwy\.)\b/g, 'pkwy')
    .replace(/\b(turnpike|tpke\.)\b/g, 'tpke')
    .replace(/\b(route|rte\.)\b/g, 'route')
    .replace(/\b(place|pl\.)\b/g, 'pl')
    .replace(/\b(lane|ln\.)\b/g, 'ln')
    .replace(/\b(drive|dr\.)\b/g, 'dr')
    .replace(/\b(court|ct\.)\b/g, 'ct')
    .replace(/\b(center|ctr\.)\b/g, 'ctr')
    .replace(/\b(plaza|plz\.)\b/g, 'plz')
    .replace(/\b(mount)\b/g, 'mt')
    .replace(/\b(saint)\b/g, 'st')
    .replace(/[^a-z0-9]/g, '');
  const withoutUnit = (value) => compact(value).replace(
    /(?:\s|,)+(?:ste|suite|unit|bldg|building|#)\s*[a-z0-9-]*.*$/i,
    '',
  );
  const slug = (value) => compact(value).toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
  const numberFromWord = (value) => ({
    one: 1,
    two: 2,
    three: 3,
    four: 4,
    five: 5,
    six: 6,
  })[compact(value).toLowerCase()] ?? (Number(value) || 1);
  const money = (value) => {
    const match = compact(value).replaceAll(',', '').match(
      /\$?([\d.]+)\s*(billion|million|thousand|[bmk])?/i,
    );
    if (!match) return null;
    const multipliers = {
      billion: 1e9,
      b: 1e9,
      million: 1e6,
      m: 1e6,
      thousand: 1e3,
      k: 1e3,
    };
    const amount = Number(match[1]) *
      (multipliers[match[2]?.toLowerCase()] ?? 1);
    return Number.isFinite(amount) && amount > 0 ? Math.round(amount) : null;
  };
  const prizeForWinner = (entry) => {
    const unit = compact(entry.prize_type).toLowerCase();
    const value = Number(entry.prize);
    if (Number.isFinite(value) && value > 0) {
      if (unit.includes('billion')) return Math.round(value * 1e9);
      if (unit.includes('million')) return Math.round(value * 1e6);
      if (unit.includes('thousand')) return Math.round(value * 1e3);
      if (/dollar|cash|^$/.test(unit)) return Math.round(value);
    }
    return money(entry.title) ?? money(entry.body);
  };
  const bodyStrings = (value, key = '') => {
    if (typeof value === 'string') return key === 'body' ? [value] : [];
    if (Array.isArray(value)) return value.flatMap((item) => bodyStrings(item, key));
    if (!value || typeof value !== 'object') return [];
    return Object.entries(value).flatMap(([childKey, child]) =>
      bodyStrings(child, childKey));
  };
  const fetchJson = async (url) => {
    let lastError;
    for (let attempt = 1; attempt <= 5; attempt++) {
      try {
        const response = await fetch(url, {
          headers: {
            accept: 'application/json',
            'user-agent': 'LotteryAtlasOfficialDataBot/1.0',
          },
        });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        return await response.json();
      } catch (error) {
        lastError = error;
        if (attempt < 5) {
          await new Promise((resolve) => setTimeout(resolve, attempt * 900));
        }
      }
    }
    throw new Error(`${url} failed: ${lastError.message}`);
  };
  const archiveSince2024 = async (baseUrl) => {
    const first = await fetchJson(`${baseUrl}&page=0`);
    const totalPages = Number(first.pager?.total_pages);
    if (!Array.isArray(first.rows) || !Number.isInteger(totalPages) || totalPages < 1) {
      throw new Error(`${baseUrl} did not return a complete official pager`);
    }
    const rows = [...first.rows];
    let stopped = first.rows.some((entry) => String(entry.date) < '2024-01-01');
    for (let start = 1; start < totalPages && !stopped; start += 5) {
      const pages = Array.from(
        {length: Math.min(5, totalPages - start)},
        (_, index) => start + index,
      );
      const payloads = await Promise.all(
        pages.map((page) => fetchJson(`${baseUrl}&page=${page}`)),
      );
      for (const payload of payloads) {
        if (!Array.isArray(payload.rows)) {
          throw new Error(`${baseUrl} returned an invalid archive page`);
        }
        rows.push(...payload.rows);
        if (payload.rows.some((entry) => String(entry.date) < '2024-01-01')) {
          stopped = true;
          break;
        }
      }
    }
    return rows.filter((entry) => String(entry.date) >= '2024-01-01');
  };
  const gameFrom = (content, scratchGames) => {
    const full = compact(content);
    if (/mega\s+millions/i.test(full)) {
      return {game: 'mega-millions', gameName: 'Mega Millions'};
    }
    if (/power\s*ball/i.test(full)) {
      return {game: 'powerball', gameName: 'Powerball'};
    }
    const drawPatterns = [
      ['Millionaire for Life', /millionaire\s+for\s+life/i],
      ['Cash4Life', /cash\s*4\s*life/i],
      ['LOTTO', /(?:new york\s+)?lotto/i],
      ['Take 5', /take\s*5/i],
      ['NUMBERS', /\bnumbers\b/i],
      ['Win4', /\bwin\s*4\b/i],
      ['Pick 10', /\bpick\s*10\b/i],
      ['Quick Draw', /\bquick\s+draw\b/i],
      ['Money Dots', /\bmoney\s+dots\b/i],
    ];
    if (/scratch(?:er|-?off)|scratch ticket/i.test(full)) {
      const normalized = canonical(full);
      const exact = scratchGames
        .map((game) => ({...game, canonicalName: canonical(game.name)}))
        .filter((game) => game.canonicalName.length >= 5 &&
          normalized.includes(game.canonicalName))
        .sort((left, right) => right.canonicalName.length - left.canonicalName.length)[0];
      const named = full.match(
        /(?:lottery[’']?s\s+|on\s+(?:the\s+)?)(.+?)\s+scratch(?:er|-?off)(?:\s+game|\s+ticket)?/i,
      );
      return {
        game: 'scratch-off',
        gameName: exact?.name ?? compact(named?.[1] ?? 'New York Scratch-Off'),
      };
    }
    for (const [gameName, pattern] of drawPatterns) {
      if (pattern.test(full)) return {game: 'state-draw', gameName};
    }
    return null;
  };
  const officialDate = (entry, content) => {
    const publication = new Date(`${entry.date}T12:00:00Z`);
    if (Number.isNaN(publication.valueOf())) return null;
    const match = compact(content).match(
      /(?:for|in|from)\s+the\s+([A-Z][a-z]{2,8})\s+(\d{1,2})(?:,\s*(\d{4}))?\s+drawing/i,
    );
    if (!match) return publication.toISOString();
    const explicitYear = Number(match[3]);
    let year = Number.isInteger(explicitYear) && explicitYear >= 2024
      ? explicitYear
      : publication.getUTCFullYear();
    let candidate = new Date(`${match[1]} ${match[2]}, ${year} 12:00:00 UTC`);
    if (!match[3] && candidate.valueOf() > publication.valueOf() + 31 * 86400000) {
      year--;
      candidate = new Date(`${match[1]} ${match[2]}, ${year} 12:00:00 UTC`);
    }
    return Number.isNaN(candidate.valueOf()) ? publication.toISOString() : candidate.toISOString();
  };
  const sellingLocationFrom = (line) => {
    const match = compact(line).match(
      /(?:ticket\s+was\s+|tickets\s+were\s+)?(?:purchased|sold)\s+at:?\s*(.+?)\s+located\s+at\s+(.+?)\s+(?:in|on)\s+(?:the\s+)?(.+?)(?=,\s*(?:which|where|that)|\s+(?:which|where|that)\b|[.]?$)/i,
    ) ?? compact(line).match(
      /^(.+?)\s+located\s+at\s+(.+?)\s+(?:in|on)\s+(?:the\s+)?(.+?)(?=,\s*(?:which|where|that)|\s+(?:which|where|that)\b|[.]?$)/i,
    );
    if (!match) return null;
    return {
      name: compact(match[1]),
      address: compact(match[2]),
      city: compact(match[3]).replace(/[.,]+$/, ''),
    };
  };

  try {
    const directory = JSON.parse(await readFile(retailerDirectoryPath, 'utf8'));
    const retailers = directory.directories?.find(
      (entry) => entry.state === 'New York',
    )?.retailers;
    if (!Array.isArray(retailers) || retailers.length < 12000) {
      throw new Error('The complete verified New York retailer directory is missing');
    }
    const scratchRoot = JSON.parse(await readFile(scratchCatalogPath, 'utf8'));
    const scratchGames = scratchRoot.catalogs?.find(
      (entry) => entry.state === 'New York',
    )?.games;
    if (!Array.isArray(scratchGames) || scratchGames.length < 80) {
      throw new Error('The complete New York Scratch-Off catalog is missing');
    }

    const retailersByStreet = new Map();
    for (const retailer of retailers) {
      const street = canonical(withoutUnit(retailer.address));
      const matches = retailersByStreet.get(street) ?? [];
      matches.push({
        ...retailer,
        canonicalName: canonical(retailer.name),
        canonicalCity: canonical(retailer.city),
      });
      retailersByStreet.set(street, matches);
    }
    const exactRetailer = (location) => {
      const candidates = retailersByStreet.get(canonical(withoutUnit(location.address))) ?? [];
      if (candidates.length === 0) return {status: 'unmatched'};
      const city = canonical(location.city);
      const cityAliases = new Set([city]);
      if (city === 'manhattan') cityAliases.add('newyork');
      const byCity = candidates.filter((retailer) => cityAliases.has(retailer.canonicalCity));
      let narrowed = byCity.length > 0 ? byCity : candidates;
      const name = canonical(location.name);
      const byName = narrowed.filter((retailer) =>
        retailer.canonicalName === name ||
        retailer.canonicalName.includes(name) ||
        name.includes(retailer.canonicalName));
      if (byName.length > 0) narrowed = byName;
      const physicalLocations = new Map(narrowed.map((retailer) => [
        [retailer.latitude, retailer.longitude, retailer.canonicalName].join('|'),
        retailer,
      ]));
      return physicalLocations.size === 1
        ? {status: 'matched', retailer: [...physicalLocations.values()][0]}
        : {status: 'ambiguous'};
    };

    const [winnerEntries, pressEntries] = await Promise.all([
      archiveSince2024(winnersApiUrl),
      archiveSince2024(pressApiUrl),
    ]);
    const activities = [];
    let unmatchedExcluded = 0;
    let ambiguousExcluded = 0;
    let onlineExcluded = 0;
    let nonWinnerExcluded = 0;

    for (const entry of winnerEntries) {
      const content = `${entry.title} ${compact(entry.body)}`;
      const game = gameFrom(content, scratchGames);
      // Official press releases cover physical draw-ticket sales at the time
      // of the drawing. The winner archive is used for Scratch-Off claims so
      // a later draw-game claim cannot double-count the same ticket.
      if (game?.game !== 'scratch-off') continue;
      if (/\bonline\b|ny lottery app|subscription/i.test(content)) {
        onlineExcluded++;
        continue;
      }
      const line = paragraphs(entry.body).find((item) =>
        /(?:purchased|sold)\s+at/i.test(item) && /located\s+at/i.test(item));
      const location = sellingLocationFrom(line);
      const prizeAmount = prizeForWinner(entry);
      if (!location || !prizeAmount) {
        nonWinnerExcluded++;
        continue;
      }
      const match = exactRetailer(location);
      if (match.status === 'unmatched') {
        unmatchedExcluded++;
        continue;
      }
      if (match.status === 'ambiguous') {
        ambiguousExcluded++;
        continue;
      }
      const retailer = match.retailer;
      const publicationDate = new Date(`${entry.date}T12:00:00Z`).toISOString();
      activities.push({
        id: `ny-winner-${slug(entry.nid)}-${retailer.id}`,
        latitude: retailer.latitude,
        longitude: retailer.longitude,
        city: retailer.city,
        county: retailer.county,
        state: 'NY',
        game: game.game,
        gameName: game.gameName,
        retailerName: retailer.name,
        retailerAddress:
          `${retailer.address}, ${retailer.city}, NY ${retailer.postalCode}`,
        coordinateSource: retailer.coordinateSource,
        drawDate: publicationDate,
        winningTickets: 1,
        prizeAmount,
        sourceUrl:
          `https://nylottery.ny.gov/winner/?alias=${encodeURIComponent(
            compact(entry.alias).split('/').filter(Boolean).at(-1),
          )}`,
        sourceLabel: `Official New York Lottery winner claim · ${entry.date}`,
      });
    }

    for (const entry of pressEntries) {
      const bodies = bodyStrings(entry.sections);
      const content = `${entry.title} ${bodies.map(compact).join(' ')}`;
      const game = gameFrom(content, scratchGames);
      if (!game || game.game === 'scratch-off') continue;
      for (const line of bodies.flatMap(paragraphs)) {
        if (!/located\s+at/i.test(line)) continue;
        const location = sellingLocationFrom(line);
        const prizeMatch = line.match(
          /(?:worth|prize(?:-winning)?\s+(?:ticket\s+)?(?:of|worth))\s+(\$[\d,.]+(?:\s*(?:billion|million|thousand|[bmk]))?)/i,
        );
        const prizeAmount = money(prizeMatch?.[1]);
        if (!location || !prizeAmount) {
          nonWinnerExcluded++;
          continue;
        }
        const match = exactRetailer(location);
        if (match.status === 'unmatched') {
          unmatchedExcluded++;
          continue;
        }
        if (match.status === 'ambiguous') {
          ambiguousExcluded++;
          continue;
        }
        const retailer = match.retailer;
        const drawDate = officialDate(entry, content);
        if (!drawDate || drawDate < '2024-01-01') continue;
        const winningTicketsMatch = line.match(
          /(?:sold|with)\s+(one|two|three|four|five|six|\d+)\s+(?:prize-)?winning\s+(?:tickets|plays)/i,
        );
        activities.push({
          id: `ny-press-${slug(entry.nid)}-${retailer.id}`,
          latitude: retailer.latitude,
          longitude: retailer.longitude,
          city: retailer.city,
          county: retailer.county,
          state: 'NY',
          game: game.game,
          gameName: game.gameName,
          retailerName: retailer.name,
          retailerAddress:
            `${retailer.address}, ${retailer.city}, NY ${retailer.postalCode}`,
          coordinateSource: retailer.coordinateSource,
          drawDate,
          winningTickets: numberFromWord(winningTicketsMatch?.[1]),
          prizeAmount,
          sourceUrl: `https://nylottery.ny.gov/press/${entry.nid}`,
          sourceLabel: `Official New York Lottery winning-ticket release · ${entry.date}`,
        });
      }
    }

    const uniqueActivities = [...new Map(activities.map((activity) => [
      activity.id,
      activity,
    ])).values()];
    const duplicateLinesExcluded = activities.length - uniqueActivities.length;
    activities.splice(0, activities.length, ...uniqueActivities);
    activities.sort((left, right) => left.id.localeCompare(right.id));
    const currentYear = new Date().getUTCFullYear();
    const years = Array.from(
      {length: currentYear - 2024 + 1},
      (_, index) => 2024 + index,
    );
    const activityYears = new Set(
      activities.map((activity) => new Date(activity.drawDate).getUTCFullYear()),
    );
    const scratchCount = activities.filter(
      (activity) => activity.game === 'scratch-off',
    ).length;
    const drawCount = activities.length - scratchCount;
    if (
      activities.length < 300 || scratchCount < 40 || drawCount < 200 ||
      !years.every((year) => activityYears.has(year))
    ) {
      throw new Error(
        `Insufficient verified activity: ${activities.length} total, ` +
        `${scratchCount} Scratch-Off, ${drawCount} draw, years ` +
        `${[...activityYears].sort().join(', ')}`,
      );
    }
    const latest = activities.map((activity) => activity.drawDate).sort().at(-1);
    const sourceLastUpdated = [...winnerEntries, ...pressEntries]
      .map((entry) => `${entry.date}T12:00:00.000Z`)
      .sort()
      .at(-1);
    const output = {
      source:
        'New York Lottery official winner archive, press releases, and active retailer directory',
      updatedAt: latest,
      sourceLastUpdated,
      coverage:
        `${activities.length} exact retailer-level winner records from 2024 through ` +
        `${currentYear}: ${scratchCount} physical Scratch-Off claims and ${drawCount} ` +
        'draw-game winning-ticket releases. Every point matched one exact active ' +
        'official retailer address and precise coordinate. ' +
        `${onlineExcluded} online-only claims, ${unmatchedExcluded} unmatched addresses, ` +
        `${ambiguousExcluded} ambiguous addresses, ${nonWinnerExcluded} records ` +
        `without a complete physical selling location or prize, and ` +
        `${duplicateLinesExcluded} duplicate source lines were excluded rather than ` +
        'inferred or counted twice. Winner-claim dates use the official publication date; draw ' +
        'releases use the published drawing date when present.',
      activities,
    };
    await writeFile(outputPath, `${JSON.stringify(output, null, 2)}\n`);
    console.log(
      `Imported ${activities.length} New York winner records: ` +
      `${scratchCount} Scratch-Off and ${drawCount} draw-game points.`,
    );
  } catch (error) {
    console.error(`New York winner import stopped: ${error.message}`);
    process.exitCode = 1;
  }
}
