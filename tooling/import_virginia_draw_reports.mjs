import {readFile, writeFile} from 'node:fs/promises';
import {tableGames, pickGames, parseTableReports, parsePickReports, assertNoReportRegression} from './virginia_draw_reports.mjs';
const output = process.argv[2];
if (!output) throw new Error('Usage: node tooling/import_virginia_draw_reports.mjs OUTPUT.json');
let previous = [];
try { previous = JSON.parse(await readFile(output, 'utf8')).reports; }
catch (error) { if (error.code !== 'ENOENT') throw error; }
const reports = [];
for (const gameId of Object.keys({...tableGames, ...pickGames})) {
  const response = await fetch('https://www.valottery.com/api/v1/drawnumbers', {
    method: 'POST', body: new URLSearchParams({gameId, page: '0', pageSize: '5'}),
    signal: AbortSignal.timeout(30000),
  });
  if (!response.ok) throw new Error(`Official reports HTTP ${response.status}`);
  const parser = pickGames[gameId] ? parsePickReports : parseTableReports;
  reports.push(...parser(await response.json(), gameId));
}
assertNoReportRegression(previous, reports);
await writeFile(output, JSON.stringify({schemaVersion: 1, state: 'Virginia',
  retrievedAt: new Date().toISOString(), sourcePublicationDate: null,
  cadence: 'Official per-draw reports; app refresh is scheduled, not live.', reports}, null, 2) + '\n');
console.log(`Validated ${reports.length} Virginia draw reports`);
