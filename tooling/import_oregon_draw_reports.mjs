import {readFile, writeFile, rename, rm} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';
import {parseOregonReport} from './oregon_draw_reports.mjs';

export const oregonReportGames = ['pb', 'mm', 'mb', 'wf', 'p4', 'cp'];
const sessions = game => game === 'p4' ? ['13:00', '16:00', '19:00', '22:00']
  : game === 'cp' ? Array.from({length: 16}, (_, i) => `${String(i + 7).padStart(2, '0')}:00`) : [null];
const group = r => `${r.gameCode}/${r.drawingTime ?? ''}`;
const moment = r => `${r.drawDate}T${r.drawingTime ?? '00:00'}`;

export function validateOregonContinuity(previous, reports) {
  const ids = new Set(), slots = new Set(), newest = new Map();
  for (const r of reports) {
    if (!oregonReportGames.includes(r.gameCode) || !sessions(r.gameCode).includes(r.drawingTime)
        || !/^\d{4}-\d{2}-\d{2}$/.test(r.drawDate) || !Number.isSafeInteger(r.drawNumber) || r.drawNumber <= 0
        || r.id !== `or-${r.gameCode}-${r.drawNumber}`) throw Error('Invalid Oregon report identity');
    const slot = `${group(r)}/${r.drawDate}`;
    if (ids.has(r.id) || slots.has(slot)) throw Error('Duplicate Oregon draw identity/session');
    ids.add(r.id); slots.add(slot);
    if (!newest.has(group(r)) || moment(newest.get(group(r))) < moment(r)) newest.set(group(r), r);
  }
  for (const game of oregonReportGames) {
    const ordered = reports.filter(r => r.gameCode === game).sort((a, b) => moment(a).localeCompare(moment(b)));
    for (let i = 1; i < ordered.length; i++) {
      if (ordered[i].drawNumber <= ordered[i - 1].drawNumber) throw Error('Oregon draw-number ordering regression');
    }
  }
  for (const r of previous) {
    const latest = newest.get(group(r));
    if (!latest || moment(latest) < moment(r) || latest.drawNumber < r.drawNumber) throw Error('Oregon game/session regression');
    const sameId = reports.find(n => n.id === r.id);
    const sameSlot = reports.find(n => group(n) === group(r) && n.drawDate === r.drawDate);
    if ((sameId && (moment(sameId) !== moment(r) || sameId.sourceDrawDateTime !== r.sourceDrawDateTime))
        || (sameSlot && sameSlot.id !== r.id)) throw Error('Oregon retained draw identity changed');
  }
}

export async function refreshOregonReports(output, fetchGame) {
  let previous = [];
  try {
    const saved = JSON.parse(await readFile(output, 'utf8'));
    if (saved.state !== 'Oregon' || saved.schemaVersion !== 1 || !Array.isArray(saved.reports)) throw Error('Invalid retained Oregon report file');
    validateOregonContinuity([], saved.reports);
    previous = saved.reports;
  } catch (error) { if (error.code !== 'ENOENT') throw error; }
  const reports = [];
  for (const game of oregonReportGames) {
    const rows = await fetchGame(game);
    if (!Array.isArray(rows) || rows.length < 2 || rows.length >= 1000) throw Error('Missing or possibly truncated Oregon draw history');
    // Every supplied record is validated, even when older than the selected window.
    const parsed = rows.map(r => parseOregonReport(game, r));
    validateOregonContinuity([], parsed);
    for (const session of sessions(game)) {
      const selected = parsed.filter(r => r.drawingTime === session).sort((a, b) => b.drawDate.localeCompare(a.drawDate)).slice(0, 2);
      if (selected.length !== 2) throw Error('Missing Oregon game/session history');
      reports.push(...selected);
    }
  }
  validateOregonContinuity(previous, reports);
  const data = {schemaVersion: 1, state: 'Oregon', retrievedAt: new Date().toISOString(),
    cadence: 'Two latest finalized reports per game/session within a bounded 14-day source query. Actual source dates retained; scheduled refresh, not live results.',
    coverage: 'Six Oregon report families. Source-reported winners are not verified distinct tickets or people. No retailer allocation or complete statewide claims coverage.', reports};
  const temporary = `${output}.tmp`;
  try {
    await writeFile(temporary, JSON.stringify(data, null, 2) + '\n');
    await rename(temporary, output);
  } finally { await rm(temporary, {force: true}); }
  return data;
}

async function main() {
  const output = process.argv[2];
  if (!output) throw Error('Usage: node tooling/import_oregon_draw_reports.mjs OUTPUT.json');
  // Public website subscription key already used by its official retailer endpoint.
  const headers = {'Ocp-Apim-Subscription-Key': '683ab88d339c4b22b2b276e3c2713809', 'user-agent': 'LotteryAtlasOfficialDataBot/1.0'};
  const end = new Date().toISOString().slice(0, 10);
  const start = new Date(Date.parse(`${end}T00:00:00Z`) - 13 * 86400000).toISOString().slice(0, 10);
  const result = await refreshOregonReports(output, async game => {
    const query = new URLSearchParams({gameSelector: game, startingDate: start, endingDate: end, pageSize: '1000', includeOpen: 'False'});
    const response = await fetch(`https://api2.oregonlottery.org/drawresults/ByDrawDate?${query}`, {headers, signal: AbortSignal.timeout(45000)});
    if (!response.ok) throw Error(`Oregon ${game} source HTTP ${response.status}`);
    const rows = await response.json();
    if (!Array.isArray(rows) || rows.some(r => typeof r.DrawDateTime !== 'string' || r.DrawDateTime.slice(0, 10) < start || r.DrawDateTime.slice(0, 10) > end)) throw Error('Oregon source query date mismatch');
    return rows;
  });
  console.log(`Validated ${result.reports.length} Oregon reports across six families`);
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch(error => {console.error(error.message); process.exitCode = 1;});
}
