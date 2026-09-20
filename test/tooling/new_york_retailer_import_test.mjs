import {test} from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp, readFile, writeFile, rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {spawnSync} from 'node:child_process';
import {fetchSourceJson, SourceUnavailableError} from '../../tooling/source_json_fetch.mjs';

const original = await readFile(new URL('../../data/new_york_retailer_directory.generated.json', import.meta.url), 'utf8');
const importer = new URL('../../tooling/import_new_york_retailer_directory.mjs', import.meta.url);
const counties = new URL('../../assets/maps/us_counties.geojson', import.meta.url);

test('temporary failures retry and recover', async () => {
  let calls = 0;
  const delays = [];
  const result = await fetchSourceJson('https://example.test', {
    fetchImpl: async () => ++calls < 3 ? new Response('', {status: 503}) : Response.json({ok: true}),
    wait: async (ms) => delays.push(ms),
  });
  assert.deepEqual(result, {ok: true});
  assert.equal(calls, 3);
  assert.deepEqual(delays, [750, 1500]);
});

for (const failure of [503, 429, 'network', 'timeout', 'body']) {
  test(`exhausted ${failure} failure is classified as unavailable`, async () => {
    let calls = 0;
    await assert.rejects(fetchSourceJson('https://example.test', {
      fetchImpl: async (_url, options) => {
        calls++;
        assert.ok(options.signal instanceof AbortSignal);
        if (failure === 'network') throw new TypeError('fetch failed');
        if (failure === 'timeout') throw new DOMException('timed out', 'TimeoutError');
        if (failure === 'body') return {ok: true, json: async () => {throw new TypeError('terminated');}};
        return new Response('', {status: failure});
      },
      wait: async () => {},
    }), SourceUnavailableError);
    assert.equal(calls, 4);
  });
}

for (const failure of [403, 404, 'json']) {
  test(`${failure} is not treated as an outage`, async () => {
    let calls = 0;
    await assert.rejects(fetchSourceJson('https://example.test', {
      fetchImpl: async () => {
        calls++;
        return failure === 'json' ? new Response('{bad') : new Response('', {status: failure});
      },
      wait: async () => {},
    }), (error) => !(error instanceof SourceUnavailableError));
    assert.equal(calls, 1);
  });
}

async function runImporter(t, {cache = original, response = 'return new Response("", {status:503});', unchanged = true} = {}) {
  const dir = await mkdtemp(join(tmpdir(), 'lottery-ny-test-'));
  t.after(() => rm(dir, {recursive: true, force: true}));
  const output = join(dir, 'directory.json');
  const preload = join(dir, 'fetch.mjs');
  if (cache !== null) await writeFile(output, cache);
  await writeFile(preload, `globalThis.setTimeout = (fn) => { queueMicrotask(fn); return 0; };\nglobalThis.fetch = async (url) => { ${response} };`);
  const result = spawnSync(process.execPath, ['--import', preload, importer.pathname, output, counties.pathname], {
    encoding: 'utf8', timeout: 30000, env: {...process.env, GITHUB_ACTIONS: 'true'},
  });
  assert.ifError(result.error);
  if (cache !== null && unchanged) assert.equal(await readFile(output, 'utf8'), cache, 'failed refresh must not rewrite existing data');
  if (!unchanged) result.outputData = JSON.parse(await readFile(output, 'utf8'));
  return result;
}

test('503 preserves complete verified cache byte-for-byte and emits a workflow warning', async (t) => {
  const result = await runImporter(t);
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stderr, /::warning title=New York retailer refresh deferred::/);
  assert.ok(result.stderr.includes(JSON.parse(original).retrievedAt));
});

const completeSource = `Array.from({length: 12000}, (_, i) => ({retailer: String(i).padStart(6, '0'), name:'Shop',street:'25 W 43rd St',city:'New York',zip:'10036',latitude:40.754479,longitude:-73.981179}))`;

test('a healthy complete source replaces the cache', async (t) => {
  const result = await runImporter(t, {
    response: `return Response.json(String(url).includes('count') ? [{count:12000}] : ${completeSource});`,
    unchanged: false,
  });
  assert.equal(result.status, 0, result.stderr);
  assert.equal(result.outputData.directories[0].retailers.length, 12000);
  assert.equal(result.outputData.directories[0].retailers[0].county, 'New York County');
  assert.doesNotMatch(result.stderr, /refresh deferred/);
});

test('Census outage also retains the complete cache without partial writes', async (t) => {
  const result = await runImporter(t, {
    response: `if (String(url).includes('census.gov')) return new Response('', {status:503});
      if (String(url).includes('count')) return Response.json([{count:12000}]);
      const rows = ${completeSource}; rows[0].latitude = 0; return Response.json(rows);`,
  });
  assert.equal(result.status, 0, result.stderr);
  assert.match(result.stderr, /refresh deferred/);
  assert.match(result.stderr, /census.gov/);
});

for (const corruption of ['missing', 'malformed', 'partial', 'wrong-state', 'duplicate', 'coordinates', 'date']) {
  test(`503 cannot use a ${corruption} cache`, async (t) => {
    const cache = JSON.parse(original);
    const directory = cache.directories[0];
    if (corruption === 'partial') directory.retailers = directory.retailers.slice(0, 100);
    if (corruption === 'wrong-state') directory.state = 'Texas';
    if (corruption === 'duplicate') directory.retailers[1] = directory.retailers[0];
    if (corruption === 'coordinates') directory.retailers[0].latitude = null;
    if (corruption === 'date') cache.retrievedAt = 'invalid';
    const result = await runImporter(t, {cache: corruption === 'missing' ? null : corruption === 'malformed' ? '{' : JSON.stringify(cache)});
    assert.equal(result.status, 1);
    assert.doesNotMatch(result.stderr, /retained the verified/);
  });
}

for (const [name, response, expected] of [
  ['invalid count', 'return Response.json([{count: 2}]);', /count is invalid/],
  ['incomplete source', 'return Response.json(String(url).includes("count") ? [{count: 12000}] : []);', /0\/12000 rows/],
  ['duplicate source', 'return Response.json(String(url).includes("count") ? [{count: 12000}] : Array.from({length: 12000}, () => ({retailer:"001",name:"Shop",street:"25 W 43rd St",city:"New York",zip:"10036",latitude:40.754479,longitude:-73.981179})));', /duplicate official retailer row/],
  ['permanent HTTP error', 'return new Response("", {status: 404});', /HTTP 404/],
  ['malformed source', 'return new Response("{bad");', /failed:/],
]) {
  test(`${name} fails even with a complete cache`, async (t) => {
    const result = await runImporter(t, {response});
    assert.equal(result.status, 1);
    assert.match(result.stderr, expected);
    assert.doesNotMatch(result.stderr, /retained the verified/);
  });
}
