import test from 'node:test';
import assert from 'node:assert/strict';
import {parseColoradoDrawReport} from '../../tooling/colorado_draw_reports.mjs';
const url = game => `https://www.coloradolottery.com/en/games/${game}/drawings/2026-10-03/`;
const row = (name,count='0',prize='$1') => `<tr><td data-label="Match">${name}<td data-label="Winners">${count}<td data-label="Prize">${prize}</tr>`;
const table = rows => `<table><tr><th>Match<th>Winners<th>Prize</tr>${rows}</table>`;
const cash = () => '<h1>Cash 5 Drawing for Saturday, 10/3/26</h1>'+table(['5 of 5','4 of 5','3 of 5','2 of 5'].map(n=>row(n)).join(''))+'10/3/2026 EZ MATCH 1,105 players won a total of $3,295!* EZ Match winnings calculated between 4:30AM and 11:59PM during specified Cash5 draw date.';
test('Cash 5 keeps EZ Match players/dollars separate and preserves zero tiers',()=>{
 const r=parseColoradoDrawReport('cash5',cash(),url('cash5'));
 assert.equal(r.tiers.length,4);assert.equal(r.tiers[0].reportedWinners,0);
 assert.equal(r.ezMatch.reportedPlayers,1105);assert.equal(r.ezMatch.publishedPayoutDollars,3295);
 assert.equal(r.winningTickets,undefined);
});
test('Lotto Plus and multiplier tiers remain separate with literal prizes',()=>{
 const names=['6 of 6',...[5,4,3].flatMap(n=>[2,3,4,5].map(m=>`${n} of 6 (${m}X)`))];
 const html='<h1>Colorado Lotto+ Drawing for Saturday, 10/3/26</h1>'+table([...names,...names.map(n=>'Plus - '+n)].map(n=>row(n,'1','$500')).join(''));
 const r=parseColoradoDrawReport('lotto',html,url('lotto'));
 assert.equal(r.tiers.length,26);assert.equal(r.tiers[13].variant,'Plus');assert.equal(r.tiers[2].prizeLabel,'$500');assert.equal(r.ezMatch,null);
});
test('Rejects malformed counts, missing/duplicate tiers, wrong date, jurisdiction and period',()=>{
 for(const html of [cash().replace('>0<','>-1<'),cash().replace('>0<','>1.5<'),cash().replace('>0<','>1,00<'),cash().replace('4 of 5','5 of 5'),cash().replace(row('2 of 5'),''),cash().replace('10/3/26','10/2/26'),cash().replace('11:59PM','10:59PM'),cash().replace('10/3/2026 EZ','10/2/2026 EZ'),cash()+table(row('extra')),cash().replace('>Winners<','>National Winners<')]) assert.throws(()=>parseColoradoDrawReport('cash5',html,url('cash5')));
 assert.throws(()=>parseColoradoDrawReport('cash5',cash(),url('cash5').replace('www.coloradolottery.com','example.com')));
 assert.throws(()=>parseColoradoDrawReport('cash5',cash(),url('cash5').replace('2026-10-03','2026-02-30')));
});

test('Millionaire for Life preserves annual prizes and requires sharing limitations',()=>{
 const names=['5 + MB','5','4 + MB','4','3 + MB','3','2 + MB','2','1 + MB'];
 const html='<h1>Millionaire for Life Drawing for Saturday, 10/3/26</h1>'+table(names.map((n,i)=>row(n,'0',i<2?['$1,000,000 a year for life*','$100,000 a year for life**'][i]:'$8')).join('')).replaceAll('Winners','Colorado Winners').replaceAll('Prize','Amount')+'<small>*Divided by the number of winners</small><small>**If 21+ total winners, divided by the number of winners</small>';
 const r=parseColoradoDrawReport('millionaireforlife',html,url('millionaireforlife'));
 assert.equal(r.tiers.length,9);assert.equal(r.tiers[0].prizeLabel,'$1,000,000 a year for life*');assert.equal(r.prizeNotes.length,2);
 for(const altered of [html.replace('$1,000,000 a year for life*','$20,000,000'),html.replace('21+','22+'),html.replaceAll('Colorado Winners','National Winners')]) assert.throws(()=>parseColoradoDrawReport('millionaireforlife',altered,url('millionaireforlife')));
});

const pick = session => {
 const names=['Exact Order','Any Order','Combined Exact Order','Combined Any Order','Front Pair','Back Pair'];
 const columns=['Bet Type',...['0.50','1.00','2.00','5.00'].map(w=>`$${w} Bet (Winners)`)];
 return `<h1>Pick 3 Drawing for Oct. 3, 2026: ${session}</h1><table><tr>${columns.map(c=>`<th>${c}`).join('')}</tr>`+names.map((n,i)=>`<tr><td data-label="Bet Type">${n}`+columns.slice(1).map((c,j)=>`<td data-label="${c}">${(i===2||i===3)&&j===0?'&bull;':'<span>$40</span> <span>0</span>'}</td>`).join('')+'</tr>').join('')+'</table>';
};
test('Pick 3 sessions and wager cells preserve unavailable versus zero',()=>{
 for(const [code,session] of [['MD','Midday'],['EV','Evening']]){
  const r=parseColoradoDrawReport('pick3',pick(session),url('pick3').replace('/2026-10-03/','/2026-10-03:'+code+'/'));
  assert.equal(r.drawingSession,session);assert.equal(r.tiers.length,24);
  assert.equal(r.tiers[0].reportedWinners,0);assert.equal(r.tiers[8].reportedWinners,null);assert.equal(r.tiers[8].available,false);assert.equal(r.tiers[9].wagerDollars,1);
 }
});
test('Pick 3 rejects session, wager, pair and missing-cell corruption',()=>{
 const u=url('pick3').replace('/2026-10-03/','/2026-10-03:MD/');
 for(const h of [pick('Evening'),pick('Midday').replaceAll('$0.50','$0.25'),pick('Midday').replace('&bull;','0'),pick('Midday').replace('<span>0</span>','<span>-1</span>'),pick('Midday').replace('Back Pair','Front Pair'),pick('Midday').replace('<span>$40</span>','')]) assert.throws(()=>parseColoradoDrawReport('pick3',h,u));
});
