import {readFile, writeFile} from 'node:fs/promises';
import {pathToFileURL} from 'node:url';

export function validateTexasTierFeed(data) {
  if (!data || !Number.isFinite(Date.parse(data.updatedAt)) || typeof data.coverage !== 'string' || !data.coverage.trim()) throw Error('Missing feed provenance');
  const games = new Map([['Powerball','Powerball'],['Mega Millions','Mega_Millions'],['Lotto Texas','Lotto_Texas'],['Texas Two Step','Texas_Two_Step'],['Cash Five','Cash_Five'],['All or Nothing','All_or_Nothing']]);
  if (!Array.isArray(data.reports) || data.reports.length !== 9) throw Error('Expected nine reviewed reports');
  const keys = new Set();
  const count = value => {
    if (['Roll', '--', 'N/A', ''].includes(value)) return null;
    if (typeof value !== 'string' || !/^(?:\d{1,3}(?:,\d{3})*|\d+)$/.test(value)) throw Error('Invalid count');
    const n = Number(value.replaceAll(',', ''));
    if (!Number.isSafeInteger(n)) throw Error('Unsafe count');
    return n;
  };
  for (const r of data.reports) {
    const folder = games.get(r.gameName);
    if (!folder || !/^\d{4}-\d{2}-\d{2}$/.test(r.drawDate) || new Date(r.drawDate).toISOString().slice(0,10) !== r.drawDate) throw Error('Invalid game or date');
    const url = new URL(r.sourceUrl);
    if (url.origin !== 'https://www.texaslottery.com' || !url.pathname.startsWith(`/export/sites/lottery/Games/${folder}/Winning_Numbers/details.html`) || url.username || url.password) throw Error('Invalid official report URL');
    if (r.sourcePublicationDate !== null || typeof r.coverage !== 'string' || !r.coverage.trim()) throw Error('Unreviewed provenance');
    if (r.gameName === 'All or Nothing' ? !['Morning','Day','Evening','Night'].includes(r.drawingSession) : r.drawingSession !== null) throw Error('Invalid session');
    const key = `${r.gameName}:${r.drawingSession}`;
    if (keys.has(key)) throw Error('Duplicate game/session');
    keys.add(key);
    if (!Array.isArray(r.headers) || r.headers.length < 3 || r.headers.some(x=>typeof x !== 'string' || !x.trim())) throw Error('Invalid headers');
    if (!Array.isArray(r.tiers) || r.tiers.length < 2 || !Array.isArray(r.reportedTotals)) throw Error('Missing rows');
    for (const row of [...r.tiers,r.reportedTotals]) if (!Array.isArray(row) || row.length !== r.headers.length || row.some(x=>typeof x !== 'string')) throw Error('Invalid row');
    if (!/^Total.*Winners:/i.test(r.reportedTotals[0])) throw Error('Missing total label');
    const columns = r.headers.flatMap((h,i)=>/Winners/i.test(h)?[i]:[]);
    if (!columns.length || JSON.stringify(columns) !== JSON.stringify(r.winnerColumns)) throw Error('Invalid winner columns');
    for (const i of columns) {
      const total = count(r.reportedTotals[i]);
      if (total === null || total !== r.tiers.reduce((n,row)=>n+(count(row[i])??0),0)) throw Error('Column total mismatch');
    }
    if (r.gameName === 'Mega Millions') {
      if (JSON.stringify(columns.map(i=>r.headers[i])) !== JSON.stringify(['Total Texas Winners','2X Winners','3X Winners','4X Winners','5X Winners','10X Winners'])) throw Error('Unreviewed multiplier columns');
      for (const row of r.tiers.slice(1)) if (count(row[2]) !== columns.slice(1).reduce((n,i)=>n+(count(row[i])??0),0)) throw Error('Multiplier partition mismatch');
    }
  }
  return data;
}

if (process.argv[1] && import.meta.url === pathToFileURL(process.argv[1]).href) {
  const [input, output] = process.argv.slice(2);
  if (!input || !output) throw Error('Input and output paths required');
  const raw = await readFile(input, 'utf8');
  validateTexasTierFeed(JSON.parse(raw));
  await writeFile(output, raw);
  console.log('Published nine validated Texas prize tables without changing source dates.');
}
