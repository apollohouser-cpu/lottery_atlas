// Closing a game removes it from the current catalog, not from claim history.
export function retainTexasRetiredClaims(previous, current, currentReportUrls) {
  if (!(currentReportUrls instanceof Set) || currentReportUrls.size < 70 || !current.length) {
    throw Error('Incomplete current Texas catalog/claims; preserve saved feed');
  }
  const retired = (previous?.activities ?? []).filter(row => !currentReportUrls.has(row.sourceUrl));
  const rows = new Map(current.map(row => [row.id,row]));
  for (const row of retired) {
    if (row.state !== 'TX' || row.game !== 'scratch-off' ||
        !/^tx-claim-[a-f0-9]{64}$/.test(row.id) ||
        !/^https:\/\/www\.texaslottery\.com\/export\/sites\/lottery\/Games\/Scratch_Offs\/retailerswhosoldtopprizes\.html_[0-9]+\.html$/.test(row.sourceUrl) ||
        !row.sourceLabel || !row.retailerAddress || !row.coordinateSource ||
        !Number.isFinite(row.latitude) || !Number.isFinite(row.longitude) ||
        !Number.isFinite(Date.parse(row.drawDate)) || row.winningTickets !== 1 || !(row.prizeAmount > 0)) {
      throw Error('Invalid archived Texas claim; preserve saved feed');
    }
    const note = ' · Archived game report; original claim/report dates retained';
    rows.set(row.id,{...row,sourceLabel:row.sourceLabel.endsWith(note)?row.sourceLabel:row.sourceLabel+note});
  }
  return [...rows.values()].sort((a,b)=>a.drawDate.localeCompare(b.drawDate)||a.id.localeCompare(b.id));
}
