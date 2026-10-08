import test from 'node:test';
import assert from 'node:assert/strict';
import {uniqueRetailerIndex} from './north_carolina_directory.mjs';
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
