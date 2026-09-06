/*
 * Imports current qualifying NC winner claims from the official NC Education
 * Lottery Winners archive and matches them to the lottery's official Where To
 * Play retailer directory. The directory provides the retailer's published
 * street address, county, and exact map coordinate. Unmatched claims are
 * excluded rather than guessed.
 *
 * The official archive covers prizes of $5,000 and up. It is therefore a
 * current, verifiable activity feed—not a claim that every lower-value winner
 * is published by the NC Lottery.
 */
import {readFile, writeFile} from 'node:fs/promises';

const winnersUrl = 'https://nclottery.com/WinnersAll';
const directoryUrl = 'https://nclottery.com/Data/WhereToPlay.js.aspx';
const outputPath = process.argv[2];
const startYear = 2024;
const maxPagesPerGame = 160;

if (!outputPath) {
  console.error('Usage: node tooling/import_north_carolina_current_winners.mjs OUTPUT.json');
  process.exitCode = 1;
} else {
  const normalize = (value) => value.toLowerCase()
    .replace(/&nbsp;/g, ' ')
    .replace(/[^a-z0-9]/g, '');
  const decode = (value) => value.replace(/&nbsp;/g, ' ').replace(/&amp;/g, '&')
    .replace(/<[^>]+>/g, '').replace(/\s+/g, ' ').trim();
  const winnerLocation = (value) => decode(value)
    .replace(/\s*,\s*NC\s*$/i, '')
    .split(',')
    .map((part) => part.trim())
    .filter(Boolean);
  const games = [
    {code: 'PB', game: 'powerball', gameName: 'Powerball'},
    {code: 'MM', game: 'mega-millions', gameName: 'Mega Millions'},
    {code: 'C5', game: 'state-draw', gameName: 'Cash 5'},
    {code: 'P4', game: 'state-draw', gameName: 'Pick 4'},
    {code: 'I', game: 'scratch-off', gameName: 'Instant Scratchers'},
  ];

  const responseText = async (url) => {
    const response = await fetch(url, {headers: {'user-agent': 'LotteryAtlasOfficialDataBot/1.0'}});
    if (!response.ok) throw new Error(`${url} returned HTTP ${response.status}`);
    return response.text();
  };
  const parseDirectory = (script) => {
    const source = script.match(/locationsAll\s*=\s*(\[.*\])\s*;?\s*$/s)?.[1];
    if (!source) throw new Error('Official NC retailer directory was not found.');
    const directory = JSON.parse(source);
    const map = new Map();
    for (const entry of directory) {
      const [name, latitude, longitude, , zip, county, address, city] = entry;
      if (!name || !address || !city || !county || !Number.isFinite(latitude) || !Number.isFinite(longitude)) continue;
      map.set(`${normalize(name)}|${normalize(city)}`, {
        retailerName: name,
        latitude,
        longitude,
        address,
        city,
        county: `${county} County`,
        zip: String(zip ?? ''),
      });
    }
    return map;
  };
  const parseRows = (html, game) => {
    const rows = [];
    const pattern = /<td>\$([\d,]+)<\/td><td[^>]*>(\d{2}\/\d{2}\/\d{4})<\/td><td><a href="\/Winner\?id=(\d+)">.*?<\/a><\/td><td>(.*?)<\/td>/gs;
    for (const match of html.matchAll(pattern)) {
      const [, rawPrize, date, id, rawLocation] = match;
      const parts = winnerLocation(rawLocation);
      if (parts.length < 2 || /n\/a or other/i.test(rawLocation)) continue;
      const city = parts.at(-1);
      const retailerName = parts.slice(0, -1).join(', ');
      const year = Number(date.slice(-4));
      if (!city || !retailerName || year < startYear) continue;
      rows.push({
        id,
        date,
        city,
        retailerName,
        prizeAmount: Number(rawPrize.replaceAll(',', '')),
        ...game,
      });
    }
    return rows;
  };
  const dateValue = (date) => {
    const [month, day, year] = date.split('/').map(Number);
    return new Date(Date.UTC(year, month - 1, day, 12));
  };
  const buildRows = async (game) => {
    const rows = [];
    for (let page = 1; page <= maxPagesPerGame; page += 1) {
      const html = await responseText(`${winnersUrl}?g=${game.code}&p=${page}`);
      const pageRows = parseRows(html, game);
      if (!pageRows.length) break;
      rows.push(...pageRows);
      const oldest = Math.min(...pageRows.map((row) => Number(row.date.slice(-4))));
      if (oldest < startYear) break;
    }
    return rows;
  };

  try {
    const directory = parseDirectory(await responseText(directoryUrl));
    const rows = (await Promise.all(games.map(buildRows))).flat();
    const activities = [];
    const unmatched = new Set();
    for (const row of rows) {
      const retailer = directory.get(`${normalize(row.retailerName)}|${normalize(row.city)}`);
      if (!retailer) {
        unmatched.add(`${row.retailerName} — ${row.city}`);
        continue;
      }
      const date = dateValue(row.date);
      activities.push({
        id: `nc-winner-${row.id}`,
        latitude: retailer.latitude,
        longitude: retailer.longitude,
        city: retailer.city,
        county: retailer.county,
        state: 'NC',
        game: row.game,
        gameName: row.gameName,
        retailerName: row.retailerName,
        retailerAddress: `${retailer.address}, ${retailer.city}, NC ${retailer.zip}`.trim(),
        drawDate: date.toISOString(),
        winningTickets: 1,
        prizeAmount: row.prizeAmount,
        sourceUrl: `https://nclottery.com/Winner?id=${row.id}`,
        sourceLabel: `Official NC Education Lottery ${row.gameName} winner claim`,
      });
    }
    activities.sort((left, right) => left.id.localeCompare(right.id));
    const latest = activities.map((activity) => activity.drawDate).sort().at(-1);
    const output = {
      source: 'North Carolina Education Lottery official winner archive and retailer directory',
      updatedAt: new Date().toISOString(),
      sourceLastUpdated: latest ?? new Date().toISOString(),
      coverage: `Current qualifying NC Lottery prize claims from ${startYear} onward for the official archive's available game categories. ${activities.length} claims were matched to the official retailer directory with its published address and coordinates. ${unmatched.size} distinct published retailer names could not be matched exactly and were excluded.`,
      activities,
    };
    await writeFile(outputPath, `${JSON.stringify(output, null, 2)}\n`);
    console.log(`Imported ${activities.length} NC winner claims; ${unmatched.size} retailers were skipped for lack of an exact official directory match.`);
  } catch (error) {
    console.error(`NC winner import stopped: ${error.message}`);
    process.exitCode = 1;
  }
}
