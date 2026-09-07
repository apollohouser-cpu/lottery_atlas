/*
 * Imports every retail Scratcher currently returned by the Virginia
 * Lottery's official Scratcher Search API. The API publishes ticket price,
 * advertised top prize, and the current unclaimed top-prize count. Detail
 * pages are also checked so a malformed summary cannot silently enter the
 * catalog.
 */
import {readFile, writeFile} from 'node:fs/promises';

const apiUrl = 'https://www.valottery.com/api/v1/scratchers';
const sourceUrl = 'https://www.valottery.com/scratcher-search';
const outputPath = process.argv[2];

if (!outputPath) {
  console.error(
    'Usage: node tooling/import_virginia_scratch_catalog.mjs OUTPUT.json',
  );
  process.exitCode = 1;
} else {
  const compact = (value) => String(value ?? '').replace(/\s+/g, ' ').trim();
  const money = (value) => {
    const normalized = compact(value).replaceAll(',', '').replaceAll('*', '');
    const match = normalized.match(/\$?([\d.]+)\s*([KMB])?/i);
    if (!match) return null;
    const amount = Number(match[1]);
    const multiplier = {K: 1e3, M: 1e6, B: 1e9}[match[2]?.toUpperCase()] ?? 1;
    const result = amount * multiplier;
    return Number.isFinite(result) ? Math.round(result) : null;
  };
  const integer = (value) => {
    const result = Number(String(value ?? '').replaceAll(',', '').trim());
    return Number.isInteger(result) && result >= 0 ? result : null;
  };
  const responseText = async (url, options = {}) => {
    let lastError;
    for (let attempt = 1; attempt <= 3; attempt++) {
      try {
        const response = await fetch(url, {
          headers: {
            'user-agent': 'LotteryAtlasOfficialDataBot/1.0',
            ...options.headers,
          },
          ...options,
        });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        return response.text();
      } catch (error) {
        lastError = error;
        if (attempt < 3) {
          await new Promise((resolve) => setTimeout(resolve, attempt * 500));
        }
      }
    }
    throw new Error(`${url} failed: ${lastError.message}`);
  };
  const officialGames = async () => {
    const raw = await responseText(apiUrl, {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({
        page: 0,
        totalPages: 0,
        pageSize: 5000,
        filters: {prices: [], categories: []},
      }),
    });
    const payload = JSON.parse(raw);
    if (!Array.isArray(payload.data) || payload.totalPages !== 1) {
      throw new Error('Official Scratcher API returned an incomplete result');
    }
    // The endpoint also exposes free event-only promotional games. Their
    // detail pages explicitly say they are not available at retail, so they
    // do not belong in the retail Scratcher catalog.
    return payload.data.filter((game) => {
      const price = money(game.TicketPrice);
      return price !== null && price > 0;
    });
  };
  const detailTopPrize = (html) => {
    const body = html.match(/<table[^>]*scratcher-prize-table[\s\S]*?<tbody>([\s\S]*?)<\/tbody>/i)?.[1];
    const row = body?.match(/<tr>([\s\S]*?)<\/tr>/i)?.[1];
    const cells = row
      ? [...row.matchAll(/<td[^>]*>([\s\S]*?)<\/td>/gi)].map((match) =>
          compact(match[1].replace(/<[^>]+>/g, ' ')))
      : [];
    if (cells.length < 3) return null;
    return {amount: money(cells[0]), remaining: integer(cells[2])};
  };
  const restoreExistingOutput = async () => {
    try {
      return JSON.parse(await readFile(outputPath, 'utf8'));
    } catch (_) {
      return null;
    }
  };

  try {
    const summaries = await officialGames();
    if (summaries.length < 80) {
      throw new Error(`Only ${summaries.length} current Scratchers were returned`);
    }

    const details = new Array(summaries.length);
    let nextGame = 0;
    const worker = async () => {
      while (nextGame < summaries.length) {
        const index = nextGame++;
        details[index] = detailTopPrize(
          await responseText(`https://www.valottery.com/scratchers/${summaries[index].GameID}`),
        );
      }
    };
    await Promise.all(Array.from({length: 8}, worker));

    const games = summaries.map((summary, index) => {
      const id = compact(summary.GameID);
      const name = compact(summary.Title);
      const cost = money(summary.TicketPrice);
      const topPrize = money(summary.TopPrize);
      const remaining = integer(summary.PayoutNumber);
      if (!id || !name || !cost || topPrize === null || remaining === null) {
        throw new Error(`Incomplete official Scratcher summary for game ${id || '?'}`);
      }
      const detail = details[index];
      if (
        detail &&
        ((detail.amount !== null && detail.amount !== topPrize) ||
          (detail.remaining !== null && detail.remaining !== remaining))
      ) {
        throw new Error(`Summary/detail disagreement for Virginia Scratcher #${id}`);
      }
      return {
        id,
        name,
        cost,
        topPrize,
        topPrizesRemaining: remaining,
        ...(compact(summary.TopPrize) !== `$${topPrize.toLocaleString('en-US')}`
          ? {topPrizeLabel: compact(summary.TopPrize)}
          : {}),
      };
    }).sort((left, right) => left.id.localeCompare(right.id));

    if (new Set(games.map((game) => game.id)).size !== games.length) {
      throw new Error('Official Scratcher API returned duplicate game numbers');
    }

    const catalogs = [{state: 'Virginia', source: sourceUrl, games}];
    const existing = await restoreExistingOutput();
    const catalogChanged =
      JSON.stringify(existing?.catalogs ?? null) !== JSON.stringify(catalogs);
    const updatedAt = catalogChanged
      ? new Date().toISOString()
      : existing.updatedAt ?? existing.retrievedAt;
    const output = {
      source: 'Virginia Lottery official Scratcher Search API and game details',
      updatedAt,
      retrievedAt: updatedAt,
      coverage:
        `All ${games.length} retail Scratchers returned by the official Virginia ` +
        'Lottery search API. Price, top prize, and current unclaimed top-prize ' +
        'count were validated against each official game detail page.',
      catalogs,
    };
    await writeFile(outputPath, `${JSON.stringify(output, null, 2)}\n`);
    console.log(`Imported ${games.length} current Virginia Scratchers.`);
  } catch (error) {
    console.error(`Virginia Scratcher import stopped: ${error.message}`);
    process.exitCode = 1;
  }
}
