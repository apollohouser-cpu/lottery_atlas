/* Imports the complete live Ohio Lottery Scratch-Off prize report. */
import {readFile, writeFile} from 'node:fs/promises';

const loginUrl =
  'https://authapi-solutions.ohiolottery.com/1.0/Authentication/Login';
const apiUrl =
  'https://api-solutions.ohiolottery.com/1.0/Games/ScratchOffs/ScratchOffGame/GetFullPrizesRemainingList';
const sourceUrl =
  'https://www.ohiolottery.com/Games/ScratchOffs/Prizes-Remaining';
const applicationUrl = 'https://www.ohiolottery.com/dist/js/app.js';
const outputPath = process.argv[2];

if (!outputPath) {
  console.error('Usage: node tooling/import_ohio_scratch_catalog.mjs OUTPUT.json');
  process.exitCode = 1;
} else {
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
  const token = async () => {
    const applicationResponse = await fetch(applicationUrl, {
      headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'},
    });
    if (!applicationResponse.ok) {
      throw new Error(`Ohio application returned HTTP ${applicationResponse.status}`);
    }
    const application = await applicationResponse.text();
    const credentials = application.match(
      /getNewAPItoken\(\)\{let \w="([^"]+)",\w="([^"]+)"/,
    );
    if (!credentials) throw new Error('Ohio public API credentials were unavailable');
    const payload = await responseJson(loginUrl, {
      method: 'POST',
      headers: {'content-type': 'application/json-patch+json'},
      body: JSON.stringify({
        userName: credentials[1],
        password: credentials[2],
      }),
    });
    if (!payload.data?.token) throw new Error('Ohio public API token was unavailable');
    return payload.data.token;
  };
  const existingOutput = async () => {
    try {
      return JSON.parse(await readFile(outputPath, 'utf8'));
    } catch (_) {
      return null;
    }
  };

  try {
    const bearer = await token();
    const payload = await responseJson(apiUrl, {
      headers: {authorization: `Bearer ${bearer}`},
    });
    if (!Array.isArray(payload.data) || payload.data.length < 60) {
      throw new Error(`Only ${payload.data?.length ?? 0} Ohio games were returned`);
    }
    const games = payload.data.map((game) => {
      const prizes = game.prizeRemainingValues;
      if (!Array.isArray(prizes) || prizes.length === 0) {
        throw new Error(`Ohio game ${game.gameCode ?? '?'} has no prize table`);
      }
      const top = [...prizes].sort((a, b) => b.prizeValue - a.prizeValue)[0];
      const id = String(game.gameCode ?? '').trim();
      const name = String(game.gameName ?? '').trim();
      const cost = Number(game.ticketPrice);
      const topPrize = Number(top.prizeValue);
      const topPrizesRemaining = Number(top.prizesLeft);
      if (
        !id || !name || !Number.isFinite(cost) || cost <= 0 ||
        !Number.isFinite(topPrize) || topPrize <= 0 ||
        !Number.isInteger(topPrizesRemaining) || topPrizesRemaining < 0
      ) {
        throw new Error(`Incomplete Ohio Scratch-Off game ${id || '?'}`);
      }
      return {id, name, cost, topPrize, topPrizesRemaining};
    }).sort((a, b) => a.id.localeCompare(b.id, undefined, {numeric: true}));
    if (new Set(games.map((game) => game.id)).size !== games.length) {
      throw new Error('Ohio API returned duplicate game numbers');
    }
    const catalogs = [{state: 'Ohio', source: sourceUrl, games}];
    const existing = await existingOutput();
    const changed = JSON.stringify(existing?.catalogs) !== JSON.stringify(catalogs);
    const updatedAt = changed
      ? new Date().toISOString()
      : existing?.updatedAt ?? existing?.retrievedAt ?? new Date().toISOString();
    await writeFile(outputPath, `${JSON.stringify({
      source: 'Ohio Lottery official live Prizes Remaining API',
      updatedAt,
      retrievedAt: updatedAt,
      coverage:
        `All ${games.length} games returned by the official live Ohio Lottery ` +
        'Scratch-Off prize report, including price, top prize, and remaining top prizes.',
      catalogs,
    }, null, 2)}\n`);
    console.log(`Imported ${games.length} current Ohio Scratch-Off games.`);
  } catch (error) {
    console.error(`Ohio Scratch-Off import stopped: ${error.message}`);
    process.exitCode = 1;
  }
}
