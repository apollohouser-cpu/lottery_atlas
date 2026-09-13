/* Imports only exact, retailer-addressed 2026 Michigan Lottery winner releases. */
import {readFile, writeFile} from 'node:fs/promises';
const [output, directoryPath] = process.argv.slice(2);
if (!output || !directoryPath) throw new Error('Usage: node tooling/import_michigan_winners.mjs OUTPUT.json RETAILERS.json');
// The official news archive spells addresses out while the official retailer
// API uses USPS abbreviations.  Normalize only those published equivalents;
// no fuzzy or proximity matching is permitted.
const canonical = value => String(value ?? '').toUpperCase().replace(/&[^;]+;/g, ' ')
  .replace(/\bNORTH\b/g, 'N').replace(/\bSOUTH\b/g, 'S').replace(/\bEAST\b/g, 'E').replace(/\bWEST\b/g, 'W')
  .replace(/\bNORTHEAST\b/g, 'NE').replace(/\bNORTHWEST\b/g, 'NW').replace(/\bSOUTHEAST\b/g, 'SE').replace(/\bSOUTHWEST\b/g, 'SW')
  .replace(/\bUNITED STATES\b/g, 'US').replace(/\bFIRST\b/g, '1ST').replace(/\bSECOND\b/g, '2ND').replace(/\bTHIRD\b/g, '3RD')
  .replace(/\bAVENUE\b/g, 'AVE').replace(/\bSTREET\b/g, 'ST').replace(/\bROAD\b/g, 'RD')
  .replace(/\bDRIVE\b/g, 'DR').replace(/\bBOULEVARD\b/g, 'BLVD').replace(/\bHIGHWAY\b/g, 'HWY')
  .replace(/\bCOURT\b/g, 'CT').replace(/\bLANE\b/g, 'LN').replace(/\bPLACE\b/g, 'PL').replace(/[^A-Z0-9]/g, '');
const text = value => String(value ?? '').replace(/<[^>]+>/g, ' ').replace(/&nbsp;|&#8217;|&#8216;|&amp;/g, ' ').replace(/\s+/g, ' ').trim();
const slug = value => String(value).toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, '');
const money = value => Number(String(value ?? '').replace(/[^0-9.]/g, ''));
const root = JSON.parse(await readFile(directoryPath, 'utf8'));
const retailers = root.directories?.find(item => item.state === 'Michigan')?.retailers;
if (!Array.isArray(retailers) || retailers.length < 10000) throw new Error('Complete Michigan retailer directory is missing');
const byAddress = new Map();
for (const retailer of retailers) { const key = `${canonical(retailer.address)}|${canonical(retailer.city)}`; byAddress.set(key, [...(byAddress.get(key) ?? []), retailer]); }
const posts = [];
for (let page = 1; page < 10; page++) {
  const response = await fetch(`https://milotteryconnect.com/wp-json/wp/v2/posts?after=2026-01-01T00:00:00&per_page=100&page=${page}`);
  if (response.status === 400 || response.status === 404) break;
  if (!response.ok) throw new Error(`Michigan official winner archive returned HTTP ${response.status}`);
  const batch = await response.json(); posts.push(...batch); if (batch.length < 100) break;
}
const activities = [], excluded = [];
for (const post of posts) {
  const body = text(post.content?.rendered);
  if (!/\b(?:purchased|bought)\b/i.test(body) || /\bonline at MichiganLottery\.com\b/i.test(body)) continue;
  const match = body.match(/(?:purchased|bought)(?: the)?(?: winning)?(?: ticket)? at (?:the )?(.+?), located at ([0-9][^,.]*?(?:Street|St\.?|Road|Rd\.?|Avenue|Ave\.?|Highway|Hwy\.?|Drive|Dr\.?|Boulevard|Blvd\.?|Lane|Ln\.?|Court|Ct\.?|Way|M\s?[- ]?\d+)[^,.]*?) in ([A-Za-z .'-]+?)\./i);
  if (!match) { excluded.push({sourceUrl: post.link, reason: 'Official release does not publish a parseable physical retailer name, address, and city'}); continue; }
  const [, retailerName, address, city] = match;
  let matches = byAddress.get(`${canonical(address)}|${canonical(city)}`) ?? [];
  if (matches.length > 1) matches = matches.filter(item => canonical(item.name) === canonical(retailerName));
  if (matches.length !== 1) { excluded.push({sourceUrl: post.link, retailerName, address, city, reason: matches.length ? 'Multiple exact official directory locations matched' : 'No exact official directory retailer matched'}); continue; }
  const retailer = matches[0];
  const title = text(post.title?.rendered);
  const amount = money((body.match(/\$(?:[\d,]+(?:\.\d{2})?)/)?.[0]));
  if (!amount) { excluded.push({sourceUrl: post.link, reason: 'Official release has no usable prize amount'}); continue; }
  const gameName = (title.match(/(?:playing|wins?) (?:the )?(.+?)(?: from| prize| jackpot| instant game|$)/i)?.[1] ?? 'Michigan Lottery').trim();
  const game = /powerball/i.test(title) ? 'powerball' : /mega millions/i.test(title) ? 'mega-millions' : /instant|scratch/i.test(title) ? 'scratch-off' : 'state-draw';
  activities.push({id: `mi-${post.date.slice(0, 10)}-${slug(retailer.id)}-${post.id}`, latitude: retailer.latitude, longitude: retailer.longitude, city: retailer.city, state: 'MI', game, gameName, retailerName: retailer.name, retailerAddress: `${retailer.address}, ${retailer.city}, MI ${retailer.postalCode}`, coordinateSource: retailer.coordinateSource, drawDate: `${post.date.slice(0, 10)}T12:00:00.000Z`, winningTickets: 1, prizeAmount: amount, sourceUrl: post.link, sourceLabel: `Official Michigan Lottery winner release · ${post.date.slice(0, 10)}`});
}
const unique = [...new Map(activities.map(item => [item.id, item])).values()].sort((a,b) => a.drawDate.localeCompare(b.drawDate));
const months = new Set(unique.map(item => item.drawDate.slice(5,7)));
if (unique.length < 15 || months.size < 7) throw new Error(`Only ${unique.length} qualifying Michigan 2026 winner locations across ${months.size} months`);
await writeFile(output, `${JSON.stringify({source: 'Michigan Lottery Connect official winner releases and Michigan Lottery retailer API', sourceUrl: 'https://milotteryconnect.com/', updatedAt: new Date().toISOString(), sourceLastUpdated: unique.at(-1).drawDate, coverage: `${unique.length} exact physical Michigan retailer winner locations from January 1, 2026 through the current official release. Releases without a uniquely matching official retailer address are excluded.`, activities: unique, excluded}, null, 2)}\n`);
console.log(`Imported ${unique.length} Michigan winner locations; excluded ${excluded.length}.`);
