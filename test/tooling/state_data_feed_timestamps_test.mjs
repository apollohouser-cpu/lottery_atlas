import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp, writeFile, readFile, rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join, resolve} from 'node:path';
import {execFileSync} from 'node:child_process';
async function build(roots) {
 const dir=await mkdtemp(join(tmpdir(),'atlas-stamps-'));
 try {
  const inputs=[];for(let i=0;i<roots.length;i++){const p=join(dir,`${i}.json`);await writeFile(p,JSON.stringify(roots[i]));inputs.push(p);}
  const c=join(dir,'catalogs.json'),d=join(dir,'directories.json');
  execFileSync(process.execPath,[resolve('tooling/build_state_data_feeds.mjs'),c,d,...inputs]);
  return [JSON.parse(await readFile(c)),JSON.parse(await readFile(d))];
 } finally {await rm(dir,{recursive:true,force:true});}
}
test('state timestamps stay independent and source dates remain unknown',async()=>{
 const [c,d]=await build([{updatedAt:'2026-09-21T12:00:00Z',catalogs:[{state:'A',sourceDate:null}]},{updatedAt:'2026-09-20T12:00:00Z',catalogs:[{state:'B'}]},{retrievedAt:'2026-09-19T12:00:00Z',directories:[{state:'A'}]}]);
 assert.equal(c.catalogs[1].updatedAt,'2026-09-20T12:00:00Z');assert.equal(c.catalogs[0].sourceDate,null);assert.equal(c.catalogs[0].timestampScope,'state');assert.equal(d.updatedAt,'2026-09-19T12:00:00Z');
});
test('chronological comparison handles offsets instead of sorting strings',async()=>{
 const [c]=await build([{updatedAt:'2026-09-21T10:00:00-04:00',catalogs:[{state:'A'}]},{updatedAt:'2026-09-21T13:00:00Z',catalogs:[{state:'B'}],directories:[{state:'A'}]}]);
 assert.equal(c.updatedAt,'2026-09-21T10:00:00-04:00');
});
test('explicit state timestamps take precedence and absent timestamps do not become now',async()=>{
 const [c,d]=await build([{updatedAt:'2026-09-21T13:00:00Z',catalogs:[{state:'A',updatedAt:'2026-09-19T00:00:00Z'}]},{directories:[{state:'A'}]}]);
 assert.equal(c.updatedAt,'2026-09-19T00:00:00Z');assert.equal(d.updatedAt,'1970-01-01T00:00:00.000Z');
});
