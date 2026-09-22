import test from 'node:test';
import assert from 'node:assert/strict';
import {parseMichiganCatalog} from '../../tooling/import_michigan_scratch_catalog.mjs';
const game={name:'Win $100',igtId:1,gameCategoryIdentifier:'RETAIL_INSTANT_GAMES_CATEGORY',includeInWebLobby:true,canBuyInStore:true,displayedTicketPrice:'$5.00',displayedTopPrize:'$100'};
const row={cms_game_igt_id:1,prizesRemainingData:[{prize_level:1,prize_amount:100,prizes_remaining:2,starting_amount:3}]};
const parse=(games=[game],rows=[row])=>parseMichiganCatalog({data:{getCMSGames:games,getRetailTopPrizesRemainingByGameType:rows}},'2026-09-20');
test('uses explicit price and excludes pull tabs',()=>{const c=parse([game,{...game,igtId:2,gameCategoryIdentifier:'PULL_TABS_CATEGORY'}],[row,{...row,cms_game_igt_id:2}]);assert.equal(c.games[0].cost,5);assert.equal(c.games.length,1);assert.deepEqual(c.excludedInventoryIds,[2]);});
test('missing inventory preserves catalog fields with unknown counts',()=>{
  const c=parse([game,{...game,igtId:2}]);
  assert.equal(c.games[1].cost,5);
  assert.equal(c.games[1].topPrize,100);
  assert.equal(c.games[1].topPrizesRemaining,null);
  assert.deepEqual(c.games[1].prizeTiers,[]);
  assert.match(c.games[1].inventoryNote,/unknown, not zero/);
  assert.deepEqual(c.unavailableInventoryIds,[2]);
});
test('empty inventory is unknown but malformed and systemic loss fail',()=>{
  const second={...game,igtId:2};
  const c=parse([game,second],[row,{cms_game_igt_id:2,prizesRemainingData:[]}]);
  assert.equal(c.games[1].topPrizesRemaining,null);
  assert.throws(()=>parse([game],[]),/No matched/);
  for(const value of [null,{},'missing'])assert.throws(()=>parse([game,second],[row,{cms_game_igt_id:2,prizesRemainingData:value}]),/Malformed/);
  assert.throws(()=>parse([game,{...second,displayedTopPrize:'unknown'}]));
});
test('restored inventory replaces unknown counts',()=>{
  const c=parse([game,{...game,igtId:2}],[row,{...row,cms_game_igt_id:2}]);
  assert.equal(c.games[1].topPrizesRemaining,2);
  assert.deepEqual(c.unavailableInventoryIds,[]);
});
test('rejects duplicate identities and malformed counts',()=>{assert.throws(()=>parse([game,game]));assert.throws(()=>parse([game],[row,row]));for(const x of [null,-1,1.5,4])assert.throws(()=>parse([game],[{...row,prizesRemainingData:[{...row.prizesRemainingData[0],prizes_remaining:x}]}]));});
test('reconciles top prize against catalog',()=>assert.throws(()=>parse([{...game,displayedTopPrize:'$500'}])));
test('preserves zero remaining and unknown verification date',()=>{const c=parse([game],[{...row,prizesRemainingData:[{...row.prizesRemainingData[0],prizes_remaining:0}]}]);assert.equal(c.sourceDate,null);assert.equal(c.games[0].topPrizesRemaining,0);assert.match(c.games[0].inventoryNote,/may already be sold/);});
