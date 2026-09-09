/* Imports the complete Colorado Lottery retailer API with published coordinates. */
import {readFile, writeFile} from 'node:fs/promises';

const apiUrl = 'https://api.coloradolottery.com/v1/retailers/';
const sourceUrl = 'https://www.coloradolottery.com/en/retailers/';
const outputPath = process.argv[2];
const countyGeometryPath = process.argv[3];
const compact = (value) => String(value ?? '').replace(/\s+/g, ' ').trim();
const titleCase = (value) => compact(value).toLowerCase().replace(
  /(^|[\s'/-])([a-z])/g, (_, prefix, letter) => `${prefix}${letter.toUpperCase()}`,
);
const insideRing = (x, y, ring) => {
  let inside = false;
  for (let i = 0, j = ring.length - 1; i < ring.length; j = i++) {
    const [xi, yi] = ring[i]; const [xj, yj] = ring[j];
    if (((yi > y) !== (yj > y)) && x < ((xj - xi) * (y - yi)) / (yj - yi) + xi) {
      inside = !inside;
    }
  }
  return inside;
};
const insideGeometry = (longitude, latitude, geometry) => {
  const polygons = geometry.type === 'Polygon' ? [geometry.coordinates] : geometry.coordinates;
  return polygons.some((polygon) =>
    insideRing(longitude, latitude, polygon[0]) &&
    polygon.slice(1).every((hole) => !insideRing(longitude, latitude, hole)),
  );
};

if (!outputPath || !countyGeometryPath) {
  console.error('Usage: node tooling/import_colorado_retailer_directory.mjs OUTPUT.json COUNTIES.geojson');
  process.exitCode = 1;
} else try {
  const response = await fetch(apiUrl, {
    headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'},
  });
  if (!response.ok) throw new Error(`Colorado retailer API returned HTTP ${response.status}`);
  const rows = await response.json();
  if (!Array.isArray(rows) || rows.length < 2800) {
    throw new Error(`Only ${rows?.length ?? 0} Colorado retailers were returned`);
  }
  const geometry = JSON.parse(await readFile(countyGeometryPath, 'utf8'));
  const counties = geometry.features.filter(
    (feature) => String(feature.properties?.STATEFP ?? '') === '08',
  );
  if (counties.length !== 64) throw new Error(`Expected 64 Colorado counties, found ${counties.length}`);
  const unresolvedRetailers = [];
  const retailers = rows.flatMap((row) => {
    const [longitude, latitude] = row.location?.coordinates ?? [];
    const county = counties.find((feature) => insideGeometry(longitude, latitude, feature.geometry));
    const id = compact(row.detail_url).match(/\/retailer\/(\d+)\/?/)?.[1];
    if (!id || !compact(row.name) || !compact(row.address) || !compact(row.city) || !compact(row.zip_code)) {
      throw new Error(`Incomplete official Colorado retailer ${id ?? row.name ?? '?'}`);
    }
    if (!Number.isFinite(latitude) || !Number.isFinite(longitude) || !county) {
      unresolvedRetailers.push({
        id: `co-${id}`, name: compact(row.name), address: titleCase(row.address),
        city: titleCase(row.city), postalCode: compact(row.zip_code).slice(0, 5),
        reason: 'Colorado Lottery coordinate does not resolve inside a Colorado county',
      });
      return [];
    }
    return [{
      id: `co-${id}`,
      name: compact(row.name),
      address: titleCase(row.address),
      city: titleCase(row.city),
      postalCode: compact(row.zip_code).slice(0, 5),
      county: `${titleCase(county.properties.NAME)} County`,
      latitude, longitude,
      coordinateSource: 'Colorado Lottery published retailer coordinate',
    }];
  }).sort((a, b) => a.id.localeCompare(b.id));
  if (new Set(retailers.map((row) => row.id)).size !== retailers.length) {
    throw new Error('Colorado retailer API returned duplicate IDs');
  }
  const directories = [{state: 'Colorado', source: sourceUrl, retailers, unresolvedRetailers}];
  let previous = null;
  try { previous = JSON.parse(await readFile(outputPath, 'utf8')); } catch (_) {}
  const changed = JSON.stringify(previous?.directories) !== JSON.stringify(directories);
  const retrievedAt = changed ? new Date().toISOString() :
    previous?.retrievedAt ?? previous?.updatedAt ?? new Date().toISOString();
  await writeFile(outputPath, `${JSON.stringify({
    source: 'Colorado Lottery official statewide retailer API',
    retrievedAt,
    coverage: `${retailers.length} official retailers with Lottery-published exact coordinates across Colorado's 64 counties. ${unresolvedRetailers.length} official rows with invalid or out-of-state published coordinates are retained as unresolved and excluded from the map.`,
    directories,
  }, null, 2)}\n`);
  console.log(`Imported ${retailers.length} Colorado Lottery retailers.`);
} catch (error) {
  console.error(`Colorado retailer import stopped: ${error.message}`);
  process.exitCode = 1;
}
