/* Join Michigan's listed retail instant games to official prize inventories. */
import {readFile, writeFile} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';
import {fetchSourceJson} from './source_json_fetch.mjs';
const source = 'https://www.michiganlottery.com/resources/instant-games-prizes-remaining';
const query = `{ getCMSGames(removeHiddenGames: false) { name identifier igtId gameCategoryIdentifier canBuyInStore displayedTicketPrice displayedTopPrize includeInWebLobby } getRetailTopPrizesRemainingByGameType(gameType: "INSTANT") { cms_game_igt_id game_name prizesRemainingData { prize_level prize_amount prizes_remaining starting_amount } } }`;
const integer = value => typeof value === 'number' && Number.isSafeInteger(value) && value >= 0;
function money(label) {
  if (typeof label !== 'string' || !/^\$\d[\d,]*(?:\.00)?$/.test(label)) throw Error('Invalid explicit money field');
  const value = Number(label.replace(/[$,]/g, ''));
  if (!integer(value) || value === 0) throw Error('Invalid explicit money amount');
  return value;
}
export function parseMichiganCatalog(body, day) {
  if (body?.errors?.length || !Array.isArray(body?.data?.getCMSGames) || !Array.isArray(body?.data?.getRetailTopPrizesRemainingByGameType)) throw Error('Incomplete Michigan response');
  const all = body.data.getCMSGames;
  const listed = all.filter(g => g.gameCategoryIdentifier === 'RETAIL_INSTANT_GAMES_CATEGORY' && g.includeInWebLobby === true && g.canBuyInStore === true);
  const rows = body.data.getRetailTopPrizesRemainingByGameType;
  const byId = new Map();
  for (const row of rows) {
    if (!integer(row.cms_game_igt_id) || byId.has(row.cms_game_igt_id)) throw Error('Invalid or duplicate inventory ID');
    byId.set(row.cms_game_igt_id, row);
  }
  const ids = new Set();
  const unavailableInventoryIds = [];
  const games = listed.map(g => {
    if (!integer(g.igtId) || ids.has(g.igtId) || typeof g.name !== 'string' || !g.name.trim()) throw Error('Invalid or duplicate catalog identity');
    ids.add(g.igtId);
    const row = byId.get(g.igtId);
    const topPrize = money(g.displayedTopPrize);
    const cost = money(g.displayedTicketPrice);
    if (row && !Array.isArray(row.prizesRemainingData)) throw Error('Malformed prize inventory');
    if (!row || !row.prizesRemainingData.length) {
      unavailableInventoryIds.push(g.igtId);
      return {stateName: 'Michigan', id: String(g.igtId), name: g.name.trim(), cost, topPrize,
        topPrizesRemaining: null, prizeTiers: [],
        inventoryNote: `Retrieved ${day}; listed in the official retail instant catalog, but current prize inventory is unavailable. Remaining prizes are unknown, not zero. Earlier counts are not presented as current. Source verification date and refresh cadence unconfirmed; store stock is unverified.`,
      };
    }
    const levels = new Set();
    for (const tier of row.prizesRemainingData) {
      if (![tier.prize_level, tier.prize_amount, tier.prizes_remaining, tier.starting_amount].every(integer) || levels.has(tier.prize_level) || tier.prizes_remaining > tier.starting_amount) throw Error('Invalid prize inventory tier');
      levels.add(tier.prize_level);
    }
    if (topPrize !== Math.max(...row.prizesRemainingData.map(t => t.prize_amount))) throw Error('Catalog and inventory top prizes disagree');
    return {stateName: 'Michigan', id: String(g.igtId), name: g.name.trim(), cost, topPrize,
      topPrizesRemaining: row.prizesRemainingData.filter(t => t.prize_amount === topPrize).reduce((sum,t) => sum+t.prizes_remaining,0),
      inventoryNote: `Retrieved ${day}; source verification date and refresh cadence unconfirmed. Remaining prizes include tickets that may already be sold.`,
      prizeTiers: row.prizesRemainingData.map(t => ({prizeLevel:t.prize_level,prizeAmount:t.prize_amount,startingPrizes:t.starting_amount,remainingPrizes:t.prizes_remaining})),
    };
  });
  if (!games.length) throw Error('No listed retail instant games');
  if (games.length === unavailableInventoryIds.length) throw Error('No matched prize inventory');
  games.sort((a,b) => Number(a.id)-Number(b.id));
  return {state:'Michigan',source,retrievedDate:day,sourceDate:null,
    coverage:'Retail instant games listed in the official web lobby and available in stores, matched by official IGT ID where published. Listed games without inventory retain catalog price and top prize with unknown remaining counts. Prize inventory is not dated claims or retailer-linked winning activity. Pull Tabs and unlisted inventory rows are excluded.',
    updateCadence:'Checked every six hours; source cadence unconfirmed.',
    unavailableInventoryIds:unavailableInventoryIds.sort((a,b)=>a-b),
    excludedInventoryIds:rows.filter(r=>!ids.has(r.cms_game_igt_id)).map(r=>r.cms_game_igt_id).sort((a,b)=>a-b),games};
}
async function main(output) {
  if (!output) throw Error('Usage: node tooling/import_michigan_scratch_catalog.mjs OUTPUT.json');
  const body=await fetchSourceJson('https://www.michiganlottery.com/api',{fetchImpl:(url,options)=>fetch(url,{...options,method:'POST',headers:{...options.headers,'content-type':'application/json','cms-type':'production'},body:JSON.stringify({query})})});
  const day=new Intl.DateTimeFormat('en-CA',{timeZone:'America/Detroit'}).format(new Date());
  const catalog=parseMichiganCatalog(body,day);
  if(catalog.games.length-catalog.unavailableInventoryIds.length<40)throw Error('Unexpectedly small Michigan retail instant catalog');
  let previous;try{previous=JSON.parse(await readFile(output,'utf8'));}catch(e){if(e.code!=='ENOENT')throw e;}
  const catalogs=[catalog];const updatedAt=JSON.stringify(previous?.catalogs)===JSON.stringify(catalogs)?previous.updatedAt:new Date().toISOString();
  await writeFile(output,JSON.stringify({source:'Michigan Lottery listed retail instant inventory',updatedAt,catalogs},null,2)+'\n');
  console.log(`Validated ${catalog.games.length} Michigan games (${catalog.unavailableInventoryIds.length} with unknown inventory); ${catalog.excludedInventoryIds.length} unlisted inventory IDs excluded.`);
}
if(process.argv[1]&&import.meta.url===pathToFileURL(process.argv[1]).href)main(process.argv[2]).catch(e=>{console.error(e.message);process.exitCode=1;});
