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
