/*
 * Imports every active licensed New York Lottery retailer from the official
 * New York State Open Data export. The source publishes an exact coordinate
 * for every row. County names are derived deterministically from the bundled
 * Census county polygons; a row is never assigned to a nearest county.
 */
import {readFile, writeFile} from 'node:fs/promises';

const apiUrl = 'https://data.ny.gov/resource/2vvn-pdyi.json';
const sourceUrl =
  'https://data.ny.gov/Government-Finance/NYS-Lottery-Retailers-Map/t8pe-c66p/about';
const outputPath = process.argv[2];
const countyGeometryPath = process.argv[3];

if (!outputPath || !countyGeometryPath) {
  console.error(
    'Usage: node tooling/import_new_york_retailer_directory.mjs OUTPUT.json COUNTY_GEOJSON',
  );
  process.exitCode = 1;
} else {
  const compact = (value) => String(value ?? '').replace(/\s+/g, ' ').trim();
  const titleCase = (value) => compact(value).toLowerCase().replace(
    /(^|[\s'/-])([a-z])/g,
    (_, prefix, letter) => `${prefix}${letter.toUpperCase()}`,
  );
  const fetchJson = async (url) => {
    let lastError;
    for (let attempt = 1; attempt <= 4; attempt++) {
      try {
        const response = await fetch(url, {
          headers: {
            accept: 'application/json',
            'user-agent': 'LotteryAtlasOfficialDataBot/1.0',
          },
        });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        return await response.json();
      } catch (error) {
        lastError = error;
        if (attempt < 4) {
          await new Promise((resolve) => setTimeout(resolve, attempt * 750));
        }
      }
    }
    throw new Error(`${url} failed: ${lastError.message}`);
  };
  const pointOnSegment = (point, start, end) => {
    const [x, y] = point;
    const [x1, y1] = start;
    const [x2, y2] = end;
    const cross = (x - x1) * (y2 - y1) - (y - y1) * (x2 - x1);
    if (Math.abs(cross) > 1e-9) return false;
    return x >= Math.min(x1, x2) - 1e-9 &&
      x <= Math.max(x1, x2) + 1e-9 &&
      y >= Math.min(y1, y2) - 1e-9 &&
      y <= Math.max(y1, y2) + 1e-9;
  };
  const inRing = (point, ring) => {
    let inside = false;
    for (let index = 0, previous = ring.length - 1; index < ring.length; previous = index++) {
      const start = ring[previous];
      const end = ring[index];
      if (pointOnSegment(point, start, end)) return true;
      const intersects = (end[1] > point[1]) !== (start[1] > point[1]) &&
        point[0] < (start[0] - end[0]) * (point[1] - end[1]) /
          (start[1] - end[1]) + end[0];
      if (intersects) inside = !inside;
    }
    return inside;
  };
  const inPolygon = (point, polygon) =>
    inRing(point, polygon[0]) && !polygon.slice(1).some((hole) => inRing(point, hole));
  const boundsFor = (polygons) => {
    const points = polygons.flat(2);
    return {
      minX: Math.min(...points.map((point) => point[0])),
      maxX: Math.max(...points.map((point) => point[0])),
      minY: Math.min(...points.map((point) => point[1])),
      maxY: Math.max(...points.map((point) => point[1])),
    };
  };
  const countyFor = (longitude, latitude, counties) => {
    const point = [longitude, latitude];
    for (const county of counties) {
      const bounds = county.bounds;
      if (
        longitude < bounds.minX || longitude > bounds.maxX ||
        latitude < bounds.minY || latitude > bounds.maxY
      ) continue;
      if (county.polygons.some((polygon) => inPolygon(point, polygon))) {
        return county.name;
      }
    }
    return null;
  };
  const existingOutput = async () => {
    try {
      return JSON.parse(await readFile(outputPath, 'utf8'));
    } catch (_) {
      return null;
    }
  };
  const censusAddress = async (row) => {
    const url = new URL(
      'https://geocoding.geo.census.gov/geocoder/geographies/onelineaddress',
    );
    url.searchParams.set(
      'address',
      `${compact(row.street)}, ${compact(row.city)}, NY ${compact(row.zip)}`,
    );
    url.searchParams.set('benchmark', 'Public_AR_Current');
    url.searchParams.set('vintage', 'Current_Current');
    url.searchParams.set('format', 'json');
    const payload = await fetchJson(url);
    const match = payload?.result?.addressMatches?.[0];
    const county = match?.geographies?.Counties?.[0];
    if (
      payload?.result?.addressMatches?.length === 1 &&
      county?.STATE === '36' &&
      compact(match.addressComponents?.zip).slice(0, 5) === compact(row.zip).slice(0, 5) &&
      Number.isFinite(match.coordinates?.x) &&
      Number.isFinite(match.coordinates?.y)
    ) {
      return {
        county: compact(county.NAME),
        longitude: match.coordinates.x,
        latitude: match.coordinates.y,
      };
    }
    return null;
  };

  try {
    const countUrl = new URL(apiUrl);
    countUrl.searchParams.set('$select', 'count(*) as count');
    const countPayload = await fetchJson(countUrl);
    const officialCount = Number(countPayload?.[0]?.count);
    if (!Number.isInteger(officialCount) || officialCount < 12000) {
      throw new Error(`Official active-retailer count is invalid: ${officialCount}`);
    }

    const retailerUrl = new URL(apiUrl);
    retailerUrl.searchParams.set('$limit', '50000');
    retailerUrl.searchParams.set('$order', 'retailer ASC');
    const officialRows = await fetchJson(retailerUrl);
    if (!Array.isArray(officialRows) || officialRows.length !== officialCount) {
      throw new Error(
        `Official directory returned ${officialRows?.length ?? 0}/${officialCount} rows`,
      );
    }

    const countyGeoJson = JSON.parse(await readFile(countyGeometryPath, 'utf8'));
    const counties = countyGeoJson.features.filter(
      (feature) => feature.properties?.STATEFP === '36',
    ).map((feature) => {
      const polygons = feature.geometry.type === 'Polygon'
        ? [feature.geometry.coordinates]
        : feature.geometry.coordinates;
      return {
        name: `${compact(feature.properties.NAME)} County`,
        polygons,
        bounds: boundsFor(polygons),
      };
    });
    if (counties.length !== 62) {
      throw new Error(`Expected 62 New York counties, found ${counties.length}`);
    }

    const countyNamesByZip = new Map();
    for (const row of officialRows) {
      const county = countyFor(Number(row.longitude), Number(row.latitude), counties);
      const postalCode = compact(row.zip).slice(0, 5);
      if (!county || !/^\d{5}$/.test(postalCode)) continue;
      const names = countyNamesByZip.get(postalCode) ?? new Set();
      names.add(county);
      countyNamesByZip.set(postalCode, names);
    }

    const ids = new Set();
    const retailers = [];
    let censusCorrections = 0;
    let zipCountyDerivations = 0;
    for (const row of officialRows) {
      const id = compact(row.retailer);
      const name = compact(row.name);
      const address = compact(row.street);
      const city = compact(row.city);
      const postalCode = compact(row.zip).slice(0, 5);
      const latitude = Number(row.latitude);
      const longitude = Number(row.longitude);
      if (
        !id || !ids.add(id) || !name || !address || !city ||
        !/^\d{5}$/.test(postalCode) ||
        !Number.isFinite(latitude) || !Number.isFinite(longitude)
      ) {
        throw new Error(`Incomplete or duplicate official retailer row ${id || '?'}`);
      }
      let exactLatitude = latitude;
      let exactLongitude = longitude;
      let county = countyFor(longitude, latitude, counties);
      let coordinateSource =
        'New York State Gaming Commission published retailer coordinate';
      if (!county) {
        const census = await censusAddress(row);
        if (census) {
          county = census.county;
          exactLatitude = census.latitude;
          exactLongitude = census.longitude;
          coordinateSource = 'U.S. Census Geocoder exact address match';
          censusCorrections++;
        } else {
          const zipCounties = countyNamesByZip.get(postalCode);
          if (zipCounties?.size === 1) {
            county = [...zipCounties][0];
            zipCountyDerivations++;
          }
        }
        if (!county) {
          throw new Error(
            `Retailer ${id} has no exact New York county or Census address match`,
          );
        }
      }
      retailers.push({
        id: `ny-${id}`,
        name,
        address: titleCase(address),
        city: titleCase(city),
        postalCode,
        county,
        latitude: exactLatitude,
        longitude: exactLongitude,
        coordinateSource,
      });
    }
    retailers.sort((left, right) => left.id.localeCompare(right.id));

    const directories = [{
      state: 'New York',
      source: sourceUrl,
      retailers,
      unresolvedRetailers: [],
    }];
    const existing = await existingOutput();
    const directoryChanged =
      JSON.stringify(existing?.directories ?? null) !== JSON.stringify(directories);
    const retrievedAt = directoryChanged
      ? new Date().toISOString()
      : existing?.retrievedAt ?? new Date().toISOString();
    const output = {
      source: 'New York State Gaming Commission official active Lottery retailer directory',
      retrievedAt,
      coverage:
        `All ${retailers.length} active licensed retailers returned by the official ` +
        'New York State Open Data export. Exact coordinates are published by the ' +
        'Commission; county names were derived by point-in-polygon against official ' +
        `Census county geometry. ${censusCorrections} source coordinates outside a ` +
        'county polygon were replaced only after an exact Census address match; ' +
        `${zipCountyDerivations} island or boundary locations retained the published ` +
        'coordinate and received the single Census county shared by every other ' +
        'official retailer in the same ZIP code. No ' +
        'nearest-location estimates were used.',
      directories,
    };
    await writeFile(outputPath, `${JSON.stringify(output, null, 2)}\n`);
    console.log(`Imported all ${retailers.length} active New York Lottery retailers.`);
  } catch (error) {
    console.error(`New York retailer-directory import stopped: ${error.message}`);
    process.exitCode = 1;
  }
}
