/* Follow the official report pagination while retaining its query snapshot. */
const decode = text => text.replace(/&amp;/g, '&');
export async function fetchColoradoReport(url, fetchHtml, parseRows, maxPages = 500) {
  const initial = new URL(url);
  initial.searchParams.set('page_size', '1000'); // Published selector option.
  let next = initial.href;
  const seen = new Set(), pages = [], signatures = new Set();
  let expected, snapshot, total = 0;
  while (next) {
    if (seen.has(next) || seen.size >= maxPages) throw Error('Colorado pagination loop or limit');
    seen.add(next);
    const page = await fetchHtml(next);
    const count = page.match(/<p[^>]*class="results"[^>]*>\s*([\d,]+)\s+Results?\s*</i);
    if (count) {
      const value = Number(count[1].replaceAll(',', ''));
      if (expected !== undefined && value !== expected) throw Error('Colorado report total changed during pagination');
      expected = value;
    }
    const publishedSnapshot = page.match(/params\.set\('queried_at',\s*'([^']+)'\)/)?.[1];
    snapshot ??= publishedSnapshot;
    if (publishedSnapshot && snapshot !== publishedSnapshot) throw Error('Colorado query snapshot changed');
    const data = parseRows(page);
    const signature = JSON.stringify(data);
    if (data.length && signatures.has(signature)) throw Error('Colorado repeated report page');
    signatures.add(signature); total += data.length; pages.push(page);
    const anchors = [...page.matchAll(/<a\b([^>]+)>\s*Next\s*<\/a>/gi)];
    if (anchors.length > 1) throw Error('Ambiguous Colorado next page');
    if (!anchors.length) { next = null; continue; }
    const href = anchors[0][1].match(/href="([^"]+)"/)?.[1];
    if (!href || expected === undefined || !snapshot || !data.length) throw Error('Incomplete Colorado pagination metadata');
    const target = new URL(decode(href), next);
    if (target.origin !== initial.origin || target.pathname !== initial.pathname ||
        ['game', 'timeframe'].some(key => target.searchParams.get(key) !== initial.searchParams.get(key)) ||
        !/^\d+$/.test(target.searchParams.get('page') ?? '')) throw Error('Unexpected Colorado pagination target');
    target.searchParams.set('page_size', '1000');
    target.searchParams.set('queried_at', snapshot);
    next = target.href;
  }
  if (expected !== undefined && total !== expected) throw Error(`Colorado report incomplete: ${total} of ${expected} rows`);
  return pages.join('\n');
}

export function retainColoradoScratchHistory(previous, cutoff) {
  if (!previous) return [];
  if (previous.sourceUrl !== 'https://www.coloradolottery.com/en/player-tools/whos-winning/' ||
      !Array.isArray(previous.activities) || !Number.isFinite(Date.parse(previous.updatedAt)) ||
      !Number.isFinite(Date.parse(cutoff))) throw Error('Invalid Colorado historical provenance');
  return previous.activities.filter(row => row.game === 'scratch-off' && row.drawDate < cutoff).map(row => {
    if (!row.id?.startsWith('co-2026-') || row.state !== 'CO' || !Number.isFinite(Date.parse(row.drawDate)) ||
        !Number.isFinite(row.latitude) || !Number.isFinite(row.longitude) || row.winningTickets !== 1 ||
        !(row.prizeAmount > 0) || !row.sourceUrl?.startsWith(previous.sourceUrl)) throw Error('Invalid historical Colorado Scratch record');
    const verifiedAt = row.historicalSourceVerifiedAt ?? previous.updatedAt;
    if (!Number.isFinite(Date.parse(verifiedAt))) throw Error('Invalid historical verification date');
    const label = row.sourceLabel.replace(/ · Historical source snapshot verified .+$/, '');
    return {...row, historicalSourceVerifiedAt: verifiedAt,
      sourceLabel: `${label} · Historical source snapshot verified ${verifiedAt}; not rechecked in the current 180-day report`};
  });
}
