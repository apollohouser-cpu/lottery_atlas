// Archive dates are claim dates. Noon UTC is a date-only transport convention.
export function claimDate(value) {
  if (!/^\d{2}\/\d{2}\/\d{4}$/.test(value)) throw Error('Invalid NC claim date');
  const [month, day, year] = value.split('/').map(Number);
  const date = new Date(Date.UTC(year, month - 1, day, 12));
  if (date.getUTCFullYear() !== year || date.getUTCMonth() !== month - 1 || date.getUTCDate() !== day || date > new Date()) throw Error('Invalid NC claim date');
  return date;
}

export function archivePage(html, game, page) {
  const pager = html.match(/<span[^>]*id="ctl00_MainContent_WinnersListDataPager"[^>]*>(.*?)<\/span>\s*(?:&nbsp;|<a)/s);
  // Extract through the pager's closing span, including its nested current-page span.
  const start = html.indexOf('id="ctl00_MainContent_WinnersListDataPager"');
  const end = html.indexOf('</span>', html.indexOf('</span>', start) + 7);
  const block = start >= 0 && end > start ? html.slice(start, end) : '';
  if (!pager || !block.includes(`<span>${page}</span>`) || !/<th>Claimed<\/th>/.test(html)) throw Error('NC archive page identity missing');
  const next = block.match(/<a href="([^"]+)">Next<\/a>/)?.[1];
  if (next && next.replaceAll('&amp;', '&') !== `/WinnersAll?g=${game.code}&p=${page + 1}`) throw Error('Unexpected NC archive next page');
  const ids = [...html.matchAll(/href="\/Winner\?id=(\d+)"/g)].map(m => m[1]);
  if (!ids.length || new Set(ids).size !== ids.length) throw Error('Empty or repeated NC archive rows');
  return {ids, hasNext: Boolean(next)};
}
