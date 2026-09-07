/*
 * Imports the Virginia Lottery's official statewide retailer directory.
 * Every county/city option published by the official finder is queried.
 * Only exact Census matches or strictly verified ArcGIS address matches are
 * mappable; unresolved official rows are retained separately and never
 * assigned an estimated location.
 */
import {createHash} from 'node:crypto';
import {readFile, writeFile} from 'node:fs/promises';

const sourceUrl = 'https://www.valottery.com/aboutus/findaretailer';
const retailerApiUrl = 'https://www.valottery.com/api/v1/retailers';
const censusBatchUrl =
  'https://geocoding.geo.census.gov/geocoder/locations/addressbatch';
const arcGisUrl =
  'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates';
const outputPath = process.argv[2];

if (!outputPath) {
  console.error(
    'Usage: node tooling/import_virginia_retailer_directory.mjs OUTPUT.json',
  );
  process.exitCode = 1;
} else {
  const compact = (value) => String(value ?? '').replace(/\s+/g, ' ').trim();
  const titleCase = (value) => compact(value).toLowerCase().replace(
    /(^|[\s'/-])([a-z])/g,
    (_, prefix, letter) => `${prefix}${letter.toUpperCase()}`,
  );
  const keyFor = (retailer) => [
    retailer.Name,
    retailer.Street,
    retailer.City,
    retailer.Zip,
  ].map((part) => compact(part).toUpperCase()).join('|');
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
  const fetchWithRetry = async (url, options = {}) => {
    let lastError;
    for (let attempt = 1; attempt <= 3; attempt++) {
      try {
        const response = await fetch(url, {
          ...options,
          headers: {
            'user-agent': 'LotteryAtlasOfficialDataBot/1.0',
            ...(options.headers ?? {}),
          },
        });
        if (!response.ok) throw new Error(`HTTP ${response.status}`);
        return response;
      } catch (error) {
        lastError = error;
        if (attempt < 3) {
          await new Promise((resolve) => setTimeout(resolve, attempt * 600));
        }
      }
    }
    throw new Error(`${url} failed: ${lastError.message}`);
  };
  const countiesFromFinder = async () => {
    const html = await (await fetchWithRetry(sourceUrl)).text();
    const counties = [...html.matchAll(
      /<option\s+value="([^"]+)"[^>]*>[^<]*<\/option>/gi,
    )].map((match) => compact(match[1])).filter(Boolean);
    if (counties.length < 130 || new Set(counties).size !== counties.length) {
      throw new Error(`Expected at least 130 official county/city options, found ${counties.length}`);
    }
    return counties;
  };
  const retailersForCounty = async (county) => {
    const response = await fetchWithRetry(retailerApiUrl, {
      method: 'POST',
      headers: {'content-type': 'application/json'},
      body: JSON.stringify({
        page: 0,
        totalPages: 0,
        pageSize: 5000,
        zipCode: '',
        county,
        onlyWithVendingMachines: false,
      }),
    });
    const payload = await response.json();
    if (
      !Array.isArray(payload.data) ||
      (payload.data.length > 0 && payload.totalPages !== 1) ||
      (payload.data.length === 0 && ![0, 1].includes(payload.totalPages))
    ) {
      throw new Error(`${county} did not return one complete official page`);
    }
    return payload.data;
  };
  const geocodeBatch = async (retailers) => {
    const csv = retailers.map((retailer, index) => [
      index,
      retailer.Street,
      retailer.City,
      'VA',
      retailer.Zip,
    ].map(csvCell).join(',')).join('\n');
    const form = new FormData();
    form.set('benchmark', 'Public_AR_Current');
    form.set(
      'addressFile',
      new Blob([`${csv}\n`], {type: 'text/csv'}),
      'virginia-retailers.csv',
    );
    const response = await fetchWithRetry(censusBatchUrl, {
      method: 'POST',
      body: form,
    });
    const coordinates = new Map();
    for (const line of (await response.text()).split(/\r?\n/)) {
      if (!line.trim()) continue;
      const cells = parseCsv(line);
      const index = Number(cells[0]);
      const point = cells[5]?.split(',').map(Number);
      if (
        cells[2] === 'Match' &&
        cells[3] === 'Exact' &&
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
      `${retailer.Street}, ${retailer.City}, VA ${retailer.Zip}`,
    );
    url.searchParams.set('f', 'json');
    url.searchParams.set(
      'outFields',
      'Match_addr,Addr_type,City,RegionAbbr,Postal,Score',
    );
    url.searchParams.set('countryCode', 'USA');
    url.searchParams.set('maxLocations', '1');
    const payload = await (await fetchWithRetry(url)).json();
    const candidate = payload.candidates?.[0];
    const attributes = candidate?.attributes ?? {};
    const officialHouseNumber = compact(retailer.Street).match(/^\d+[A-Z-]*/i)?.[0]
      ?.toUpperCase();
    const matchedHouseNumber = compact(attributes.Match_addr).match(/^\d+[A-Z-]*/i)?.[0]
      ?.toUpperCase();
    const isPointAddress =
      attributes.Addr_type === 'PointAddress' || attributes.Addr_type === 'Subaddress';
    const isVerifiedStreetAddress =
      ['StreetAddress', 'StreetAddressExt'].includes(attributes.Addr_type) &&
      candidate?.score >= 98 &&
      officialHouseNumber &&
      officialHouseNumber === matchedHouseNumber;
    const postal = compact(attributes.Postal).slice(0, 5);
    if (
      candidate?.score >= 95 &&
      (isPointAddress || isVerifiedStreetAddress) &&
      attributes.RegionAbbr === 'VA' &&
      postal === compact(retailer.Zip).slice(0, 5) &&
      Number.isFinite(candidate.location?.x) &&
      Number.isFinite(candidate.location?.y)
    ) {
      return {
        longitude: candidate.location.x,
        latitude: candidate.location.y,
        coordinateSource: isPointAddress
          ? 'ArcGIS World Geocoder verified point address'
          : 'ArcGIS World Geocoder verified numbered street address',
      };
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
  const outputCounty = (value) => titleCase(value).replace(/\s+\(city\)$/i, ' (City)');

  try {
    const counties = await countiesFromFinder();
    const countyResults = new Array(counties.length);
    let nextCounty = 0;
    const countyWorker = async () => {
      while (nextCounty < counties.length) {
        const index = nextCounty++;
        countyResults[index] = await retailersForCounty(counties[index]);
      }
    };
    await Promise.all(Array.from({length: 8}, countyWorker));

    const officialRetailers = [];
    const seen = new Set();
    for (const retailer of countyResults.flat()) {
      const key = keyFor(retailer);
      if (
        !retailer.Name ||
        !retailer.Street ||
        !retailer.City ||
        !retailer.Zip ||
        !retailer.Description ||
        !seen.add(key)
      ) continue;
      officialRetailers.push(retailer);
    }
    if (officialRetailers.length < 5000) {
      throw new Error(`Only ${officialRetailers.length} unique official retailers were returned`);
    }

    const existing = await existingOutput();
    const coordinateCache = new Map(
      (existing?.directories?.[0]?.retailers ?? []).map((retailer) => [
        [retailer.name, retailer.address, retailer.city, retailer.postalCode]
          .map((part) => compact(part).toUpperCase()).join('|'),
        {
          latitude: retailer.latitude,
          longitude: retailer.longitude,
          coordinateSource: retailer.coordinateSource,
        },
      ]),
    );
    const censusMissing = officialRetailers.filter(
      (retailer) => !coordinateCache.has(keyFor(retailer)),
    );
    for (let offset = 0; offset < censusMissing.length; offset += 1000) {
      const batch = censusMissing.slice(offset, offset + 1000);
      const coordinates = await geocodeBatch(batch);
      for (const [index, coordinate] of coordinates) {
        coordinateCache.set(keyFor(batch[index]), coordinate);
      }
    }

    const arcGisMissing = officialRetailers.filter(
      (retailer) => !coordinateCache.has(keyFor(retailer)),
    );
    let nextAddress = 0;
    const addressWorker = async () => {
      while (nextAddress < arcGisMissing.length) {
        const retailer = arcGisMissing[nextAddress++];
        const coordinate = await geocodeArcGis(retailer);
        if (coordinate) coordinateCache.set(keyFor(retailer), coordinate);
      }
    };
    await Promise.all(Array.from({length: 8}, addressWorker));

    const retailers = officialRetailers.flatMap((retailer) => {
      const coordinate = coordinateCache.get(keyFor(retailer));
      if (!coordinate) return [];
      const identity = createHash('sha256')
        .update(keyFor(retailer))
        .digest('hex')
        .slice(0, 16);
      return [{
        id: `va-${identity}`,
        name: compact(retailer.Name),
        address: titleCase(retailer.Street),
        city: titleCase(retailer.City),
        postalCode: compact(retailer.Zip),
        county: outputCounty(retailer.Description),
        latitude: coordinate.latitude,
        longitude: coordinate.longitude,
        coordinateSource: coordinate.coordinateSource,
      }];
    }).sort((left, right) => left.id.localeCompare(right.id));
    const unresolvedRetailers = officialRetailers.flatMap((retailer) => {
      if (coordinateCache.has(keyFor(retailer))) return [];
      return [{
        name: compact(retailer.Name),
        address: titleCase(retailer.Street),
        city: titleCase(retailer.City),
        postalCode: compact(retailer.Zip),
        county: outputCounty(retailer.Description),
        reason: 'No precise address-level coordinate passed verification',
      }];
    }).sort((left, right) => [left.name, left.address]
      .join('|').localeCompare([right.name, right.address].join('|')));

    const directories = [{
      state: 'Virginia',
      source: sourceUrl,
      retailers,
      unresolvedRetailers,
    }];
    const directoryChanged =
      JSON.stringify(existing?.directories ?? null) !== JSON.stringify(directories);
    const retrievedAt = directoryChanged
      ? new Date().toISOString()
      : existing?.retrievedAt;
    const output = {
      source: 'Virginia Lottery official statewide retailer finder',
      retrievedAt,
      coverage:
        `Queried all ${counties.length} county/city options in the official Virginia ` +
        `Lottery finder. It returned ${officialRetailers.length} unique retailers; ` +
        `${retailers.length} received exact Census or verified ArcGIS address ` +
        `coordinates. ${unresolvedRetailers.length} unresolved addresses were ` +
        'excluded from the map rather than estimated.',
      directories,
    };
    await writeFile(outputPath, `${JSON.stringify(output, null, 2)}\n`);
    console.log(
      `Imported ${retailers.length}/${officialRetailers.length} Virginia retailers; ` +
      `${unresolvedRetailers.length} exact coordinates unresolved.`,
    );
  } catch (error) {
    console.error(`Virginia retailer-directory import stopped: ${error.message}`);
    process.exitCode = 1;
  }
}
