import test from 'node:test';
import assert from 'node:assert/strict';
import {mkdtemp, readFile, rm} from 'node:fs/promises';
import {tmpdir} from 'node:os';
import {join} from 'node:path';
import {parseOregonRetailers, refreshOregonDirectory} from '../../tooling/import_oregon_retailer_directory.mjs';
const row = {RetailerNumber: '123', RetailerName: 'Example', StreetName: '1 Main St', CityName: 'Salem',
  ZipCode: '97301-1234', CountyName: 'Marion', ContractStatus: 'ACTIVE', Latitude: 44.94, Longitude: -123.03,
  SellsVideo: true, SellsDrawGames: false, SellsKeno: false, SellsInstant: false,
  PhoneNumber: 'PRIVATE', PrimaryContact: 'PRIVATE', InstantGames: ['PRIVATE'], ShippingStreet: 'PRIVATE'};
test('public directory allowlist excludes contacts and preserves distinct product flags', () => {
  const d = parseOregonRetailers([row]);
  assert.equal(d.retailers[0].sellsVideo, true);
  assert.equal(d.retailers[0].sellsDrawGames, false);
  assert.equal(d.retailers[0].postalCode, '97301');
  assert.equal(JSON.stringify(d).includes('PRIVATE'), false);
  const unresolved = parseOregonRetailers([{...row, Latitude: null}]);
  assert.equal(unresolved.retailers.length, 0);
  assert.equal(unresolved.unresolvedRetailers.length, 1);
});
test('identity, status, coordinates, missing flags and capped responses fail closed', () => {
  for (const patch of [{RetailerNumber: ''}, {ContractStatus: 'INACTIVE'}, {Latitude: 0}, {Longitude: '0'},
    {SellsVideo: undefined}, {ZipCode: 'BAD'}, {StreetName: ''}]) assert.throws(() => parseOregonRetailers([{...row, ...patch}]));
  assert.throws(() => parseOregonRetailers([row, row]));
  assert.throws(() => parseOregonRetailers(Array(6000).fill(row)));
});
test('source/validation failure retains bytes and unchanged directory retains date', async () => {
  const dir = await mkdtemp(join(tmpdir(), 'oregon-locator-')); const file = join(dir, 'out.json');
  const rows = Array.from({length: 3500}, (_, i) => ({...row, RetailerNumber: String(i + 1)}));
  try {
    await refreshOregonDirectory(file, async () => rows);
    const baseline = await readFile(file, 'utf8');
    await refreshOregonDirectory(file, async () => rows);
    assert.equal(await readFile(file, 'utf8'), baseline);
    for (const load of [async () => {throw Error('network');}, async () => [row], async () => [...rows, row]]) {
      await assert.rejects(refreshOregonDirectory(file, load));
      assert.equal(await readFile(file, 'utf8'), baseline);
    }
  } finally {await rm(dir, {recursive: true, force: true});}
});
