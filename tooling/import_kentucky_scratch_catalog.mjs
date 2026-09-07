/*
 * Imports every ticket published on the Kentucky Lottery's official
 * "Available Scratch-off Games" page. The page publishes ticket price, game
 * number, advertised top prize, and a current prize/remaining table. When the
 * table is temporarily blank, the advertised top prize remains available but
 * the remaining count is left null rather than guessed.
 */
import {writeFile} from 'node:fs/promises';

const sourceUrl =
  'https://www.kylottery.com/apps/scratch_offs/available_games.html';
const outputPath = process.argv[2];

if (!outputPath) {
  console.error(
    'Usage: node tooling/import_kentucky_scratch_catalog.mjs OUTPUT.json',
  );
  process.exitCode = 1;
} else {
  const responseText = async (url) => {
    const response = await fetch(url, {
      headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'},
    });
    if (!response.ok) throw new Error(`${url} returned HTTP ${response.status}`);
    return response.text();
  };

  const decodeEntities = (value) => value
    .replace(/&nbsp;/gi, ' ')
    .replace(/&amp;/gi, '&')
    .replace(/&quot;/gi, '"')
    .replace(/&#39;|&apos;/gi, "'")
    .replace(/&reg;/gi, '®')
    .replace(/&trade;/gi, '™')
    .replace(/&#(\d+);/g, (_, code) => String.fromCodePoint(Number(code)));

  const text = (value) => decodeEntities(value)
    .replace(/<[^>]+>/g, ' ')
    .replace(/\s+/g, ' ')
    .trim();

  const integer = (value) => {
    const match = value.match(/\$?([\d,]+)/);
    return match ? Number(match[1].replaceAll(',', '')) : null;
  };

  const field = (panel, label) => text(
    panel.match(new RegExp(`${label}:&nbsp;<\\/span><b>(.*?)<\\/b>`, 's'))?.[1] ?? '',
  );

  const gamesFrom = (html) => {
    const starts = [...html.matchAll(/<div class="panel panel-info">/g)]
      .map((match) => match.index);
    const games = [];
    const sourceDates = [];

    for (let index = 0; index < starts.length; index++) {
      const panel = html.slice(starts[index], starts[index + 1] ?? html.length);
      const title = text(
        panel.match(/<h4 class="panel-title">([\s\S]*?)<\/h4>/)?.[1] ?? '',
      );
      const gameNumber = field(panel, 'Game #');
      const cost = integer(field(panel, 'Value'));
      const topPrizeLabel = field(panel, 'Top Prize');
      const titleSuffix = new RegExp(`\\s*-\\s*${gameNumber}\\s*$`);
      const name = title.replace(titleSuffix, '').trim();
      const remainingDate = text(
        panel.match(/Prizes Remaining as of\s*<b>(.*?)<\/b>/s)?.[1] ?? '',
      );
      if (remainingDate) sourceDates.push(remainingDate);

      const topRow = panel.match(
        /<td[^>]*title="Prize Amount"[^>]*>([\s\S]*?)<\/td>[\s\S]*?<td[^>]*title="Prizes Remaining"[^>]*>([\s\S]*?)<\/td>/,
      );
      const tablePrize = integer(text(topRow?.[1] ?? ''));
      const advertisedPrize = integer(topPrizeLabel);
      const topPrize = tablePrize ?? advertisedPrize;
      const topPrizesRemaining = integer(text(topRow?.[2] ?? ''));

      if (!gameNumber || !name || !cost || topPrize === null) {
        throw new Error(`Official Scratch-Off panel could not be parsed: ${title}`);
      }

      const game = {
        id: gameNumber,
        name,
        cost,
        topPrize,
      };
      if (topPrizesRemaining !== null) {
        game.topPrizesRemaining = topPrizesRemaining;
      }
      if (topPrizeLabel && (advertisedPrize !== topPrize || /[*]/.test(topPrizeLabel))) {
        game.topPrizeLabel = topPrizeLabel;
      }
      games.push(game);
    }

    if (games.length < 20) {
      throw new Error(`Only ${games.length} official Scratch-Off games were found`);
    }
    if (new Set(games.map((game) => game.id)).size !== games.length) {
      throw new Error('The official Scratch-Off page contains duplicate game numbers');
    }

    const parsedDates = sourceDates
      .map((value) => {
        const [month, day, year] = value.split('/').map(Number);
        return Number.isFinite(month) && Number.isFinite(day) && Number.isFinite(year)
          ? new Date(Date.UTC(year, month - 1, day, 12))
          : null;
      })
      .filter(Boolean)
      .sort((left, right) => right - left);
    const sourceLastUpdated = parsedDates[0]?.toISOString() ?? null;
    if (!sourceLastUpdated) {
      throw new Error('The official remaining-prize date was not published');
    }

    return {games, sourceLastUpdated};
  };

  try {
    const {games, sourceLastUpdated} = gamesFrom(await responseText(sourceUrl));
    const output = {
      source: 'Kentucky Lottery official Available Scratch-off Games',
      updatedAt: sourceLastUpdated,
      sourceLastUpdated,
      coverage:
        `All ${games.length} tickets published on the official Kentucky Lottery ` +
        'Available Scratch-off Games page. Remaining top-prize counts are omitted ' +
        'only when the official prize table is blank.',
      catalogs: [{state: 'Kentucky', source: sourceUrl, games}],
    };
    await writeFile(outputPath, `${JSON.stringify(output, null, 2)}\n`);
    console.log(
      `Imported ${games.length} Kentucky Scratch-Off games as of ${sourceLastUpdated.slice(0, 10)}.`,
    );
  } catch (error) {
    console.error(`Kentucky Scratch-Off import stopped: ${error.message}`);
    process.exitCode = 1;
  }
}
