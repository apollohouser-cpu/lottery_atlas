/*
 * Imports 2026 Ohio Lottery physical retailer-level winner releases.
 * A map point is emitted only when the official article contains an address
 * that uniquely matches the official active-retailer directory.
 */
import {readFile, writeFile} from 'node:fs/promises';

const loginUrl =
  'https://authapi-solutions.ohiolottery.com/1.0/Authentication/Login';
const articlesUrl =
  'https://api-solutions.ohiolottery.com/1.0/Games/Article/GetByDateRangeAndCategory';
const applicationUrl = 'https://www.ohiolottery.com/dist/js/app.js';
const sourceUrl = 'https://www.ohiolottery.com/about/media-center/press-releases';
const outputPath = process.argv[2];
const retailerDirectoryPath = process.argv[3];
const scratchCatalogPath = process.argv[4];

if (!outputPath || !retailerDirectoryPath || !scratchCatalogPath) {
  console.error(
    'Usage: node tooling/import_ohio_winners.mjs OUTPUT.json RETAILERS.json SCRATCH.json',
  );
  process.exitCode = 1;
} else {
  const decode = (value) => String(value ?? '')
    .replace(/&nbsp;|&#160;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&quot;/gi, '"')
    .replace(/&#39;|&apos;|&rsquo;|&lsquo;/gi, "'")
    .replace(/&ldquo;|&rdquo;/gi, '"')
    .replace(/&ndash;|&mdash;/gi, '-')
    .replace(/&#(\d+);/g, (_, code) => String.fromCodePoint(Number(code)));
  const compact = (value) => decode(value)
    .replace(/<br\s*\/?>/gi, ' ')
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();
  const canonical = (value) => compact(value).toLowerCase()
    .normalize('NFKD').replace(/[\u0300-\u036f]/g, '')
    .replace(/\b(north)\b/g, 'n').replace(/\b(south)\b/g, 's')
    .replace(/\b(east)\b/g, 'e').replace(/\b(west)\b/g, 'w')
    .replace(/\b(avenue|ave)\b/g, 'ave').replace(/\b(street|st)\b/g, 'st')
    .replace(/\b(road|rd)\b/g, 'rd').replace(/\b(boulevard|blvd)\b/g, 'blvd')
    .replace(/\b(highway|hwy)\b/g, 'hwy').replace(/\b(route|rte)\b/g, 'route')
    .replace(/\b(lane|ln)\b/g, 'ln').replace(/\b(drive|dr)\b/g, 'dr')
    .replace(/\b(court|ct)\b/g, 'ct').replace(/\b(parkway|pkwy)\b/g, 'pkwy')
    .replace(/[^a-z0-9]/g, '');
  const slug = (value) => compact(value).toLowerCase()
    .replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
  const moneyValues = (value) => {
    const values = [];
    const expression = /\$\s*([\d,.]+)\s*(billion|million|thousand|[bmk]\b)?/gi;
    for (const match of compact(value).matchAll(expression)) {
      const multiplier = {
        billion: 1e9, b: 1e9, million: 1e6, m: 1e6,
        thousand: 1e3, k: 1e3,
      }[match[2]?.toLowerCase()] ?? 1;
      const amount = Number(match[1].replaceAll(',', '')) * multiplier;
      if (Number.isFinite(amount) && amount > 0) values.push(Math.round(amount));
    }
    return values;
  };
  const prizeFrom = (article) => {
    const titleValues = moneyValues(article.title);
    if (titleValues.length) return Math.max(...titleValues);
    const text = compact(article.content).split(/after mandatory|after federal|after taxes/i)[0];
    const clauses = text.split(/(?<=[.!?])\s+/).filter(
      (part) => /\b(won|winner|winning|worth|prize|jackpot)\b/i.test(part),
    );
    const values = clauses.flatMap(moneyValues).filter((amount) => amount >= 1000);
    // Official releases commonly mention the much larger current multi-state
    // jackpot later in the story. The first qualifying winner clause carries
    // the prize for the retailer-level event represented by this record.
    return values.length ? values[0] : null;
  };
  const gameFrom = (article, scratchGames) => {
    const text = `${compact(article.title)} ${compact(article.content)}`;
    if (/power\s*ball/i.test(text)) return {game: 'powerball', gameName: 'Powerball'};
    if (/mega\s+millions/i.test(text)) {
      return {game: 'mega-millions', gameName: 'Mega Millions'};
    }
    const scratch = /scratch(?:er|-?off)|scratch ticket/i.test(text);
    if (scratch) {
      const normalized = canonical(text);
      const exact = scratchGames
        .map((entry) => ({...entry, key: canonical(entry.name)}))
        .filter((entry) => entry.key.length >= 5 && normalized.includes(entry.key))
        .sort((left, right) => right.key.length - left.key.length)[0];
      const named = text.match(
        /(?:purchased|bought|playing|won\s+on|thanks\s+to|ticket\s+was)\s+(?:a|an|the)?\s*(?:\$[\d,.]+\s+)?(.{3,60}?)\s+scratch(?:er|-?off)/i,
      );
      return {
        game: 'scratch-off',
        gameName: exact?.name ?? compact(named?.[1] ?? 'Ohio Scratch-Off'),
      };
    }
    const draws = [
      ['Millionaire for Life', /millionaire\s+for\s+life/i],
      ['Lucky for Life', /lucky\s+for\s+life/i],
      ['Rolling Cash 5', /rolling\s+(?:cash\s+)?5/i],
      ['Classic Lotto', /classic\s+lotto/i],
      ['Pick 5', /pick\s*5/i], ['Pick 4', /pick\s*4/i],
      ['Pick 3', /pick\s*3/i], ['KENO', /\bkeno\b/i],
      ['EZPLAY', /\bezplay\b/i], ['Cash Explosion', /cash\s+explosion/i],
    ];
    for (const [gameName, expression] of draws) {
      if (expression.test(text)) return {game: 'state-draw', gameName};
    }
    return null;
  };
  const responseJson = async (url, options = {}) => {
    const response = await fetch(url, {
      ...options,
      headers: {
        'user-agent': 'LotteryAtlasOfficialDataBot/1.0',
        ...(options.headers ?? {}),
      },
    });
    if (!response.ok) throw new Error(`${url} returned HTTP ${response.status}`);
    return response.json();
  };
  const apiToken = async () => {
    const application = await (await fetch(applicationUrl, {
      headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'},
    })).text();
    const credentials = application.match(
      /getNewAPItoken\(\)\{let \w="([^"]+)",\w="([^"]+)"/,
    );
    if (!credentials) throw new Error('Ohio public API credentials were unavailable');
    const payload = await responseJson(loginUrl, {
      method: 'POST',
      headers: {'content-type': 'application/json-patch+json'},
      body: JSON.stringify({userName: credentials[1], password: credentials[2]}),
    });
    if (!payload.data?.token) throw new Error('Ohio public API token was unavailable');
    return payload.data.token;
  };
  const existingOutput = async () => {
    try { return JSON.parse(await readFile(outputPath, 'utf8')); } catch (_) { return null; }
  };

  try {
    const directoryRoot = JSON.parse(await readFile(retailerDirectoryPath, 'utf8'));
    const retailers = directoryRoot.directories?.find(
      (entry) => entry.state === 'Ohio',
    )?.retailers;
    if (!Array.isArray(retailers) || retailers.length < 9000) {
      throw new Error('The complete verified Ohio retailer directory is missing');
    }
    const scratchRoot = JSON.parse(await readFile(scratchCatalogPath, 'utf8'));
    const scratchGames = scratchRoot.catalogs?.find(
      (entry) => entry.state === 'Ohio',
    )?.games;
    if (!Array.isArray(scratchGames) || scratchGames.length < 60) {
      throw new Error('The complete Ohio Scratch-Off catalog is missing');
    }

    const byAddress = new Map();
    for (const retailer of retailers) {
      const key = canonical(retailer.address);
      if (key.length < 5) continue;
      const matches = byAddress.get(key) ?? [];
      matches.push(retailer);
      byAddress.set(key, matches);
    }
    const bearer = await apiToken();
    const now = new Date();
    const endMonth = now.getUTCFullYear() === 2026 ? now.getUTCMonth() + 1 : 12;
    const articles = [];
    for (let month = 1; month <= endMonth; month++) {
      const dateFrom = `2026-${String(month).padStart(2, '0')}-01`;
      const monthEnd = new Date(Date.UTC(2026, month, 0));
      const dateTo = month === endMonth && now.getUTCFullYear() === 2026
        ? now.toISOString().slice(0, 10)
        : monthEnd.toISOString().slice(0, 10);
      const url = new URL(articlesUrl);
      url.searchParams.set('dateFrom', dateFrom);
      url.searchParams.set('dateTo', dateTo);
      url.searchParams.set('category', 'PressRelease');
      const payload = await responseJson(url, {
        headers: {authorization: `Bearer ${bearer}`},
      });
      if (!Array.isArray(payload.data)) {
        throw new Error(`Ohio press releases were unavailable for ${dateFrom}`);
      }
      articles.push(...payload.data);
    }

    const activities = [];
    const excluded = [];
    for (const article of articles) {
      const text = compact(article.content);
      const normalized = canonical(text);
      const game = gameFrom(article, scratchGames);
      const prizeAmount = prizeFrom(article);
      if (!game || !prizeAmount || !/\b(won|winner|winning|jackpot|prize)\b/i.test(text)) {
        excluded.push({articleID: article.articleID, title: compact(article.title), reason: 'Not a mappable winner release'});
        continue;
      }
      const addressMatches = [];
      for (const [address, candidates] of byAddress) {
        if (normalized.includes(address)) addressMatches.push(...candidates);
      }
      const uniqueById = [...new Map(addressMatches.map((item) => [item.id, item])).values()];
      let matches = uniqueById;
      if (matches.length > 1) {
        matches = matches.filter((retailer) => normalized.includes(canonical(retailer.name)));
      }
      if (matches.length !== 1) {
        excluded.push({
          articleID: article.articleID,
          title: compact(article.title),
          reason: matches.length ? 'Multiple official retailers matched' : 'No exact official retailer address matched',
        });
        continue;
      }
      const retailer = matches[0];
      const publication = new Date(`${article.date}Z`);
      if (Number.isNaN(publication.valueOf())) {
        throw new Error(`Invalid official publication date for article ${article.articleID}`);
      }
      // The API's nodeAlias field is capped at 50 characters. Capped aliases
      // are not public routes, so retain the official press-release archive as
      // the source URL and preserve the exact release title in sourceLabel.
      const alias = String(article.nodeAlias ?? '');
      const articlePage = alias.length < 49 && !/\(\d+\)$/.test(alias)
        ? `${sourceUrl}/${article.nodeAlias}`
        : sourceUrl;
      activities.push({
        id: `oh-${publication.toISOString().slice(0, 10)}-${article.articleID}-${slug(retailer.id)}`,
        latitude: retailer.latitude,
        longitude: retailer.longitude,
        city: retailer.city,
        county: retailer.county.replace(/\s+County$/i, ''),
        state: 'OH',
        ...game,
        retailerName: retailer.name,
        retailerAddress: `${retailer.address}, ${retailer.city}, OH ${retailer.postalCode}`,
        coordinateSource: retailer.coordinateSource,
        drawDate: publication.toISOString(),
        winningTickets: 1,
        prizeAmount,
        sourceUrl: articlePage,
        sourceLabel: `Official Ohio Lottery winner release · ${compact(article.title)} · ${publication.toLocaleDateString('en-US', {month: 'short', day: '2-digit', year: 'numeric', timeZone: 'UTC'})}`,
      });
    }
    activities.sort((left, right) => left.drawDate.localeCompare(right.drawDate));
    if (activities.length < 80) {
      throw new Error(`Only ${activities.length} exact Ohio winner locations qualified`);
    }
    const existing = await existingOutput();
    const contentChanged = JSON.stringify(existing?.activities) !== JSON.stringify(activities) ||
      JSON.stringify(existing?.excluded) !== JSON.stringify(excluded);
    const updatedAt = contentChanged
      ? new Date().toISOString()
      : existing?.updatedAt ?? new Date().toISOString();
    const latest = activities.at(-1)?.drawDate;
    await writeFile(outputPath, `${JSON.stringify({
      source: 'Ohio Lottery official press release API and active retailer directory',
      sourceUrl,
      updatedAt,
      sourceLastUpdated: latest,
      coverage:
        `${activities.length} physical retailer-level Ohio Lottery winner releases ` +
        'from January 1, 2026 through the current official publication date, each ' +
        'matched to exactly one active official retailer address. Publication time is ' +
        'used when the article does not publish a separate structured claim date.',
      activities,
      excluded,
    }, null, 2)}\n`);
    console.log(
      `Imported ${activities.length} Ohio winner locations; excluded ${excluded.length}.`,
    );
  } catch (error) {
    console.error(`Ohio winner import stopped: ${error.message}`);
    process.exitCode = 1;
  }
}
