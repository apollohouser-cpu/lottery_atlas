// Rolling-page dates replace overlap; older verified notices remain archived.
// Preserve IDs and notice dates so installed bundles remain compatible.
export function retainKentuckyNotices(previous, current, reportStart, reportEnd) {
  if (!current.length || !Number.isFinite(Date.parse(reportStart)) ||
      !Number.isFinite(Date.parse(reportEnd)) || reportStart > reportEnd) {
    throw Error('Invalid or empty Kentucky notice window; retain saved feed');
  }
  const previousEnd = previous?.sourceLastUpdated;
  if (previousEnd && Date.parse(reportEnd) < Date.parse(previousEnd)) {
    throw Error('Regressed Kentucky notice window; retain saved feed');
  }
  const archived = (previous?.activities ?? []).filter(row => row.drawDate < reportStart);
  const combined = [...archived, ...current];
  const ids = new Set();
  for (const row of combined) {
    if (row.state !== 'KY' || !row.id?.startsWith('ky-current-') ||
        !Number.isFinite(Date.parse(row.drawDate)) ||
        !Number.isFinite(row.latitude) || !Number.isFinite(row.longitude) ||
        !row.retailerName || !row.retailerAddress || !row.coordinateSource ||
        row.sourceUrl !== 'https://www.kylottery.com/apps/winners/index.html' ||
        row.winningTickets !== 1 || !(row.prizeAmount > 0) || ids.has(row.id)) {
      throw Error('Invalid or duplicate Kentucky notice; retain saved feed');
    }
    ids.add(row.id);
  }
  return combined.sort((a,b) => a.id.localeCompare(b.id));
}
