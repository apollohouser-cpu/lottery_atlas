// All or Nothing publishes four sessions progressively through the day.
// Keep a complete dated report day until all four new sessions are available.
export function selectReportDay(links, fourSessions = false) {
  const days = new Map();
  const seen = new Map();
  for (const link of links) {
    if (!/^\d{4}-\d{2}-\d{2}$/.test(link.drawDate) || !Number.isFinite(Date.parse(link.drawDate)) || new Date(link.drawDate).toISOString().slice(0,10) !== link.drawDate) throw Error('Invalid report date');
    if (seen.has(link.sourceUrl)) {
      if (seen.get(link.sourceUrl) !== link.drawDate) throw Error('Conflicting report date');
      continue; // Navigation can repeat the same dated link.
    }
    seen.set(link.sourceUrl, link.drawDate);
    const rows = days.get(link.drawDate) ?? [];
    rows.push(link); days.set(link.drawDate, rows);
  }
  const dates = [...days.keys()].sort().reverse();
  if (!dates.length) throw Error('No report links');
  const expected = fourSessions ? 4 : 1;
  for (const date of dates) {
    const rows = days.get(date);
    if (rows.length > expected) throw Error('Unexpected drawing count');
    if (rows.length === expected) return rows;
    if (!fourSessions) throw Error('Missing report');
  }
  throw Error('No complete report day');
}

export function validateReportContinuity(reports, oldReports = []) {
  const key = r => `${r.gameName}|${r.drawingSession ?? ''}`;
  const seen = new Set();
  for (const r of reports) {
    if (seen.has(key(r))) throw Error('Duplicate report session');
    seen.add(key(r));
    const prior = oldReports.find(p => key(p) === key(r));
    if (prior && r.drawDate < prior.drawDate) throw Error('Report date regression');
  }
  const aon = reports.filter(r => r.gameName === 'All or Nothing');
  if (aon.length !== 4 || new Set(aon.map(r=>r.drawDate)).size !== 1 ||
      ['Morning','Day','Evening','Night'].some(s=>!aon.some(r=>r.drawingSession===s))) {
    throw Error('Incomplete All or Nothing sessions');
  }
  for (const p of oldReports) if (!seen.has(key(p))) throw Error('Missing retained report session');
}
