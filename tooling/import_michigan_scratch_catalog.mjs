/* Imports every current retail Michigan Scratch-Off from the official API. */
import {writeFile} from 'node:fs/promises';
const output = process.argv[2];
if (!output) throw new Error('Usage: node tooling/import_michigan_scratch_catalog.mjs OUTPUT.json');
const source = 'https://www.michiganlottery.com/resources/instant-games-prizes-remaining';
const api = 'https://www.michiganlottery.com/api';
const query = '{ getRetailTopPrizesRemainingByGameType(gameType: "instant") { cms_game_igt_id game_name prizesRemainingData { prize_level prize_amount prizes_remaining starting_amount } } }';
const response = await fetch(api, {method: 'POST', headers: {'content-type': 'application/json', 'cms-type': 'production'}, body: JSON.stringify({query})});
if (!response.ok) throw new Error(`Michigan Scratch API returned HTTP ${response.status}`);
const rows = (await response.json()).data?.getRetailTopPrizesRemainingByGameType;
const games = (rows ?? []).flatMap(row => {
  const prizes = row.prizesRemainingData ?? [];
  const cost = Number((row.game_name.match(/\$(\d+)(?:\)?$|\s)/)?.[1]));
  const top = Math.max(...prizes.map(item => Number(item.prize_amount) || 0));
  const remaining = prizes.filter(item => Number(item.prize_amount) === top).reduce((sum, item) => sum + (Number(item.prizes_remaining) || 0), 0);
  if (!row.cms_game_igt_id || !row.game_name || !cost || !top) return [];
  return [{id: String(row.cms_game_igt_id), name: row.game_name.trim(), cost, topPrize: top, topPrizesRemaining: remaining, sourceUrl: source}];
});
if (games.length < 40) throw new Error(`Michigan Scratch catalog is incomplete (${games.length})`);
const updatedAt = new Date().toISOString();
await writeFile(output, `${JSON.stringify({source: 'Michigan Lottery official current retail Instant Games API', updatedAt, retrievedAt: updatedAt, coverage: `All ${games.length} current retail Michigan Scratch-Off games with official price, top prize, and remaining top-prize count.`, catalogs: [{state: 'Michigan', source, games}]}, null, 2)}\n`);
console.log(`Imported ${games.length} Michigan Scratch-Off games.`);
