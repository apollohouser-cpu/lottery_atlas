/*
 * Imports Virginia Lottery winner/news records from 2024 through today.
 * A heat-map record is emitted only when the official article publishes a
 * physical selling location and that address resolves to exactly one entry
 * in the separately imported, precisely geocoded official retailer
 * directory. Online-only wins, news releases, closed/unmatched retailers,
 * and ambiguous shared-address directory entries are excluded.
 */
import {readFile, writeFile} from 'node:fs/promises';

const winnersApiUrl = 'https://www.valottery.com/api/v1/latestwinners';
const sourceUrl = 'https://www.valottery.com/winnersnews/latestwinners';
const outputPath = process.argv[2];
const retailerDirectoryPath = process.argv[3];

if (!outputPath || !retailerDirectoryPath) {
  console.error(
    'Usage: node tooling/import_virginia_winners.mjs OUTPUT.json RETAILERS.json',
  );
  process.exitCode = 1;
} else {
  const decodeEntities = (value) => String(value ?? '')
    .replace(/&nbsp;|&#160;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&quot;/gi, '"')
    .replace(/&#39;|&apos;|&rsquo;/gi, "'")
    .replace(/&ldquo;|&rdquo;/gi, '"')
    .replace(/&ndash;|&mdash;/gi, '-')
    .replace(/&#(\d+);/g, (_, code) => String.fromCodePoint(Number(code)));
  const text = (value) => decodeEntities(value)
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  const compact = (value) => text(value).replace(/\s+/g, ' ').trim();
  const withoutUnit = (value) => compact(value).replace(
    /(?:\s|,)+(?:ste|suite|unit|bldg|building|#)\s*[a-z0-9-]*.*$/i,
    '',
  );
  const canonicalAddress = (value) => text(value).toLowerCase()
    .replace(/\b(hwy|hwy\.)\b/g, 'highway')
    .replace(/\b(rd|rd\.)\b/g, 'road')
    .replace(/\b(st|st\.)\b/g, 'street')
    .replace(/\b(ave|ave\.)\b/g, 'avenue')
    .replace(/\b(blvd|blvd\.)\b/g, 'boulevard')
    .replace(/\b(pkwy|pkwy\.)\b/g, 'parkway')
    .replace(/\b(ln|ln\.)\b/g, 'lane')
    .replace(/\b(dr|dr\.)\b/g, 'drive')
    .replace(/\b(rt|rte)\b/g, 'route')
    .replace(/\b(tpke|tnpk)\b/g, 'turnpike')
    .replace(/\bctr\b/g, 'center')
    .replace(/\bshpg\b/g, 'shopping')
    .replace(/\bsq\b/g, 'square')
    .replace(/[^a-z0-9]/g, '');
  const slug = (value) => text(value).toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '');
  const isOnlineOnly = (entry, body) => {
    const opening = `${entry.Title} ${body.slice(0, 1800)}`;
    return (
      /\bonline\b/i.test(entry.Title) ||
      /\b(?:bought|purchased|played)[^.]{0,100}\bonline\b/i.test(opening) ||
      /\bonline game\b/i.test(opening) ||
      /\bon (?:his|her|their) personal device\b/i.test(opening)
    );
  };
  const gameFrom = (entry, body, scratchGames) => {
    const content = `${entry.Title} ${body}`;
    if (/mega\s+millions/i.test(content)) {
      return {game: 'mega-millions', gameName: 'Mega Millions'};
    }
    if (/powerball/i.test(content)) {
      return {game: 'powerball', gameName: 'Powerball'};
    }
    const drawPatterns = [
      ['Millionaire for Life', /millionaire\s+for\s+life/i],
      ['Cash4Life', /cash\s*4\s*life/i],
      ['Bank a Million', /bank\s+a\s+million/i],
      ['Cash 5 with EZ Match', /cash\s*5(?:\s+with\s+ez\s+match)?/i],
      ['Cash Pop', /cash\s+pop/i],
      ['Pick 5', /pick\s*5/i],
      ['Pick 4', /pick\s*4/i],
      ['Pick 3', /pick\s*3/i],
      ["Virginia's New Year's Millionaire Raffle", /new year'?s millionaire raffle/i],
      ['Keno', /\bkeno\b/i],
    ];
    for (const [gameName, pattern] of drawPatterns) {
      if (pattern.test(content)) return {game: 'state-draw', gameName};
    }
    const normalizedContent = content.toLowerCase().replace(/[^a-z0-9]/g, '');
    const scratch = scratchGames.find((game) => {
      const name = game.name.toLowerCase().replace(/[^a-z0-9]/g, '');
      return name.length >= 5 && normalizedContent.includes(name);
    });
    if (scratch) return {game: 'scratch-off', gameName: scratch.name};
    const titleMatch = entry.Title.match(
      /(?:top prize in|playing|in)\s+(.+?)(?:\s+scratcher(?:\s+game)?|\s+game|[.!]|$)/i,
    );
    return {
      game: 'scratch-off',
      gameName: compact(titleMatch?.[1] ?? 'Virginia Scratcher'),
    };
  };
  const fetchYear = async (year) => {
    const response = await fetch(winnersApiUrl, {
      method: 'POST',
      headers: {
        'content-type': 'application/json',
        'user-agent': 'LotteryAtlasOfficialDataBot/1.0',
      },
      body: JSON.stringify({
        page: 0,
        totalPages: 0,
        pageSize: 5000,
        keyword: '',
        year: String(year),
        specificYear: 0,
        specificWinner: '',
        QueryString: '',
      }),
    });
    if (!response.ok) throw new Error(`${year} archive returned HTTP ${response.status}`);
    const payload = await response.json();
    if (!Array.isArray(payload.data) || payload.totalPages !== 1) {
      throw new Error(`${year} archive did not return one complete official page`);
    }
    return payload.data;
  };

  try {
    const directory = JSON.parse(await readFile(retailerDirectoryPath, 'utf8'));
    const verifiedRetailers = directory.directories?.find(
      (entry) => entry.state === 'Virginia',
    )?.retailers;
    if (!Array.isArray(verifiedRetailers) || verifiedRetailers.length < 5000) {
      throw new Error('The verified Virginia retailer directory is missing or incomplete');
    }
    const scratchCatalog = JSON.parse(
      await readFile('data/virginia_scratch_catalog.generated.json', 'utf8'),
    );
    const scratchGames = scratchCatalog.catalogs?.find(
      (entry) => entry.state === 'Virginia',
    )?.games ?? [];

    const retailersByHouseNumber = new Map();
    for (const retailer of verifiedRetailers) {
      const houseNumber = retailer.address.match(/^\d+[A-Z-]*/i)?.[0]?.toLowerCase();
      if (!houseNumber) continue;
      const matches = retailersByHouseNumber.get(houseNumber) ?? [];
      matches.push({
        ...retailer,
        canonicalStreet: canonicalAddress(withoutUnit(retailer.address)),
      });
      retailersByHouseNumber.set(houseNumber, matches);
    }

    const currentYear = new Date().getUTCFullYear();
    const years = Array.from({length: currentYear - 2024 + 1}, (_, index) => 2024 + index);
    const entries = (await Promise.all(years.map(fetchYear))).flat();
    const activities = [];
    let onlineExcluded = 0;
    let unmatchedExcluded = 0;
    let ambiguousExcluded = 0;
    for (const entry of entries) {
      if (!Number.isFinite(entry.Prize) || entry.Prize <= 0) continue;
      const body = text(entry.BodyHtml);
      if (isOnlineOnly(entry, body)) {
        onlineExcluded++;
        continue;
      }
      const canonicalBody = canonicalAddress(body);
      const houseNumbers = new Set(
        [...body.matchAll(/\b\d{1,6}[A-Z-]?\b/g)].map((match) =>
          match[0].toLowerCase()),
      );
      const matches = [];
      for (const houseNumber of houseNumbers) {
        for (const retailer of retailersByHouseNumber.get(houseNumber) ?? []) {
          if (
            retailer.canonicalStreet.length >= 8 &&
            canonicalBody.includes(retailer.canonicalStreet)
          ) matches.push(retailer);
        }
      }
      const uniqueMatches = [...new Map(matches.map((retailer) => [
        retailer.id,
        retailer,
      ])).values()];
      if (uniqueMatches.length === 0) {
        unmatchedExcluded++;
        continue;
      }
      if (uniqueMatches.length !== 1) {
        ambiguousExcluded++;
        continue;
      }
      const retailer = uniqueMatches[0];
      const publicationDate = new Date(`${entry.PublicationDate}Z`);
      if (Number.isNaN(publicationDate.valueOf())) {
        throw new Error(`Invalid official publication date for ${entry.Id}`);
      }
      const winningTicketsMatch = entry.Title.match(
        /(?:with|from)\s+(\d+)\s+winning\s+(?:tickets|plays)/i,
      );
      const winningTickets = Number(winningTicketsMatch?.[1] ?? 1);
      const game = gameFrom(entry, body, scratchGames);
      const articleUrl = `${sourceUrl}?itemId=${encodeURIComponent(entry.Id)}`;
      activities.push({
        id: `va-${publicationDate.toISOString().slice(0, 10)}-${slug(entry.Id)}`,
        latitude: retailer.latitude,
        longitude: retailer.longitude,
        city: retailer.city,
        county: retailer.county,
        state: 'VA',
        game: game.game,
        gameName: game.gameName,
        retailerName: retailer.name,
        retailerAddress:
          `${retailer.address}, ${retailer.city}, VA ${retailer.postalCode}`,
        coordinateSource: retailer.coordinateSource,
        drawDate: publicationDate.toISOString(),
        winningTickets,
        prizeAmount: Math.round(entry.Prize),
        sourceUrl: articleUrl,
        sourceLabel:
          `Official Virginia Lottery winner release · ${entry.PublicationDateFormatted}`,
      });
    }
    activities.sort((left, right) => left.id.localeCompare(right.id));
    const activityYears = new Set(
      activities.map((activity) => new Date(activity.drawDate).getUTCFullYear()),
    );
    if (activities.length < 90 || !years.every((year) => activityYears.has(year))) {
      throw new Error(
        `Insufficient verified 2024-current activity: ${activities.length} records, ` +
        `years ${[...activityYears].sort().join(', ')}`,
      );
    }
    const latest = activities.map((activity) => activity.drawDate).sort().at(-1);
    const output = {
      source:
        'Virginia Lottery official Latest Winners archive and statewide retailer finder',
      updatedAt: latest,
      sourceLastUpdated: latest,
      coverage:
        `${activities.length} physical retailer-level winner releases from 2024 ` +
        `through ${currentYear}, each matched to exactly one official Virginia Lottery ` +
        'retailer address with a previously verified precise coordinate. ' +
        `${onlineExcluded} online-only releases, ${unmatchedExcluded} releases without ` +
        'an exact current-directory address match, and ' +
        `${ambiguousExcluded} shared-address matches were excluded rather than inferred. ` +
        'drawDate stores the official publication timestamp because the archive does not ' +
        'publish a structured draw/claim date for every record.',
      activities,
    };
    await writeFile(outputPath, `${JSON.stringify(output, null, 2)}\n`);
    console.log(
      `Imported ${activities.length} Virginia physical winner releases; ` +
      `${onlineExcluded} online, ${unmatchedExcluded} unmatched, and ` +
      `${ambiguousExcluded} ambiguous releases excluded.`,
    );
  } catch (error) {
    console.error(`Virginia winner import stopped: ${error.message}`);
    process.exitCode = 1;
  }
}
