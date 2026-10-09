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

// Account for every linked row before optional location exclusions. Known
// shared-prize rows remain excluded; they are not one independently won prize.
export function archiveRows(html) {
  const rows = [];
  const pattern = /<td>([^<]*(?:<sup>[^<]*<\/sup>)?)<\/td><td[^>]*>(\d{2}\/\d{2}\/\d{4})<\/td><td><a href="\/Winner\?id=(\d+)">.*?<\/a><\/td><td>(.*?)<\/td>/gs;
  for (const m of html.matchAll(pattern)) {
    const [, prize, date, id, location] = m;
    claimDate(date);
    const literal = prize.replace(/<\/?sup>/g, '').trim();
    if (!/^\$(?:[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)(?:\*)?$/.test(literal)) throw Error('Unrecognized NC archive prize');
    const amount = Number(literal.replace(/[$,*]/g, ''));
    if (!Number.isSafeInteger(amount) || amount < 5000) throw Error('Invalid qualifying NC archive prize');
    rows.push({id, date, rawLocation: location, prizeAmount: amount, sharedPrize: literal.endsWith('*')});
  }
  const count = [...html.matchAll(/href="\/Winner\?id=\d+"/g)].length;
  if (!count || rows.length !== count) throw Error('NC archive row structure mismatch');
  return rows;
}
