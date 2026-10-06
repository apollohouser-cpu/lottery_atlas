// Public locator entries, not a certified complete roster or winning locations.
import {readFile, writeFile, rename, rm} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';

const apiUrl = 'https://api2.oregonlottery.org/retailers/Find?includeInactive=false&addInstantGameList=true&addVideoGameList=true&PageSize=6000';
const sourceUrl = 'https://www.oregonlottery.org/retailer/where-to-play/';
const compact = value => typeof value === 'string' ? value.replace(/\s+/g, ' ').trim() : '';

export function parseOregonRetailers(rows) {
  if (!Array.isArray(rows) || !rows.length || rows.length >= 6000) throw Error('Empty or possibly truncated Oregon locator response');
  const ids = new Set(), retailers = [], unresolvedRetailers = [];
  for (const row of rows) {
    const id = compact(row.RetailerNumber), name = compact(row.RetailerName), address = compact(row.StreetName);
    const city = compact(row.CityName), zip = compact(row.ZipCode), county = compact(row.CountyName);
    if (!/^\d+$/.test(id) || ids.has(id) || !name || !address || !city || !/^\d{5}(?:-\d{4})?$/.test(zip) || !county
        || row.ContractStatus !== 'ACTIVE') throw Error('Invalid or duplicate Oregon locator identity/status');
    ids.add(id);
    for (const field of ['SellsVideo', 'SellsDrawGames', 'SellsKeno', 'SellsInstant']) {
      if (typeof row[field] !== 'boolean') throw Error('Missing Oregon product coverage flag');
    }
    const base = {id: `or-${id}`, name, address, city, postalCode: zip.slice(0, 5),
      county: county.endsWith(' County') ? county : `${county} County`,
      sellsVideo: row.SellsVideo, sellsDrawGames: row.SellsDrawGames,
      sellsKeno: row.SellsKeno, sellsInstant: row.SellsInstant};
    const lat = row.Latitude, lon = row.Longitude;
    if (lat == null || lon == null) {
      unresolvedRetailers.push({...base, reason: 'Oregon Lottery did not publish a complete coordinate'});
    } else if (!Number.isFinite(lat) || !Number.isFinite(lon) || lat < 41.9 || lat > 46.4 || lon < -124.8 || lon > -116.4) {
      throw Error('Invalid Oregon published coordinate');
    } else {
      retailers.push({...base, latitude: lat, longitude: lon,
        coordinateSource: 'Oregon Lottery public locator coordinate'});
    }
  }
  retailers.sort((a, b) => a.id.localeCompare(b.id));
  unresolvedRetailers.sort((a, b) => a.id.localeCompare(b.id));
  return {state: 'Oregon', source: sourceUrl, retailers, unresolvedRetailers};
}

export async function refreshOregonDirectory(output, fetchRows) {
  let previous;
  try {
    previous = JSON.parse(await readFile(output, 'utf8'));
    if (!Array.isArray(previous.directories) || previous.directories.length !== 1
        || previous.directories[0].state !== 'Oregon') throw Error('Invalid retained Oregon directory');
  } catch (error) { if (error.code !== 'ENOENT') throw error; }
  const rows = await fetchRows();
  // An anomaly guard anchored to observed source size, never a completeness proof.
  if (!Array.isArray(rows) || rows.length < 3500) throw Error('Unexpected Oregon locator row-count drop');
  const directory = parseOregonRetailers(rows);
  const directories = [directory];
  const changed = JSON.stringify(previous?.directories) !== JSON.stringify(directories);
  const data = {source: 'Oregon Lottery public active retailer locator',
    retrievedAt: changed ? new Date().toISOString() : previous.retrievedAt,
    coverage: `${directory.retailers.length} public locator entries with published coordinates; ${directory.unresolvedRetailers.length} unresolved entries excluded from mapping. Includes differing draw, Keno, Scratch and video product flags, not store stock or winning activity. Agency roster and public locator differ; no certified statewide completeness.`, directories};
  const temporary = `${output}.tmp`;
  try {
    await writeFile(temporary, JSON.stringify(data, null, 2) + '\n');
    await rename(temporary, output);
  } finally { await rm(temporary, {force: true}); }
  return data;
}

async function main() {
  const output = process.argv[2];
  if (!output) throw Error('Usage: node tooling/import_oregon_retailer_directory.mjs OUTPUT.json');
  const data = await refreshOregonDirectory(output, async () => {
    const response = await fetch(apiUrl, {headers: {
      'Ocp-Apim-Subscription-Key': '683ab88d339c4b22b2b276e3c2713809',
      'user-agent': 'LotteryAtlasOfficialDataBot/1.0'}, signal: AbortSignal.timeout(45000)});
    if (!response.ok) throw Error(`Oregon locator HTTP ${response.status}`);
    return response.json();
  });
  console.log(`Validated ${data.directories[0].retailers.length} Oregon public locator entries`);
}
if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  main().catch(error => {console.error(error.message); process.exitCode = 1;});
}
