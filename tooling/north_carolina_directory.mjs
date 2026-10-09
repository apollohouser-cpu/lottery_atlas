// Archive rows supply retailer name and city, not a reliable branch address.
// Repeated keys must remain unavailable regardless of directory ordering.
export function uniqueRetailerIndex(locations) {
  const normalize = (value) => value.toLowerCase()
    .replace(/&nbsp;/g, ' ').replace(/[^a-z0-9]/g, '');
  const map = new Map();
  const ambiguousKeys = new Set();
  for (const location of locations) {
    const key = `${normalize(location.retailerName)}|${normalize(location.city)}`;
    if (ambiguousKeys.has(key)) continue;
    if (map.has(key)) {
      map.delete(key);
      ambiguousKeys.add(key);
    } else {
      map.set(key, location);
    }
  }
  return {map, ambiguousKeys};
}

// Official coordinates are retained verbatim. This broad NC envelope detects
// malformed/swapped positions; it is not a street-address or boundary certification.
export function parseOfficialDirectory(script) {
  const source = script.match(/locationsAll\s*=\s*(\[.*\])\s*;?\s*$/s)?.[1];
  if (!source) throw Error('Official NC retailer directory was not found');
  const rows = JSON.parse(source);
  if (!Array.isArray(rows) || rows.length === 0) throw Error('Empty NC directory');
  const text = value => typeof value === 'string' && value.trim().length > 0;
  const locations = rows.map(entry => {
    if (!Array.isArray(entry) || entry.length !== 8) throw Error('Unknown NC directory row structure');
    const [retailerName, latitude, longitude, , zip, county, address, city] = entry;
    if (![retailerName,county,address,city].every(text) ||
        !Number.isFinite(latitude) || !Number.isFinite(longitude) ||
        latitude < 33 || latitude > 37 || longitude < -85 || longitude > -75 ||
        !/^\d{5}(?:-\d{4})?$/.test(String(zip))) {
      // Never skip a malformed branch before collision detection, since that
      // could make another branch falsely appear to be a unique name/city match.
      throw Error('Invalid NC directory location');
    }
    return {retailerName,latitude,longitude,address,city,county:`${county} County`,zip:String(zip)};
  });
  const {map, ambiguousKeys} = uniqueRetailerIndex(locations);
  return {map, locations, ambiguousKeys};
}
