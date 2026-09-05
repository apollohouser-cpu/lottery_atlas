/*
 * Builds bundled NC Powerball/Mega Millions history from primary sources.
 * NC's current "Instant" archive resolves to Keno claims, so it is not used
 * as a Scratch-Off heat-map source.
 */
import {readFile, writeFile} from 'node:fs/promises';

const winnersUrl = 'https://nclottery.com/WinnersAll';
const gazetteerUrl =
  'https://www2.census.gov/geo/docs/maps-data/data/gazetteer/2025_Gazetteer/2025_gaz_place_37.txt';
const counties = JSON.parse(
  await readFile(new URL('../assets/maps/us_counties.geojson', import.meta.url)),
);
const normalize = (value) => value.toLowerCase()
  .replace(/\b(city|town|village|cdp|municipality)\b/g, '')
  .replace(/[^a-z0-9]/g, '');

const places = new Map();
const gazetteer = await (await fetch(gazetteerUrl)).text();
for (const line of gazetteer.trim().split(/\r?\n/).slice(1)) {
  const fields = line.split('|');
  const name = fields[4]?.replace(/\s+(city|town|village|CDP|municipality)$/i, '');
  const latitude = Number(fields[11]);
  const longitude = Number(fields[12]);
  if (name && Number.isFinite(latitude) && Number.isFinite(longitude)) {
    places.set(normalize(name), {latitude, longitude});
  }
}
const ncCounties = counties.features.filter((feature) => feature.properties?.STATEFP === '37');

function ringContains(longitude, latitude, ring) {
  let inside = false;
  for (let i = 0, previous = ring.length - 1; i < ring.length; previous = i++) {
    const [x, y] = ring[i];
    const [previousX, previousY] = ring[previous];
    if ((y > latitude) !== (previousY > latitude) &&
        longitude < ((previousX - x) * (latitude - y)) / (previousY - y) + x) {
      inside = !inside;
    }
  }
  return inside;
}
function countyFor(longitude, latitude) {
  for (const feature of ncCounties) {
    const polygons = feature.geometry.type === 'Polygon'
      ? [feature.geometry.coordinates]
      : feature.geometry.coordinates;
    if (polygons.some((polygon) =>
      ringContains(longitude, latitude, polygon[0]) &&
      !polygon.slice(1).some((hole) => ringContains(longitude, latitude, hole)))) {
      return feature.properties.NAME;
    }
  }
  return null;
}
function decode(value) {
  return value.replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&')
    .replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();
}
function parseRows(html) {
  const rows = [];
  const pattern = /<td>\$([\d,]+)<\/td><td[^>]*>(\d{2}\/\d{2}\/\d{4})<\/td><td><a href="\/Winner\?id=(\d+)">.*?<\/a><\/td><td>(.*?)<\/td>/gs;
  for (const match of html.matchAll(pattern)) {
    const [, rawPrize, date, id, sourceLocation] = match;
    const location = decode(sourceLocation);
    if (/n\/a or other/i.test(location)) continue;
    const city = location.split(',').map((part) => part.trim()).at(-2);
    if (city) rows.push({id, city, date, prizeAmount: Number(rawPrize.replaceAll(',', ''))});
  }
  return rows;
}

const games = [
  {code: 'PB', game: 'powerball', gameName: 'Powerball'},
  {code: 'MM', game: 'mega-millions', gameName: 'Mega Millions'},
];
const allRows = (await Promise.all(games.map(async (game) => {
  const pages = await Promise.all(Array.from({length: 14}, async (_, index) => {
    const response = await fetch(`${winnersUrl}?g=${game.code}&p=${index + 1}`);
    return response.ok ? parseRows(await response.text()) : [];
  }));
  return pages.flat().map((row) => ({...row, ...game}));
}))).flat();

const activities = [];
const skippedCities = new Set();
for (const winner of allRows) {
  const year = Number(winner.date.slice(-4));
  if (year < 2016) continue;
  const place = places.get(normalize(winner.city));
  const county = place && countyFor(place.longitude, place.latitude);
  if (!place || !county) {
    skippedCities.add(winner.city);
    continue;
  }
  const [month, day] = winner.date.split('/');
  activities.push({
    id: `nc-${winner.code.toLowerCase()}-${winner.id}`,
    latitude: place.latitude,
    longitude: place.longitude,
    city: winner.city,
    county: `${county} County`,
    state: 'NC',
    game: winner.game,
    gameName: winner.gameName,
    drawDate: `${year}-${month}-${day}T12:00:00Z`,
    winningTickets: 1,
    prizeAmount: winner.prizeAmount,
    sourceUrl: `https://nclottery.com/Winner?id=${winner.id}`,
    sourceLabel: `Official NC Education Lottery ${winner.gameName} winner claim`,
    isHistorical: true,
  });
}

const output = {
  source: 'North Carolina Education Lottery official national winner claims',
  updatedAt: new Date().toISOString(),
  sourceLastUpdated: new Date().toISOString(),
  coverage: `Verified NC Powerball and Mega Millions winner claims of $5,000 and above from the official winners archive, covering 2016 through 2026. ${activities.length} records with published retailer cities were mapped to Census place centroids and county boundaries.`,
  activities,
};
await writeFile(
  new URL('../data/north_carolina_national_history.initial.json', import.meta.url),
  `${JSON.stringify(output, null, 2)}\n`,
);
console.log(`Wrote ${activities.length} NC national-draw records.`);
if (skippedCities.size) console.log(`Skipped: ${[...skippedCities].join(', ')}`);
