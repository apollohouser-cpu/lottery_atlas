// Date-specific official drawing tables, separate from retailer winner listings.
const definitions = {
  millionaireforlife: {name: 'Millionaire for Life', tiers: ['5 + MB', '5', '4 + MB', '4', '3 + MB', '3', '2 + MB', '2', '1 + MB']},
  cash5: {name: 'Cash 5', tiers: ['5 of 5', '4 of 5', '3 of 5', '2 of 5']},
  lotto: {name: 'Colorado Lotto+', tiers: [
    '6 of 6', ...[5, 4, 3].flatMap(n => [2, 3, 4, 5].map(m => `${n} of 6 (${m}X)`)),
    'Plus - 6 of 6', ...[5, 4, 3].flatMap(n => [2, 3, 4, 5].map(m => `Plus - ${n} of 6 (${m}X)`)),
  ]},
};
const clean = s => s.replace(/<[^>]*>/g, ' ').replace(/&nbsp;/g, ' ').replace(/\s+/g, ' ').trim();
function integer(value) {
  if (!/^(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)$/.test(value)) throw Error('Invalid Colorado count');
  const n = Number(value.replaceAll(',', ''));
  if (!Number.isSafeInteger(n)) throw Error('Unsafe Colorado count');
  return n;
}
export function parseColoradoDrawReport(game, html, sourceUrl) {
  if (game === 'pick3') return parseColoradoPick3(html, sourceUrl);
  const def = definitions[game];
  if (!def) throw Error('Unsupported Colorado report game');
  const url = new URL(sourceUrl);
  const path = url.pathname.match(new RegExp(`^/en/games/${game}/drawings/(\\d{4}-\\d{2}-\\d{2})/$`));
  if (url.origin !== 'https://www.coloradolottery.com' || !path || url.search || url.hash) throw Error('Invalid Colorado source URL');
  const date = path[1];
  if (!Number.isFinite(Date.parse(date)) || new Date(date).toISOString().slice(0,10) !== date) throw Error('Invalid Colorado date');
  const headings = [...html.matchAll(/<h1\b[^>]*>([\s\S]*?)<\/h1>/gi)].map(m => clean(m[1]));
  const [y, m, d] = date.split('-').map(Number);
  if (headings.length !== 1 || headings[0] !== `${def.name} Drawing for ${new Date(date).toLocaleDateString('en-US', {weekday: 'long', timeZone: 'UTC'})}, ${m}/${d}/${String(y).slice(2)}`) throw Error('Mismatched Colorado heading/date');
  const tables = [...html.matchAll(/<table\b[^>]*>([\s\S]*?)<\/table>/gi)];
  if (tables.length !== 1) throw Error('Unexpected Colorado table count');
  const headers = [...tables[0][1].matchAll(/<th\b[^>]*>([\s\S]*?)(?=<th\b|<\/tr>)/gi)].map(m => clean(m[1]));
  const columns = game === 'millionaireforlife' ? ['Match', 'Colorado Winners', 'Amount'] : ['Match', 'Winners', 'Prize'];
  if (headers.join('|') !== columns.join('|')) throw Error('Unexpected Colorado table headers');
  const rows = [...tables[0][1].matchAll(/<tr\b[^>]*>([\s\S]*?)<\/tr>/gi)].filter(m => /<td\b/i.test(m[1]));
  if (rows.length !== def.tiers.length) throw Error('Missing or extra Colorado tiers');
  const tiers = rows.map((row, i) => {
    const cells = [...row[1].matchAll(/<td\b([^>]*)>([\s\S]*?)(?=<td\b|$)/gi)];
    if (cells.length !== 3 || !cells.every((c,j) => c[1].includes(`data-label="${columns[j]}"`))) throw Error('Invalid Colorado tier cells');
    const [match, count, prize] = cells.map(c => clean(c[2]));
    if (match !== def.tiers[i]) throw Error('Unexpected or duplicate Colorado tier');
    const annual = game === 'millionaireforlife' && i < 2;
    if (annual ? prize !== ['$1,000,000 a year for life*', '$100,000 a year for life**'][i] : !/^\$(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)$/.test(prize)) throw Error('Invalid Colorado prize');
    return {match, variant: match.startsWith('Plus - ') ? 'Plus' : 'Base', reportedWinners: integer(count), prizeLabel: prize};
  });
  const prizeNotes = game === 'millionaireforlife' ? ['*Divided by the number of winners', '**If 21+ total winners, divided by the number of winners'] : [];
  if (prizeNotes.some(note => !clean(html).includes(note))) throw Error('Missing Colorado annual prize sharing notes');
  let ezMatch = null;
  if (game === 'cash5') {
    const text = clean(html);
    const ez = text.match(/(\d{1,2}\/\d{1,2}\/\d{4}) EZ MATCH ([\d,]+) players won a total of (\$[\d,]+)!/);
    if (!ez || ez[1] !== `${m}/${d}/${y}` || !text.includes('EZ Match winnings calculated between 4:30AM and 11:59PM during specified Cash5 draw date.')) throw Error('Missing Colorado EZ Match period');
    ezMatch = {date, reportedPlayers: integer(ez[2]), publishedPayoutDollars: integer(ez[3].slice(1)), periodLabel: '4:30 AM–11:59 PM on draw date'};
  }
  return {id: `co-${game}-${date}`, game: def.name, drawDate: date, sourceUrl, tiers, ezMatch, prizeNotes,
    limitations: 'Source-reported winners, not verified distinct tickets. Variants are separate; no combined total or retailer allocation. Draw date has no verified event time. EZ Match players and dollars are separate from Cash 5 draw tiers.'};
}

