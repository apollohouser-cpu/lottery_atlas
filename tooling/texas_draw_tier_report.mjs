// Preserve official statewide tier columns separately from selling-store activity.
// In particular, multiplier columns can overlap base columns: never add them.
import {text} from './import_texas_draw_winners.mjs';

export function parseTierReport(html, {gameName, drawDate, sourceUrl}) {
  const heading = text(html).match(/Winning Numbers for (\d{2})\/(\d{2})\/(\d{4})(?: (Morning|Day|Evening|Night))? (?:were|are)/);
  if (!heading || `${heading[3]}-${heading[1]}-${heading[2]}` !== drawDate) {
    throw new Error('Tier report draw date mismatch');
  }
  const gameHeading = [...html.matchAll(/<h[12]\b[^>]*>([\s\S]*?)<\/h[12]>/gi)]
    .some(m => text(m[1]).includes(gameName));
  if (!gameHeading) throw new Error('Tier report game mismatch');
  const tables = [...html.matchAll(/<table\b[^>]*>([\s\S]*?)<\/table>/gi)]
    .map(m => m[1]).filter(t => /Number Correct/.test(t) && /Prize Amount/.test(t));
  if (tables.length !== 1) throw new Error('Expected one unambiguous prize table');
  const table = tables[0];
  if (/\b(?:colspan|rowspan)\s*=/i.test(table)) {
    throw new Error('Spanning prize columns need a separately reviewed parser');
  }
  const headers = [...table.matchAll(/<th\b[^>]*>([\s\S]*?)<\/th>/gi)]
    .map(m => text(m[1].replace(/<sup\b[^>]*>[\s\S]*?<\/sup>/gi, '')));
  const winnerColumns = headers.flatMap((h, i) => /Winners/i.test(h) ? [i] : []);
  if (!headers.length || !winnerColumns.length) throw new Error('Missing winner columns');
  const rows = [...table.matchAll(/<tr\b[^>]*>([\s\S]*?)<\/tr>/gi)]
    .map(m => [...m[1].matchAll(/<td\b[^>]*>([\s\S]*?)<\/td>/gi)].map(c => text(c[1])))
    .filter(c => c.length);
  if (rows.some(c => c.length !== headers.length)) throw new Error('Inconsistent tier columns');
  const totals = rows.filter(c => /^Total.*Winners:/i.test(c[0]));
  const tiers = rows.filter(c => !/^Total.*Winners:/i.test(c[0]));
  if (totals.length !== 1 || tiers.length < 2) throw new Error('Missing tier rows or totals');
  const count = value => {
    if (['Roll', '--', 'N/A', ''].includes(value)) return null;
    if (!/^\d{1,3}(?:,\d{3})*$|^\d+$/.test(value)) throw new Error('Unknown winner-count value');
    const result = Number(value.replaceAll(',', ''));
    if (!Number.isSafeInteger(result)) throw new Error('Invalid winner count');
    return result;
  };
  for (const i of winnerColumns) {
    const reported = count(totals[0][i]);
    const sum = tiers.reduce((n, row) => n + (count(row[i]) ?? 0), 0);
    if (reported === null || sum !== reported) throw new Error('Tier sum differs from reported column total');
  }
  return {
    gameName, drawDate, drawingSession: heading[4] ?? null, sourceUrl,
    sourcePublicationDate: null,
    coverage: 'One official Texas draw prize table; statewide reported winners by tier, not validated claims or retailer locations. Columns remain separate and must not be added together. Roll, N/A and -- retain their source meaning.',
    headers, tiers, reportedTotals: totals[0], winnerColumns,
  };
}
