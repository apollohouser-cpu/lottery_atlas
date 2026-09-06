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
const newsUrl = 'https://nclottery.com/News';
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
  const plainText = (value) => decode(value)
    .replace(/&#8216;|&#8217;|[‘’]/g, "'")
    .replace(/&#8211;|&#8212;|[–—]/g, '-');
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
    const locations = [];
    for (const entry of directory) {
      const [name, latitude, longitude, , zip, county, address, city] = entry;
      if (!name || !address || !city || !county || !Number.isFinite(latitude) || !Number.isFinite(longitude)) continue;
      const location = {
        retailerName: name,
        latitude,
        longitude,
        address,
        city,
        county: `${county} County`,
        zip: String(zip ?? ''),
      };
      map.set(`${normalize(name)}|${normalize(city)}`, location);
      locations.push(location);
    }
    return {map, locations};
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

  const newsIndex = (html) => {
    const articles = [];
    const pattern = /<h6>\s*([A-Za-z]+\s+\d{1,2},\s+\d{4})\s+By NCEL\s*<\/h6>\s*<h3><a[^>]+href="([^"]+)"[^>]*>(.*?)<\/a>/gs;
    for (const match of html.matchAll(pattern)) {
      const [, published, href, title] = match;
      const date = new Date(`${published} 12:00:00 UTC`);
      if (Number.isNaN(date.valueOf()) || date.getUTCFullYear() < startYear) continue;
      articles.push({
        published: date,
        href: new URL(href, newsUrl).toString(),
        title: plainText(title),
      });
    }
    return articles;
  };
  const prizeFrom = (text) => {
    const match = text.match(/\$([\d,]+(?:\.\d+)?)\s*(million|billion)?/i);
    if (!match) return null;
    const base = Number(match[1].replaceAll(',', ''));
    if (!Number.isFinite(base)) return null;
    const multiplier = match[2]?.toLowerCase() === 'billion' ? 1000000000 :
      match[2]?.toLowerCase() === 'million' ? 1000000 : 1;
    return base * multiplier;
  };
  const gameFrom = (text) => {
    if (/powerball/i.test(text)) return {game: 'powerball', gameName: 'Powerball'};
    if (/mega\s+millions/i.test(text)) return {game: 'mega-millions', gameName: 'Mega Millions'};
    if (/scratch-?off|scratch off/i.test(text)) return {game: 'scratch-off', gameName: 'Scratch-Off'};
    if (/cash\s*5|pick\s*[34]|cash\s*pop|fast\s*play|keno/i.test(text)) {
      return {game: 'state-draw', gameName: 'NC Lottery drawing'};
    }
    return null;
  };
  const abbreviateRoad = (value) => normalize(value)
    .replaceAll('west', 'w')
    .replaceAll('east', 'e')
    .replaceAll('north', 'n')
    .replaceAll('south', 's')
    .replaceAll('highway', 'hwy')
    .replaceAll('boulevard', 'blvd')
    .replaceAll('street', 'st')
    .replaceAll('avenue', 'ave')
    .replaceAll('road', 'rd');
  const resolveNewsRetailer = (directory, retailerName, streetHint, city) => {
    const name = normalize(retailerName);
    const locationCity = normalize(city);
    const street = abbreviateRoad(streetHint);
    const candidates = directory.locations.filter((location) => {
      const candidateName = normalize(location.retailerName);
      return normalize(location.city) === locationCity &&
        (candidateName === name || candidateName.includes(name) || name.includes(candidateName));
    });
    const scored = candidates.map((location) => {
      const candidateStreet = abbreviateRoad(location.address);
      let score = 0;
      if (candidateStreet.includes(street) || street.includes(candidateStreet)) score += 20;
      for (const token of street.match(/\d+|[a-z]+/g) ?? []) {
        if (token.length > 1 && candidateStreet.includes(token)) score += 2;
      }
      return {location, score};
    }).sort((left, right) => right.score - left.score);
    if (!scored.length || !scored[0].score ||
      (scored[1] && scored[0].score === scored[1].score)) return null;
    return scored[0].location;
  };
  const retailerFromNews = (text) => {
    const patterns = [
      /(?:bought|purchased|picked up|got).*?\b(?:from|at)\s+(?:the\s+)?([^.,]+?)\s+on\s+(.+?)\s+in\s+([A-Za-z .'-]+?)(?:[,.])/i,
      /went to\s+(?:the\s+)?([^.,]+?)\s+on\s+(.+?)\s+in\s+([A-Za-z .'-]+?)\s+(?:for|when|and|to)\b/i,
    ];
    for (const pattern of patterns) {
      const match = text.match(pattern);
      if (match) return {name: match[1].trim(), street: match[2].trim(), city: match[3].trim()};
    }
    return null;
  };
  const newsActivities = async (directory, archiveLatest) => {
    const articles = [];
    for (let page = 1; page <= 3; page += 1) {
      articles.push(...newsIndex(await responseText(`${newsUrl}?p=${page}`)));
    }
    const seen = new Set();
    const activities = [];
    for (const article of articles) {
      if (seen.has(article.href) || (archiveLatest && article.published <= archiveLatest)) continue;
      seen.add(article.href);
      const html = await responseText(article.href);
      const body = html.match(/id="ctl00_MainContent_lblBody"[^>]*>([\s\S]*?)<\/span>/i)?.[1];
      if (!body) continue;
      const text = plainText(body);
      const retailerDetails = retailerFromNews(text);
      const game = gameFrom(`${article.title} ${text}`);
      const prizeAmount = prizeFrom(article.title);
      if (!retailerDetails || !game || !prizeAmount) continue;
      const retailer = resolveNewsRetailer(
        directory,
        retailerDetails.name,
        retailerDetails.street,
        retailerDetails.city,
      );
      if (!retailer) continue;
      const articleId = article.href.replace(/^.*\/News\//, '').replace(/[^a-z0-9]+/gi, '-').replace(/^-|-$/g, '').toLowerCase();
      activities.push({
        id: `nc-news-${articleId}`,
        latitude: retailer.latitude,
        longitude: retailer.longitude,
        city: retailer.city,
        county: retailer.county,
        state: 'NC',
        game: game.game,
        gameName: game.gameName,
        retailerName: retailer.retailerName,
        retailerAddress: `${retailer.address}, ${retailer.city}, NC ${retailer.zip}`.trim(),
        drawDate: article.published.toISOString(),
        winningTickets: 1,
        prizeAmount,
        sourceUrl: article.href,
        sourceLabel: `Official NC Education Lottery news release · ${article.published.toLocaleDateString('en-US', {month: 'short', day: 'numeric', year: 'numeric', timeZone: 'UTC'})}`,
      });
    }
    return activities;
  };

  try {
    const directory = parseDirectory(await responseText(directoryUrl));
    const rows = (await Promise.all(games.map(buildRows))).flat();
    const activities = [];
    const unmatched = new Set();
    for (const row of rows) {
      const retailer = directory.map.get(`${normalize(row.retailerName)}|${normalize(row.city)}`);
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
    const archiveLatest = activities.map((activity) => new Date(activity.drawDate))
      .sort((left, right) => right - left)[0];
    activities.push(...await newsActivities(directory, archiveLatest));
    activities.sort((left, right) => left.id.localeCompare(right.id));
    const latest = activities.map((activity) => activity.drawDate).sort().at(-1);
    const output = {
      source: 'North Carolina Education Lottery official winner archive, news releases, and retailer directory',
      updatedAt: latest ?? null,
      sourceLastUpdated: latest ?? null,
      coverage: `Current qualifying NC Lottery prize claims from ${startYear} onward for the official archive's available game categories, supplemented by newer official NC Education Lottery news releases when the archive has not yet published the claim. ${activities.length} claims were matched to the official retailer directory with its published address and coordinates. ${unmatched.size} distinct published archive retailer names could not be matched exactly and were excluded.`,
      activities,
    };
    await writeFile(outputPath, `${JSON.stringify(output, null, 2)}\n`);
    console.log(`Imported ${activities.length} NC winner claims; ${unmatched.size} retailers were skipped for lack of an exact official directory match.`);
  } catch (error) {
    console.error(`NC winner import stopped: ${error.message}`);
    process.exitCode = 1;
  }
}
