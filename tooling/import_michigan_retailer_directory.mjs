/* Imports the official Michigan Lottery active retailer API. */
import {writeFile} from 'node:fs/promises';
const output = process.argv[2];
const api = 'https://www.michiganlottery.com/api';
const source = 'https://www.michiganlottery.com/resources/find-a-retailer';
const canonical = value => String(value ?? '').trim();
if (!output) throw new Error('Usage: node tooling/import_michigan_retailer_directory.mjs OUTPUT.json');
const query = '{ retailers { id retailerNumber name address city postalCode latitude longitude sellsPokerLotto acceptsCreditOrDebit } }';
const response = await fetch(api, {method: 'POST', headers: {'content-type': 'application/json', 'cms-type': 'production'}, body: JSON.stringify({query})});
if (!response.ok) throw new Error(`Michigan retailer API returned HTTP ${response.status}`);
const rows = (await response.json()).data?.retailers;
if (!Array.isArray(rows) || rows.length < 10000) throw new Error('Michigan retailer response is incomplete');
const unresolvedRetailers = [];
const retailers = rows.flatMap(row => {
  const latitude = Number(row.latitude), longitude = Number(row.longitude);
  const valid = canonical(row.name) && canonical(row.address) && canonical(row.city) && canonical(row.postalCode) &&
    latitude >= 41.5 && latitude <= 48.5 && longitude >= -90.5 && longitude <= -82;
  if (!valid) { unresolvedRetailers.push({id: `mi-${row.retailerNumber ?? row.id}`, name: row.name ?? '', reason: 'Official API row lacks a usable Michigan coordinate or complete address'}); return []; }
  return [{id: `mi-${row.retailerNumber}`, name: canonical(row.name), address: canonical(row.address), city: canonical(row.city), postalCode: canonical(row.postalCode), latitude, longitude, coordinateSource: 'Michigan Lottery published retailer coordinate'}];
});
if (retailers.length < 10000) throw new Error(`Only ${retailers.length} usable Michigan retailers returned`);
await writeFile(output, `${JSON.stringify({source: 'Michigan Lottery official active retailer API', retrievedAt: new Date().toISOString(), coverage: `${retailers.length} active Michigan Lottery retailers with Lottery-published exact coordinates; ${unresolvedRetailers.length} non-Michigan or incomplete API rows excluded.`, directories: [{state: 'Michigan', source, retailers, unresolvedRetailers}]}, null, 2)}\n`);
console.log(`Imported ${retailers.length} Michigan retailers.`);
