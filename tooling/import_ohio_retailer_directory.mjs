/* Imports all active Ohio Lottery retailers with Lottery-published coordinates. */
import {readFile, writeFile} from 'node:fs/promises';

const loginUrl =
  'https://authapi-solutions.ohiolottery.com/1.0/Authentication/Login';
const apiUrl =
  'https://api-solutions.ohiolottery.com/1.0/Retailer/GetContentElementByFilters';
const sourceUrl = 'https://www.ohiolottery.com/retail-locations';
const applicationUrl = 'https://www.ohiolottery.com/dist/js/app.js';
const arcGisUrl =
  'https://geocode.arcgis.com/arcgis/rest/services/World/GeocodeServer/findAddressCandidates';
const outputPath = process.argv[2];
const countyGeometryPath = process.argv[3];

if (!outputPath || !countyGeometryPath) {
  console.error(
    'Usage: node tooling/import_ohio_retailer_directory.mjs OUTPUT.json assets/maps/us_counties.geojson',
  );
  process.exitCode = 1;
} else {
  const compact = (value) => String(value ?? '').replace(/\s+/g, ' ').trim();
  const titleCase = (value) => compact(value).toLowerCase().replace(
    /(^|[\s'/-])([a-z])/g,
    (_, prefix, letter) => `${prefix}${letter.toUpperCase()}`,
  );
  const responseJson = async (url, options = {}) => {
    const response = await fetch(url, {
      ...options,
      headers: {
        'user-agent': 'LotteryAtlasOfficialDataBot/1.0',
        ...(options.headers ?? {}),
      },
    });
    if (!response.ok) throw new Error(`${url} returned HTTP ${response.status}`);
    return response.json();
  };
  const token = async () => {
    const applicationResponse = await fetch(applicationUrl, {
      headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'},
    });
    if (!applicationResponse.ok) {
      throw new Error(`Ohio application returned HTTP ${applicationResponse.status}`);
    }
    const application = await applicationResponse.text();
    const credentials = application.match(
      /getNewAPItoken\(\)\{let \w="([^"]+)",\w="([^"]+)"/,
    );
    if (!credentials) throw new Error('Ohio public API credentials were unavailable');
    const payload = await responseJson(loginUrl, {
      method: 'POST',
      headers: {'content-type': 'application/json-patch+json'},
      body: JSON.stringify({
        userName: credentials[1],
        password: credentials[2],
      }),
    });
    if (!payload.data?.token) throw new Error('Ohio public API token was unavailable');
    return payload.data.token;
  };
  const existingOutput = async () => {
    try {
      return JSON.parse(await readFile(outputPath, 'utf8'));
    } catch (_) {
      return null;
    }
  };
  const inOhio = (latitude, longitude) =>
    latitude >= 38.3 && latitude <= 42.1 &&
    longitude >= -85 && longitude <= -80.4;
  const verifiedFallbackCoordinate = async (row) => {
    const url = new URL(arcGisUrl);
    url.searchParams.set(
      'SingleLine',
      `${compact(row.address)}, ${compact(row.city)}, OH ${compact(row.zip)}`,
    );
    url.searchParams.set('f', 'json');
    url.searchParams.set(
      'outFields',
      'Match_addr,Addr_type,City,RegionAbbr,Postal,Score',
    );
    url.searchParams.set('countryCode', 'USA');
    url.searchParams.set('maxLocations', '1');
    const payload = await responseJson(url);
    const candidate = payload.candidates?.[0];
    const attributes = candidate?.attributes ?? {};
    const officialHouseNumber = compact(row.address).match(/^\d+[A-Z-]*/i)?.[0]
      ?.toUpperCase();
    const matchedHouseNumber = compact(attributes.Match_addr).match(/^\d+[A-Z-]*/i)?.[0]
      ?.toUpperCase();
    const exactType = ['PointAddress', 'Subaddress'].includes(attributes.Addr_type);
    const verifiedStreet =
      ['StreetAddress', 'StreetAddressExt'].includes(attributes.Addr_type) &&
      candidate?.score >= 98 && officialHouseNumber &&
      officialHouseNumber === matchedHouseNumber;
    const latitude = Number(candidate?.location?.y);
    const longitude = Number(candidate?.location?.x);
    if (
      candidate?.score >= 95 && (exactType || verifiedStreet) &&
      attributes.RegionAbbr === 'OH' &&
      compact(attributes.Postal).slice(0, 5) === compact(row.zip).slice(0, 5) &&
      inOhio(latitude, longitude)
    ) {
      return {
        latitude,
        longitude,
        coordinateSource: exactType
          ? 'ArcGIS World Geocoder verified point address'
          : 'ArcGIS World Geocoder verified numbered street address',
      };
    }
    return null;
  };

  try {
    const geometry = JSON.parse(await readFile(countyGeometryPath, 'utf8'));
    const counties = geometry.features
      .filter((feature) => String(feature.properties?.STATEFP ?? '') === '39')
      .map((feature) => compact(feature.properties?.NAME))
      .filter(Boolean)
      .sort();
    if (counties.length !== 88) {
      throw new Error(`Expected 88 Ohio counties, found ${counties.length}`);
    }
    const bearer = await token();
    const byAgent = new Map();
    let nextCounty = 0;
    const worker = async () => {
      while (nextCounty < counties.length) {
        const county = counties[nextCounty++];
        const payload = await responseJson(apiUrl, {
          method: 'POST',
          headers: {
            authorization: `Bearer ${bearer}`,
            'content-type': 'application/json',
          },
          body: JSON.stringify({
            businessName: '', addressCity: '', county, zip: '',
            latitude: 0, longitude: 0, ticketCashAmount: 0,
          }),
        });
        if (!Array.isArray(payload.data)) {
          throw new Error(`${county} County returned no official retailer list`);
        }
        for (const row of payload.data) {
          if (compact(row.agentStatus).toUpperCase() === 'ACTIVE') {
            byAgent.set(compact(row.agentNumber), row);
          }
        }
      }
    };
    await Promise.all(Array.from({length: 6}, worker));
    if (byAgent.size < 9000) {
      throw new Error(`Only ${byAgent.size} active Ohio retailers were returned`);
    }
    const rows = [...byAgent.values()];
    const coordinates = new Map();
    const unresolvedRows = [];
    let nextRow = 0;
    const coordinateWorker = async () => {
      while (nextRow < rows.length) {
        const index = nextRow++;
        const row = rows[index];
        let latitude = Number(row.latitude);
        let longitude = Number(row.longitude);
        let coordinateSource = 'Ohio Lottery published retailer coordinate';
        if (!inOhio(latitude, longitude) && inOhio(longitude, latitude)) {
          [latitude, longitude] = [longitude, latitude];
          coordinateSource = 'Ohio Lottery published coordinate with verified axis correction';
        }
        if (!inOhio(latitude, longitude)) {
          const fallback = await verifiedFallbackCoordinate(row);
          if (fallback) {
            ({latitude, longitude, coordinateSource} = fallback);
          } else {
            unresolvedRows.push(row);
            continue;
          }
        }
        coordinates.set(compact(row.agentNumber), {
          latitude, longitude, coordinateSource,
        });
      }
    };
    await Promise.all(Array.from({length: 6}, coordinateWorker));
    const retailers = rows.filter((row) =>
      coordinates.has(compact(row.agentNumber)),
    ).map((row) => {
      const coordinate = coordinates.get(compact(row.agentNumber));
      const {latitude, longitude, coordinateSource} = coordinate;
      if (
        !compact(row.agentNumber) || !compact(row.businessName) ||
        !compact(row.address) || !compact(row.city) || !compact(row.zip) ||
        !compact(row.county) || !Number.isFinite(latitude) ||
        !Number.isFinite(longitude) || latitude === 0 || longitude === 0
      ) {
        throw new Error(`Incomplete official Ohio retailer ${row.agentNumber ?? '?'}`);
      }
      return {
        id: `oh-${compact(row.agentNumber)}`,
        name: compact(row.businessName),
        address: titleCase(row.address),
        city: titleCase(row.city),
        postalCode: compact(row.zip).slice(0, 5),
        county: `${titleCase(row.county)} County`,
        latitude,
        longitude,
        coordinateSource,
      };
    }).sort((a, b) => a.id.localeCompare(b.id));
    const unresolvedRetailers = unresolvedRows.map((row) => ({
      id: `oh-${compact(row.agentNumber)}`,
      name: compact(row.businessName),
      address: titleCase(row.address),
      city: titleCase(row.city),
      postalCode: compact(row.zip).slice(0, 5),
      county: `${titleCase(row.county)} County`,
      reason: 'Official coordinate is outside Ohio and no exact fallback match was verified',
    })).sort((a, b) => a.id.localeCompare(b.id));
    const directories = [{
      state: 'Ohio', source: sourceUrl, retailers, unresolvedRetailers,
    }];
    const existing = await existingOutput();
    const changed = JSON.stringify(existing?.directories) !== JSON.stringify(directories);
    const retrievedAt = changed
      ? new Date().toISOString()
      : existing?.retrievedAt ?? existing?.updatedAt ?? new Date().toISOString();
    await writeFile(outputPath, `${JSON.stringify({
      source: 'Ohio Lottery official active retailer finder API',
      retrievedAt,
      coverage:
        `${retailers.length} active retailers with exact verified coordinates across ` +
        `Ohio's 88 counties. ${unresolvedRetailers.length} official rows were retained ` +
        'as unresolved and are not exposed on the map.',
      directories,
    }, null, 2)}\n`);
    console.log(`Imported ${retailers.length} active Ohio Lottery retailers.`);
  } catch (error) {
    console.error(`Ohio retailer import stopped: ${error.message}`);
    process.exitCode = 1;
  }
}
