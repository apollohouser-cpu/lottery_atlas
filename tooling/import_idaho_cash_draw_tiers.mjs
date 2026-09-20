/*
 * Audit Idaho Cash's official daily prize-tier counts. This output deliberately
 * does not enter the winning-ticket total or retailer activity feeds: the source
 * does not establish distinct tickets, players, or selling locations.
 */
import {readFile, writeFile} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';
import {fetchSourceJson} from './source_json_fetch.mjs';

export const PAGE = 'https://www.idaholottery.com/games/draw/idaho-cash';
export const API = 'https://www.idaholottery.com/api/v1/drawgame/idaho-cash/';
export const START = '2026-01-01';
const labels = ['Jackpot', '$200', '$5', 'Free Ticket'];

function nonnegativeInteger(value) {
  if (!['string', 'number'].includes(typeof value) || !/^\d+$/.test(String(value))) {
    throw new Error('Invalid prize-tier count');
  }
  const result = Number(value);
  if (!Number.isSafeInteger(result)) throw new Error('Unsafe prize-tier count');
  return result;
}

export function datesThrough(end) {
  if (!/^2026-\d{2}-\d{2}$/.test(end)) throw new Error('Expected a 2026 source date');
  const until = new Date(`${end}T00:00:00Z`);
  if (!Number.isFinite(until.getTime()) || until.toISOString().slice(0, 10) !== end || end < START) {
    throw new Error('Invalid source date');
  }
  const dates = [];
  for (let time = Date.parse(`${START}T00:00:00Z`); time <= until.getTime(); time += 86400000) {
    dates.push(new Date(time).toISOString().slice(0, 10));
  }
  return dates;
}

export function latestDrawFromPage(html) {
  const inputs = html.match(/<input\b[^>]*>/gi) ?? [];
  const matches = inputs.filter((input) => /class="[^"]*winners-datepicker\b/.test(input) &&
    /data-game="Idaho Cash"/.test(input) && /data-region="idaho"/.test(input));
  if (matches.length !== 1) throw new Error('Missing or ambiguous Idaho Cash winner date');
  const date = matches[0].match(/value="(\d{2})\/(\d{2})\/(\d{2})"/);
  if (!date) throw new Error('Missing dated Idaho Cash winner table');
  const result = `20${date[3]}-${date[1]}-${date[2]}`;
  datesThrough(result);
  if (Date.parse(`${result}T00:00:00Z`) > Date.now()) throw new Error('Future source drawing');
  return result;
}

export function parseDraw(payload, requestedDate) {
  const data = payload?.data;
  if (payload?.success !== true || data?.game !== 'Idaho Cash' || data.draw_date !== requestedDate) {
    throw new Error(`Wrong game, missing result, or wrong drawing for ${requestedDate}`);
  }
  if (!Array.isArray(data.winners) || data.winners.length !== 4) {
    throw new Error(`Incomplete prize-tier coverage for ${requestedDate}`);
  }
  const counts = new Map();
  for (const row of data.winners) {
    const label = row?.['0'];
    if (!labels.includes(label) || counts.has(label)) throw new Error('Unknown or duplicate prize tier');
    counts.set(label, nonnegativeInteger(row['1']));
  }
  const numbers = (data.winning_numbers ?? []).map((row) => nonnegativeInteger(row['1']));
  if (numbers.length !== 5 || new Set(numbers).size !== 5 || numbers.some((n) => n < 1 || n > 45)) {
    throw new Error(`Invalid winning numbers for ${requestedDate}`);
  }
  return {
    drawDate: requestedDate,
    sourceUrl: `${API}${requestedDate}`,
    winningNumbers: numbers,
    tiers: labels.map((label, index) => ({
      match: 5 - index,
      prizeLabel: label,
      prizeKind: index === 0 ? 'jackpot' : index === 3 ? 'free-ticket' : 'cash',
      ...(index === 1 ? {cashPrize: 200} : index === 2 ? {cashPrize: 5} : {}),
      publishedWinnerCount: counts.get(label),
    })),
  };
}

export function buildReport(draws, latest) {
  const expected = datesThrough(latest);
  if (draws.length !== expected.length || draws.some((draw, index) => draw.drawDate !== expected[index])) {
    throw new Error('Missing, duplicate, or out-of-order daily drawings');
  }
  return {
    source: 'Idaho Lottery official Idaho Cash draw API',
    sourceUrl: PAGE,
    periodStart: START,
    periodEnd: latest,
    countDefinition: 'Published prize-tier winner counts; distinct ticket and player counts are not established.',
    coverage: 'Idaho Cash only, including the free-ticket tier. Excludes other draw games, Scratch, ' +
      'InstaPlay and Tab games. No retailer locations or complete statewide total. ' +
      'This audit is not yet connected to the public app feeds.',
    updateCadence: 'Drawings are daily; API publication and correction timing are not documented.',
    drawCount: draws.length,
    totalsByTier: labels.map((label, index) => ({
      prizeLabel: label,
      publishedWinnerCount: draws.reduce((total, draw) => total + draw.tiers[index].publishedWinnerCount, 0),
    })),
    draws,
  };
}

async function main() {
  const outputPath = process.argv[2];
  if (!outputPath) throw new Error('Usage: node tooling/import_idaho_cash_draw_tiers.mjs OUTPUT.json');
  const response = await fetch(PAGE, {signal: AbortSignal.timeout(30000)});
  if (!response.ok) throw new Error(`Official game page returned HTTP ${response.status}`);
  const latest = latestDrawFromPage(await response.text());
  const dates = datesThrough(latest);
  const draws = new Array(dates.length);
  let next = 0;
  // Two requests at a time keep the initial historical audit modest.
  await Promise.all(Array.from({length: 2}, async () => {
    while (next < dates.length) {
      const index = next++;
      draws[index] = parseDraw(await fetchSourceJson(`${API}${dates[index]}`), dates[index]);
      if ((index + 1) % 50 === 0) console.log(`Verified ${index + 1}/${dates.length} daily drawings`);
    }
  }));
  const report = buildReport(draws, latest);
  let previous;
  try { previous = JSON.parse(await readFile(outputPath, 'utf8')); } catch (_) {}
  const {retrievedAt: previousTime, ...previousData} = previous ?? {};
  report.retrievedAt = JSON.stringify(previousData) === JSON.stringify(report)
    ? previousTime : new Date().toISOString();
  // All remote responses and the continuous date window validate before writing.
  await writeFile(outputPath, `${JSON.stringify(report, null, 2)}\n`);
  console.log(`Verified ${draws.length} daily Idaho Cash drawings from ${START} through ${latest}.`);
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch((error) => { console.error(error.message); process.exitCode = 1; });
}
