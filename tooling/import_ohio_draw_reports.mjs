import {readFile, writeFile, rename, rm} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';
import {parseOhioPayout} from './ohio_draw_reports.mjs';

export const ohioPayoutGames = ['Pick3', 'Pick4', 'Pick5', 'ClassicLotto', 'RollingCashFive'];

export function validateOhioContinuity(previous, reports) {
  const newest = new Map();
  const ids = new Set();
  const slots = new Set();
  for (const report of reports) {
    const key = `${report.game}/${report.drawingSession ?? ''}`;
    const slot = `${key}/${report.drawDate}`;
    if (ids.has(report.id) || slots.has(slot)) throw Error('Duplicate Ohio draw report');
    ids.add(report.id); slots.add(slot);
    const prior = newest.get(key);
    if (!prior || prior.drawDate < report.drawDate) newest.set(key, report);
  }
  for (const report of previous) {
    const key = `${report.game}/${report.drawingSession ?? ''}`;
    const latest = newest.get(key);
    if (!latest || latest.drawDate < report.drawDate ||
        Number(latest.drawNumber) < Number(report.drawNumber)) {
      throw Error('Ohio game/session report regression');
    }
  }
}

export async function refreshOhioReports(output, fetchGame) {
  let previous = [];
  try {
    const saved = JSON.parse(await readFile(output, 'utf8'));
    if (!Array.isArray(saved.reports)) throw Error('Invalid previous Ohio reports');
    previous = saved.reports;
  } catch (error) { if (error.code !== 'ENOENT') throw error; }
  const reports = [];
  for (const game of ohioPayoutGames) {
    const payload = await fetchGame(game);
    if (!Array.isArray(payload.data) || payload.data.length < 2) throw Error('Insufficient Ohio draw history');
    const parsed = payload.data.map(row => parseOhioPayout(game, row));
    if (game.startsWith('Pick') && new Set(parsed.map(row => row.drawingSession)).size !== 2) {
      throw Error('Missing Ohio Midday/Evening session');
    }
    reports.push(...parsed);
  }
  validateOhioContinuity(previous, reports);
  const data = {
    schemaVersion: 1, state: 'Ohio', retrievedAt: new Date().toISOString(),
    cadence: 'Latest published draw payouts; scheduled refresh, not a live monitor-game feed.',
    coverage: 'Pick 3/4/5, Classic Lotto and Rolling Cash 5 published payout dollars. No tier winner counts or retailer allocations.',
    reports,
  };
  const temporary = output + '.tmp';
  try {
    await writeFile(temporary, JSON.stringify(data, null, 2) + '\n');
    await rename(temporary, output);
  } finally { await rm(temporary, {force: true}); }
  return data;
}

async function main() {
  const output = process.argv[2];
  if (!output) throw Error('Usage: node tooling/import_ohio_draw_reports.mjs OUTPUT.json');
  const headers = {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'};
  const request = async (url, options = {}) => {
    const response = await fetch(url, {...options, headers: {...headers, ...options.headers}, signal: AbortSignal.timeout(45000)});
    if (!response.ok) throw Error('Ohio public source HTTP ' + response.status);
    return response;
  };
  const application = await (await request('https://www.ohiolottery.com/dist/js/app.js')).text();
  const credentials = application.match(/getNewAPItoken\(\)\{let \w="([^"]+)",\w="([^"]+)"/);
  if (!credentials) throw Error('Ohio public-site authentication configuration missing');
  const login = await (await request('https://authapi-solutions.ohiolottery.com/1.0/Authentication/Login', {
    method: 'POST', headers: {'content-type': 'application/json-patch+json'},
    body: JSON.stringify({userName: credentials[1], password: credentials[2]}),
  })).json();
  if (!login.data?.token) throw Error('Ohio public-site token unavailable');
  const data = await refreshOhioReports(output, async game => (await request(
    `https://api-solutions.ohiolottery.com/1.0/Games/DrawGames/${game}/GetLatestDraws`,
    {headers: {Authorization: 'Bearer ' + login.data.token}},
  )).json());
  console.log(`Validated ${data.reports.length} Ohio payout reports`);
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch(error => {console.error(error.message); process.exitCode = 1;});
}
