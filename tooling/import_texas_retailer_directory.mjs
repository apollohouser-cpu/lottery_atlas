/* Imports the official Texas statewide retailer roster and verifies coordinates. */
import {readFile, writeFile} from 'node:fs/promises';

const apiUrl = 'https://data.texas.gov/resource/beka-uwfq.json';
const sourceUrl =
  'https://data.texas.gov/See-Category-Tile/Texas-Lottery-Sales-by-Fiscal-Month-Year-Game-and-/beka-uwfq';
const censusUrl = 'https://geocoding.geo.census.gov/geocoder/locations/addressbatch';
const arcGisUrl =
  'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates';
const outputPath = process.argv[2];
const compact = (value) => String(value ?? '').replace(/\s+/g, ' ').trim();
const titleCase = (value) => compact(value).toLowerCase().replace(
  /(^|[\s'/-])([a-z])/g, (_, prefix, letter) => `${prefix}${letter.toUpperCase()}`,
);
const keyFor = (row) => [row.name, row.address, row.city, row.postalCode]
  .map((part) => compact(part).toUpperCase()).join('|');
const csvCell = (value) => `"${String(value).replaceAll('"', '""')}"`;
const parseCsv = (line) => {
  const cells = []; let cell = ''; let quoted = false;
  for (let index = 0; index < line.length; index++) {
    const character = line[index];
    if (character === '"') {
      if (quoted && line[index + 1] === '"') { cell += '"'; index++; }
      else quoted = !quoted;
    } else if (character === ',' && !quoted) { cells.push(cell); cell = ''; }
    else cell += character;
  }
  cells.push(cell); return cells;
};

const fetchRetailers = async () => {
  const select = [
    'retailer_number', 'location_name', 'location_address', 'location_address2',
    'location_city', 'location_state', 'location_zip', 'location_county_desc',
  ].join(',');
  const url = new URL(apiUrl);
  url.searchParams.set('$select', select);
  url.searchParams.set('$where', "month_end_date >= '2026-08-01T00:00:00.000' AND location_state = 'TX'");
  url.searchParams.set('$group', select);
  url.searchParams.set('$limit', '50000');
  const response = await fetch(url, {headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'}});
  if (!response.ok) throw new Error(`Texas retailer data returned HTTP ${response.status}`);
  const rows = await response.json();
  const byId = new Map();
  for (const row of rows) {
    const id = compact(row.retailer_number);
    const address = compact([row.location_address, row.location_address2].filter(Boolean).join(' '));
    if (!id || !compact(row.location_name) || !address || !compact(row.location_city) ||
        !compact(row.location_zip) || !compact(row.location_county_desc)) continue;
    byId.set(id, {
      id: `tx-${id}`, name: compact(row.location_name), address: titleCase(address),
      city: titleCase(row.location_city), postalCode: compact(row.location_zip).slice(0, 5),
      county: `${titleCase(row.location_county_desc)} County`,
    });
  }
  if (byId.size < 19000) throw new Error(`Only ${byId.size} current Texas retailers were returned`);
  return [...byId.values()];
};

const censusBatch = async (rows) => {
  const body = rows.map((row, index) => [index, row.address, row.city, 'TX', row.postalCode]
    .map(csvCell).join(',')).join('\n');
  const form = new FormData(); form.set('benchmark', 'Public_AR_Current');
  form.set('addressFile', new Blob([`${body}\n`], {type: 'text/csv'}), 'texas-retailers.csv');
  const response = await fetch(censusUrl, {
    method: 'POST', headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'}, body: form,
  });
  if (!response.ok) throw new Error(`Census batch geocoder returned HTTP ${response.status}`);
  const matches = new Map();
  for (const line of (await response.text()).split(/\r?\n/)) {
    if (!line.trim()) continue;
    const cells = parseCsv(line); const point = cells[5]?.split(',').map(Number);
    if (cells[2] === 'Match' && cells[3] === 'Exact' && Number.isInteger(Number(cells[0])) &&
        point?.length === 2 && Number.isFinite(point[0]) && Number.isFinite(point[1])) {
      matches.set(Number(cells[0]), {longitude: point[0], latitude: point[1],
        coordinateSource: 'U.S. Census Geocoder exact address match'});
    }
  }
  return matches;
};

const arcGis = async (row) => {
  const url = new URL(arcGisUrl);
  url.searchParams.set('SingleLine', `${row.address}, ${row.city}, TX ${row.postalCode}`);
  url.searchParams.set('f', 'json');
  url.searchParams.set('outFields', 'Match_addr,Addr_type,RegionAbbr,Postal,Score');
  url.searchParams.set('countryCode', 'USA'); url.searchParams.set('maxLocations', '1');
  const response = await fetch(url, {headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'}});
  if (!response.ok) return null;
  const candidate = (await response.json()).candidates?.[0]; const fields = candidate?.attributes ?? {};
  const exactType = ['PointAddress', 'Subaddress'].includes(fields.Addr_type);
  const officialNumber = row.address.match(/^\d+[A-Z-]*/i)?.[0]?.toUpperCase();
  const matchedNumber = compact(fields.Match_addr).match(/^\d+[A-Z-]*/i)?.[0]?.toUpperCase();
  const verifiedStreet = ['StreetAddress', 'StreetAddressExt'].includes(fields.Addr_type) &&
    candidate?.score >= 98 && officialNumber && officialNumber === matchedNumber;
  if (candidate?.score >= 95 && (exactType || verifiedStreet) && fields.RegionAbbr === 'TX' &&
      compact(fields.Postal).slice(0, 5) === row.postalCode &&
      Number.isFinite(candidate.location?.x) && Number.isFinite(candidate.location?.y)) {
    return {longitude: candidate.location.x, latitude: candidate.location.y,
      coordinateSource: exactType ? 'ArcGIS World Geocoder verified point address' :
        'ArcGIS World Geocoder verified numbered street address'};
  }
  return null;
};

if (!outputPath) {
  console.error('Usage: node tooling/import_texas_retailer_directory.mjs OUTPUT.json');
  process.exitCode = 1;
} else try {
  const official = await fetchRetailers();
  let previous = null;
  try { previous = JSON.parse(await readFile(outputPath, 'utf8')); } catch (_) {}
  const cached = new Map((previous?.directories?.[0]?.retailers ?? []).map((row) =>
    [keyFor(row), {latitude: row.latitude, longitude: row.longitude,
      coordinateSource: row.coordinateSource}],
  ));
  const missing = official.filter((row) => !cached.has(keyFor(row)));
  for (let offset = 0; offset < missing.length; offset += 1000) {
    const batch = missing.slice(offset, offset + 1000);
    const matches = await censusBatch(batch);
    for (const [index, coordinate] of matches) cached.set(keyFor(batch[index]), coordinate);
  }
  const arcMissing = official.filter((row) => !cached.has(keyFor(row)));
  let next = 0;
  const worker = async () => {
    while (next < arcMissing.length) {
      const row = arcMissing[next++];
      try { const coordinate = await arcGis(row); if (coordinate) cached.set(keyFor(row), coordinate); }
      catch (_) {}
    }
  };
  await Promise.all(Array.from({length: 12}, worker));
  const retailers = official.flatMap((row) => {
    const coordinate = cached.get(keyFor(row));
    return coordinate ? [{...row, ...coordinate}] : [];
  }).sort((a, b) => a.id.localeCompare(b.id, undefined, {numeric: true}));
  const unresolvedRetailers = official.filter((row) => !cached.has(keyFor(row)))
    .map((row) => ({...row, reason: 'No precise address-level coordinate passed verification'}));
  const directories = [{state: 'Texas', source: sourceUrl, retailers, unresolvedRetailers}];
  const changed = JSON.stringify(previous?.directories) !== JSON.stringify(directories);
  const retrievedAt = changed ? new Date().toISOString() : previous?.retrievedAt ?? new Date().toISOString();
  await writeFile(outputPath, `${JSON.stringify({
    source: 'Official State of Texas Lottery sales-by-retailer open dataset', retrievedAt,
    coverage: `${official.length} current official retailer licenses; ${retailers.length} have exact Census or verified ArcGIS coordinates and ${unresolvedRetailers.length} unresolved addresses are excluded from the map.`,
    directories,
  }, null, 2)}\n`);
  console.log(`Imported ${retailers.length}/${official.length} Texas retailers.`);
} catch (error) {
  console.error(`Texas retailer import stopped: ${error.message}`); process.exitCode = 1;
}
