/*
 * Imports the Kentucky Lottery's official statewide retailer directory.
 *
 * The public retailer finder requires a location query, so this importer uses
 * the 120 Kentucky county names from the bundled U.S. Census county geometry
 * and queries every county. The official response supplies retailer name,
 * street address, city, ZIP, and county. Exact U.S. Census address matches
 * provide coordinates; unresolved addresses are excluded rather than placed
 * approximately.
 */
import {createHash} from 'node:crypto';
import {readFile, writeFile} from 'node:fs/promises';

const retailerUrl =
  'https://www.kylottery.com/webhandlers/CashingAgentsInfo.xhtml';
const sourceUrl =
  'https://www.kylottery.com/apps/customer_service/find_retailer.html';
const censusBatchUrl =
  'https://geocoding.geo.census.gov/geocoder/locations/addressbatch';
const arcGisUrl =
  'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates';
const outputPath = process.argv[2];
const countiesPath = process.argv[3] ?? 'assets/maps/us_counties.geojson';

if (!outputPath) {
  console.error(
    'Usage: node tooling/import_kentucky_retailer_directory.mjs OUTPUT.json [COUNTIES.geojson]',
  );
  process.exitCode = 1;
} else {
  const titleCase = (value) => value.toLowerCase().replace(
    /(^|[\s'/-])([a-z])/g,
    (_, prefix, letter) => `${prefix}${letter.toUpperCase()}`,
  );
  const compact = (value) => value.replace(/\s+/g, ' ').trim();
  const keyFor = (retailer) => [
    retailer.NAME,
    retailer.ADDRESS1,
    retailer.CITY,
    retailer.ZIP,
  ].map((part) => compact(part ?? '').toUpperCase()).join('|');
  const csvCell = (value) => `"${String(value).replaceAll('"', '""')}"`;

  const parseCsv = (line) => {
    const cells = [];
    let cell = '';
    let quoted = false;
    for (let index = 0; index < line.length; index++) {
      const character = line[index];
      if (character === '"') {
        if (quoted && line[index + 1] === '"') {
          cell += '"';
          index++;
        } else {
          quoted = !quoted;
        }
      } else if (character === ',' && !quoted) {
        cells.push(cell);
        cell = '';
      } else {
        cell += character;
      }
    }
    cells.push(cell);
    return cells;
  };

  const postCounty = async (county) => {
    const endpointCounty = /^Mc[A-Z]/.test(county)
      ? `MC ${county.slice(2).toUpperCase()}`
      : county;
    let lastError;
    for (let attempt = 1; attempt <= 3; attempt++) {
      try {
        const response = await fetch(retailerUrl, {
          method: 'POST',
          headers: {
            'content-type': 'application/json',
            'user-agent': 'LotteryAtlasOfficialDataBot/1.0',
          },
          body: JSON.stringify({
            id: '',
            LocationSelect: 'County',
            county: endpointCounty,
            CashingAgent: 'N',
          }),
        });
        if (!response.ok) {
          throw new Error(`HTTP ${response.status}`);
        }
        const json = await response.json();
        if (!Array.isArray(json.RETAILERS)) {
          throw new Error('response did not include RETAILERS');
        }
        return json.RETAILERS;
      } catch (error) {
        lastError = error;
        if (attempt < 3) {
          await new Promise((resolve) => setTimeout(resolve, attempt * 500));
        }
      }
    }
    throw new Error(`${county} County retailer query failed: ${lastError.message}`);
  };

  const geocodeBatch = async (retailers) => {
    const csv = retailers.map((retailer, index) => [
      index,
      retailer.ADDRESS1,
      retailer.CITY,
      'KY',
      retailer.ZIP,
    ].map(csvCell).join(',')).join('\n');
    const form = new FormData();
    form.set('benchmark', 'Public_AR_Current');
    form.set(
      'addressFile',
      new Blob([`${csv}\n`], {type: 'text/csv'}),
      'kentucky-retailers.csv',
    );
    const response = await fetch(censusBatchUrl, {
      method: 'POST',
      headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'},
      body: form,
    });
    if (!response.ok) {
      throw new Error(`Census batch geocoder returned HTTP ${response.status}`);
    }
    const coordinates = new Map();
    for (const line of (await response.text()).split(/\r?\n/)) {
      if (!line.trim()) continue;
      const cells = parseCsv(line);
      const index = Number(cells[0]);
      const status = cells[2];
      const matchType = cells[3];
      const point = cells[5]?.split(',').map(Number);
      if (
        status === 'Match' &&
        matchType === 'Exact' &&
        Number.isInteger(index) &&
        point?.length === 2 &&
        Number.isFinite(point[0]) &&
        Number.isFinite(point[1])
      ) {
        coordinates.set(index, {
          longitude: point[0],
          latitude: point[1],
          coordinateSource: 'U.S. Census Geocoder exact address match',
        });
      }
    }
    return coordinates;
  };

  const geocodeArcGis = async (retailer) => {
    const url = new URL(arcGisUrl);
    url.searchParams.set(
      'SingleLine',
      `${retailer.ADDRESS1}, ${retailer.CITY}, KY ${retailer.ZIP}`,
    );
    url.searchParams.set('f', 'json');
    url.searchParams.set(
      'outFields',
      'Match_addr,Addr_type,City,RegionAbbr,Postal,Score',
    );
    url.searchParams.set('countryCode', 'USA');
    url.searchParams.set('maxLocations', '1');

    let lastError;
    for (let attempt = 1; attempt <= 3; attempt++) {
      try {
        const response = await fetch(url, {
          headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'},
        });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        const candidate = (await response.json()).candidates?.[0];
        const attributes = candidate?.attributes ?? {};
        const addressType = attributes.Addr_type;
        const postal = compact(attributes.Postal ?? '').slice(0, 5);
        const location = candidate?.location;
        const isPointAddress =
          addressType === 'PointAddress' || addressType === 'Subaddress';
        const officialHouseNumber = compact(retailer.ADDRESS1).match(/^\d+[A-Z-]*/i)?.[0]
          ?.toUpperCase();
        const matchedHouseNumber = compact(attributes.Match_addr ?? '').match(/^\d+[A-Z-]*/i)?.[0]
          ?.toUpperCase();
        const isVerifiedStreetAddress =
          (addressType === 'StreetAddress' || addressType === 'StreetAddressExt') &&
          candidate.score >= 98 &&
          officialHouseNumber &&
          officialHouseNumber === matchedHouseNumber;
        if (
          candidate?.score >= 95 &&
          (isPointAddress || isVerifiedStreetAddress) &&
          attributes.RegionAbbr === 'KY' &&
          postal === compact(retailer.ZIP).slice(0, 5) &&
          Number.isFinite(location?.x) &&
          Number.isFinite(location?.y)
        ) {
          return {
            longitude: location.x,
            latitude: location.y,
            coordinateSource: isPointAddress
              ? 'ArcGIS World Geocoder verified point address'
              : 'ArcGIS World Geocoder verified numbered street address',
          };
        }
        return null;
      } catch (error) {
        lastError = error;
        if (attempt < 3) {
          await new Promise((resolve) => setTimeout(resolve, attempt * 750));
        }
      }
    }
    throw new Error(`ArcGIS geocoder failed: ${lastError.message}`);
  };

  const restoreExistingOutput = async () => {
    try {
      return JSON.parse(await readFile(outputPath, 'utf8'));
    } catch (_) {
      return null;
    }
  };

  try {
    const countyGeoJson = JSON.parse(await readFile(countiesPath, 'utf8'));
    const countyNames = countyGeoJson.features
      .filter((feature) => feature.properties?.STATEFP === '21')
      .map((feature) => feature.properties.NAME)
      .sort();
    if (countyNames.length !== 120 || new Set(countyNames).size !== 120) {
      throw new Error(`Expected 120 official Kentucky counties, found ${countyNames.length}`);
    }

    const countyResults = new Array(countyNames.length);
    let nextCounty = 0;
    const worker = async () => {
      while (nextCounty < countyNames.length) {
        const index = nextCounty++;
        countyResults[index] = await postCounty(countyNames[index]);
      }
    };
    await Promise.all(Array.from({length: 8}, worker));

    const officialRetailers = [];
    const seen = new Set();
    for (const retailer of countyResults.flat()) {
      const key = keyFor(retailer);
      if (
        !retailer.NAME ||
        !retailer.ADDRESS1 ||
        !retailer.CITY ||
        !retailer.ZIP ||
        !retailer.COUNTY ||
        !seen.add(key)
      ) {
        continue;
      }
      officialRetailers.push(retailer);
    }
    if (officialRetailers.length < 3000) {
      throw new Error(
        `Only ${officialRetailers.length} official Kentucky retailers were returned`,
      );
    }

    const existingOutput = await restoreExistingOutput();
    const coordinateCache = new Map(
      (existingOutput?.directories?.[0]?.retailers ?? []).map((retailer) => [
        [retailer.name, retailer.address, retailer.city, retailer.postalCode]
          .map((part) => compact(part ?? '').toUpperCase()).join('|'),
        {
          latitude: retailer.latitude,
          longitude: retailer.longitude,
          coordinateSource:
            retailer.coordinateSource ?? 'U.S. Census Geocoder exact address match',
        },
      ]),
    );
    const missing = officialRetailers.filter(
      (retailer) => !coordinateCache.has(keyFor(retailer)),
    );
    for (let offset = 0; offset < missing.length; offset += 1000) {
      const batch = missing.slice(offset, offset + 1000);
      const coordinates = await geocodeBatch(batch);
      for (const [index, coordinate] of coordinates) {
        coordinateCache.set(keyFor(batch[index]), coordinate);
      }
    }

    const arcGisMissing = officialRetailers.filter(
      (retailer) => !coordinateCache.has(keyFor(retailer)),
    );
    let nextAddress = 0;
    const arcGisWorker = async () => {
      while (nextAddress < arcGisMissing.length) {
        const index = nextAddress++;
        const retailer = arcGisMissing[index];
        const coordinate = await geocodeArcGis(retailer);
        if (coordinate) coordinateCache.set(keyFor(retailer), coordinate);
      }
    };
    await Promise.all(Array.from({length: 6}, arcGisWorker));

    const retailers = officialRetailers.flatMap((retailer) => {
      const coordinate = coordinateCache.get(keyFor(retailer));
      if (!coordinate) return [];
      const identity = createHash('sha256')
        .update(keyFor(retailer))
        .digest('hex')
        .slice(0, 16);
      return [{
        id: `ky-${identity}`,
        name: compact(retailer.NAME),
        address: titleCase(compact(retailer.ADDRESS1)),
        city: titleCase(compact(retailer.CITY)),
        postalCode: compact(retailer.ZIP),
        county: `${titleCase(compact(retailer.COUNTY).replace(/^MC /, 'Mc'))} County`,
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
        coordinateSource: coordinate.coordinateSource,
      }];
    }).sort((left, right) => left.id.localeCompare(right.id));

    const missingCoordinates = officialRetailers.length - retailers.length;
    const unresolvedRetailers = officialRetailers.flatMap((retailer) => {
      if (coordinateCache.has(keyFor(retailer))) return [];
      return [{
        name: compact(retailer.NAME),
        address: titleCase(compact(retailer.ADDRESS1)),
        city: titleCase(compact(retailer.CITY)),
        postalCode: compact(retailer.ZIP),
        county: `${titleCase(compact(retailer.COUNTY).replace(/^MC /, 'Mc'))} County`,
        reason: 'No precise address-level coordinate passed verification',
      }];
    }).sort((left, right) => [left.name, left.address]
      .join('|')
      .localeCompare([right.name, right.address].join('|')));
    const directories = [{
      state: 'Kentucky',
      source: sourceUrl,
      retailers,
      unresolvedRetailers,
    }];
    const directoryChanged =
      JSON.stringify(existingOutput?.directories ?? null) !==
      JSON.stringify(directories);
    const output = {
      source: 'Kentucky Lottery official statewide retailer finder',
      retrievedAt: directoryChanged
        ? new Date().toISOString()
        : existingOutput.retrievedAt,
      coverage:
        `Queried every one of Kentucky's 120 counties. The official directory ` +
        `returned ${officialRetailers.length} unique retailers; ${retailers.length} ` +
        'received exact Census or verified ArcGIS point-address coordinates. ' +
        `${missingCoordinates} unresolved addresses were excluded rather than estimated.`,
      directories,
    };
    await writeFile(outputPath, `${JSON.stringify(output, null, 2)}\n`);
    console.log(
      `Imported ${retailers.length}/${officialRetailers.length} Kentucky retailers; ` +
      `${missingCoordinates} exact coordinates unresolved.`,
    );
  } catch (error) {
    console.error(`Kentucky retailer-directory import stopped: ${error.message}`);
    process.exitCode = 1;
  }
}