function parseColoradoPick3(html, sourceUrl) {
  const url = new URL(sourceUrl);
  const path = url.pathname.match(/^\/en\/games\/pick3\/drawings\/(\d{4}-\d{2}-\d{2}):(MD|EV)\/$/);
  if (url.origin !== 'https://www.coloradolottery.com' || !path || url.search || url.hash) throw Error('Invalid Colorado Pick 3 URL');
  const date = path[1];
  if (!Number.isFinite(Date.parse(date)) || new Date(date).toISOString().slice(0,10) !== date) throw Error('Invalid Colorado Pick 3 date');
  const [y,m,d] = date.split('-').map(Number);
  const drawingSession = path[2] === 'MD' ? 'Midday' : 'Evening';
  const months = ['Jan.', 'Feb.', 'March', 'April', 'May', 'June', 'July', 'Aug.', 'Sept.', 'Oct.', 'Nov.', 'Dec.'];
  const headings = [...html.matchAll(/<h1\b[^>]*>([\s\S]*?)<\/h1>/gi)].map(m => clean(m[1]));
  if (headings.length !== 1 || headings[0] !== `Pick 3 Drawing for ${months[m-1]} ${d}, ${y}: ${drawingSession}`) throw Error('Mismatched Colorado Pick 3 heading/session');
  const tables = [...html.matchAll(/<table\b[^>]*>([\s\S]*?)<\/table>/gi)];
  if (tables.length !== 1) throw Error('Unexpected Colorado Pick 3 tables');
  const columns = ['Bet Type', ...['0.50','1.00','2.00','5.00'].map(w => `$${w} Bet (Winners)`)];
  const headers = [...tables[0][1].matchAll(/<th\b[^>]*>([\s\S]*?)(?=<th\b|<\/tr>)/gi)].map(m => clean(m[1]));
  if (headers.join('|') !== columns.join('|')) throw Error('Unexpected Colorado Pick 3 wager columns');
  const names = ['Exact Order','Any Order','Combined Exact Order','Combined Any Order','Front Pair','Back Pair'];
  const rows = [...tables[0][1].matchAll(/<tr\b[^>]*>([\s\S]*?)<\/tr>/gi)].filter(m=>/<td\b/i.test(m[1]));
  if (rows.length !== names.length) throw Error('Missing Colorado Pick 3 bet types');
  const tiers = rows.flatMap((row,i)=>{
    const cells = [...row[1].matchAll(/<td\b([^>]*)>([\s\S]*?)(?=<td\b|$)/gi)];
    if (cells.length !== 5 || !cells.every((c,j)=>c[1].includes(`data-label="${columns[j]}"`)) || clean(cells[0][2]) !== names[i]) throw Error('Invalid Colorado Pick 3 cells');
    return cells.slice(1).map((cell,j)=>{
      const unavailable = (i===2 || i===3) && j===0;
      const text = clean(cell[2]);
      const wagerDollars = [0.5,1,2,5][j];
      if (unavailable) {
        if (!['&bull;','•'].includes(text)) throw Error('Changed Colorado Pick 3 unavailable wager');
        return {match:names[i],variant:'Base',wagerDollars,reportedWinners:null,prizeLabel:null,available:false};
      }
      const pair = [...cell[2].matchAll(/<span\b[^>]*>([\s\S]*?)<\/span>/gi)].map(m=>clean(m[1]));
      if (pair.length !== 2 || text !== pair.join(' ') || !/^\$(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)$/.test(pair[0])) throw Error('Invalid Colorado Pick 3 prize/count pair');
      return {match:names[i],variant:'Base',wagerDollars,reportedWinners:integer(pair[1]),prizeLabel:pair[0],available:true};
    });
  });
  return {id:`co-pick3-${date}-${path[2]}`,game:'Pick 3',drawDate:date,drawingSession,sourceUrl,tiers,ezMatch:null,prizeNotes:[],
    limitations:'Source-reported winners by bet type and wager, not verified distinct tickets. No combined total or retailer allocation. Unavailable wagers are not zero wins. Draw date has no verified event time.'};
}
