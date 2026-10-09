import test from 'node:test';
import assert from 'node:assert/strict';
import {uniqueRetailerIndex} from '../../tooling/north_carolina_directory.mjs';
const branch = (address, city = 'Example City', retailerName = 'Sample Market') =>
  ({retailerName, city, address});
test('unique name/city keeps published location and separates cities', () => {
  const rows = [branch('1 Main'), branch('2 Main', 'Other City')];
  const result = uniqueRetailerIndex(rows);
  assert.equal(result.map.size, 2);
  assert.equal(result.map.get('samplemarket|examplecity'), rows[0]);
  assert.equal(result.ambiguousKeys.size, 0);
});
test('collisions never select a branch, even after a third row or reorder', () => {
  const rows = [branch('1 Main'), branch('2 Main'), branch('3 Main')];
  for (const ordered of [rows, [...rows].reverse()]) {
    const result = uniqueRetailerIndex(ordered);
    assert.equal(result.map.size, 0);
    assert.deepEqual([...result.ambiguousKeys], ['samplemarket|examplecity']);
  }
});
test('normalization collisions and repeated identical rows stay excluded', () => {
  const first = branch('1 Main');
  for (const second of [first, branch('2 Main', 'EXAMPLE CITY', 'Sample-Market')]) {
    assert.equal(uniqueRetailerIndex([first, second]).map.size, 0);
  }
});

import {mkdtemp, writeFile, readFile, rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {spawnSync} from 'node:child_process';
const importer = new URL('../../tooling/import_north_carolina_current_winners.mjs', import.meta.url);
test('import excludes ambiguous archive branches and never requests news', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'nc-import-'));
  try {
    const preload = join(dir, 'fetch.mjs');
    const output = join(dir, 'output.json');
    const directory = ['locationsAll=', JSON.stringify([
      ['Sample Market',35,-80,null,'28000','Example','1 Main','Example City'],
      ['Sample Market',35.1,-80.1,null,'28000','Example','2 Main','Example City'],
      ['Unique Market',35.2,-80.2,null,'28000','Example','3 Main','Example City'],
    ]), ';'].join('');
    const row = (id, name) => `<td>$5,000</td><td>10/07/2026</td><td><a href="/Winner?id=${id}">Example</a></td><td>${name}, Example City</td>`;
    const page = (rows,n=1,next=false) => `<span id="ctl00_MainContent_WinnersListDataPager"><a disabled="disabled">Previous</a>&nbsp;<span>${n}</span>&nbsp;${next ? '<a href="/WinnersAll?g=PB&amp;p=2">Next</a>' : '<a disabled="disabled">Next</a>'}&nbsp;</span><th>Claimed</th>${rows}`;
    await writeFile(preload, `globalThis.fetch = async (url) => {
      const u = new URL(url);
      if (u.pathname.includes('News')) throw Error('News must not be requested');
      return {ok:true,text:async()=>u.pathname.includes('WhereToPlay') ? ${JSON.stringify(directory)} :
        (u.searchParams.get('g') === 'PB' && u.searchParams.get('p') === '1' ? ${JSON.stringify(page(row(1,'Sample Market'),1,true))} : u.searchParams.get('g') === 'PB' ? ${JSON.stringify(page(row(2,'Unique Market')+row(4,'Unique Market').replace('$5,000','$50,000*'),2))} : ${JSON.stringify(page(row(3,'Unmapped Market')))} )};
    };`);
    const result = spawnSync(process.execPath, ['--import',preload,importer.pathname,output], {encoding:'utf8'});
    assert.equal(result.status,0,result.stderr);
    const parsed = JSON.parse(await readFile(output,'utf8'));
    assert.deepEqual(parsed.activities.map(x=>x.id),['nc-winner-2']);
    assert.match(parsed.coverage,/News articles are excluded/);
    const before = await readFile(output);
    await writeFile(preload, `globalThis.fetch = async () => { throw Error('fixture outage'); };`);
    const failure = spawnSync(process.execPath, ['--import',preload,importer.pathname,output], {encoding:'utf8'});
    assert.equal(failure.status,1);
    assert.deepEqual(await readFile(output),before);
  } finally { await rm(dir,{recursive:true,force:true}); }
});

import {parseOfficialDirectory} from '../../tooling/north_carolina_directory.mjs';
test('directory preserves official coordinates and rejects malformed branches before joining',()=>{
 const good=['Sample Market',35.2,-80.2,null,'28000','Example','3 Main','Example City'];
 const source=rows=>`locationsAll=${JSON.stringify(rows)};`;
 assert.equal(parseOfficialDirectory(source([good])).locations[0].latitude,35.2);
 for(const mutate of [r=>r[1]=null,r=>r[1]=-80,r=>r[2]=35,r=>r[6]='',r=>r[4]='bad',r=>r.push('unknown')]) {
   const bad=[...good]; mutate(bad);
   assert.throws(()=>parseOfficialDirectory(source([good,bad])));
 }
 assert.equal(parseOfficialDirectory(source([good,[...good]])).map.size,0);
 assert.throws(()=>parseOfficialDirectory(source([])));
});
