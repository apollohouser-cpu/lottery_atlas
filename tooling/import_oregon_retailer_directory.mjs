/* Imports Oregon Lottery's complete active retailer API with published coordinates. */
import {readFile, writeFile} from 'node:fs/promises';

const apiUrl = 'https://api2.oregonlottery.org/retailers/Find?includeInactive=false&addInstantGameList=true&addVideoGameList=true&PageSize=6000';
const sourceUrl = 'https://www.oregonlottery.org/retailer/where-to-play/';
const outputPath = process.argv[2];
const compact = (value) => String(value ?? '').replace(/\s+/g, ' ').trim();

if (!outputPath) {
  console.error('Usage: node tooling/import_oregon_retailer_directory.mjs OUTPUT.json');
  process.exitCode = 1;
} else try {
  const response = await fetch(apiUrl, {headers: {
    'Ocp-Apim-Subscription-Key': '683ab88d339c4b22b2b276e3c2713809',
    'user-agent': 'LotteryAtlasOfficialDataBot/1.0',
  }});
  if (!response.ok) throw new Error(`Oregon retailer API returned HTTP ${response.status}`);
  const rows = await response.json();
  if (!Array.isArray(rows) || rows.length < 3500) throw new Error(`Only ${rows?.length ?? 0} Oregon retailers returned`);
  const unresolvedRetailers = [];
  const retailers = rows.flatMap((row) => {
    const id = compact(row.RetailerNumber);
    const name = compact(row.RetailerName); const address = compact(row.StreetName);
    const city = compact(row.CityName); const postalCode = compact(row.ZipCode).slice(0, 5);
    const county = compact(row.CountyName);
    if (!id || !name || !address || !city || !postalCode || !county) {
      throw new Error(`Incomplete official Oregon retailer ${id || name || '?'}`);
    }
    if (!Number.isFinite(row.Latitude) || !Number.isFinite(row.Longitude)) {
      unresolvedRetailers.push({id: `or-${id}`, name, address, city, postalCode,
        reason: 'Oregon Lottery did not publish a coordinate'});
      return [];
    }
    return [{id: `or-${id}`, name, address, city, postalCode, county: `${county} County`,
      latitude: row.Latitude, longitude: row.Longitude,
      coordinateSource: 'Oregon Lottery published retailer coordinate'}];
  }).sort((a, b) => a.id.localeCompare(b.id));
  if (retailers.length < 3500 || new Set(retailers.map((row) => row.id)).size !== retailers.length) {
    throw new Error(`Oregon directory did not contain a complete unique active roster (${retailers.length})`);
  }
  const directories = [{state: 'Oregon', source: sourceUrl, retailers, unresolvedRetailers}];
  let previous; try { previous = JSON.parse(await readFile(outputPath, 'utf8')); } catch (_) {}
  const changed = JSON.stringify(previous?.directories) !== JSON.stringify(directories);
  const retrievedAt = changed ? new Date().toISOString() : previous?.retrievedAt ?? new Date().toISOString();
  await writeFile(outputPath, `${JSON.stringify({
    source: 'Oregon Lottery official active statewide retailer API', retrievedAt,
    coverage: `${retailers.length} active Oregon Lottery retailers with Lottery-published exact coordinates. ${unresolvedRetailers.length} incomplete coordinate rows are retained as unresolved and excluded from the map.`, directories,
  }, null, 2)}\n`);
  console.log(`Imported ${retailers.length} Oregon Lottery retailers.`);
} catch (error) {
  console.error(`Oregon retailer import stopped: ${error.message}`);
  process.exitCode = 1;
}
