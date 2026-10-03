import test from 'node:test';
import assert from 'node:assert/strict';
import {readFileSync} from 'node:fs';
import {parseNewYorkPowerball} from '../../tooling/new_york_draw_reports.mjs';
const fixture = JSON.parse(readFileSync(new URL('./fixtures/new_york_powerball.json', import.meta.url)));
test('NY Powerball variants exclude national metadata and duplicate aliases', () => {
  const raw = structuredClone(fixture);
  raw.national_winners = [{prize_winners: 999999}];
  const report = parseNewYorkPowerball(raw);
  assert.deepEqual(report.tables.map(t => t.tiers.length), [9, 8, 9]);
  assert.equal(report.tables[0].tiers[1].reportedWinners, 0);
  assert.equal(report.tables[0].tiers[2].reportedWinners, 1);
  assert.equal(report.tables[2].tiers.reduce((s,t) => s+t.reportedWinners,0), 4432);
  assert.equal(report.tables[1].tiers[1].prizeLabel, '200000');
  assert.equal(report.sourcePublicationDate, null);
});
test('partial, duplicate and conflicting tables fail instead of zero-fill', () => {
  for (const mutate of [r => r.local_winners.pop(), r => r.local_winners[1]=r.local_winners[0],
    r => r.local_multiplier_winners[0].prize_winners=1,
    r => r.dp_local_winners[0].prize_winners=null]) {
    const raw=structuredClone(fixture); mutate(raw); assert.throws(()=>parseNewYorkPowerball(raw));
  }
});
test('invalid calendar dates and multipliers fail', () => {
  for (const change of [{date:'2026-02-30'}, {multiplier:'0'}, {draw_number:''}]) {
    assert.throws(()=>parseNewYorkPowerball({...fixture,...change}));
  }
});

import {parseNewYorkMegaMillions} from '../../tooling/new_york_draw_reports.mjs';
const mega = JSON.parse(readFileSync(new URL('./fixtures/new_york_mega_millions.json', import.meta.url)));
test('Mega Millions preserves five built-in multiplier groups without national counts', () => {
  const raw=structuredClone(mega); raw.national_winners=[{prize_winners:999999}];
  const report=parseNewYorkMegaMillions(raw);
  assert.deepEqual(report.tables.map(t=>t.tiers.length), [1,8,8,8,8,8]);
  assert.equal(report.tables[1].tiers[2].prizeLabel,'1000');
  assert.equal(report.tables[1].tiers[2].reportedWinners,3);
  assert.equal(report.tables.flatMap(t=>t.tiers).reduce((s,t)=>s+t.reportedWinners,0),17175);
});
test('Mega Millions missing, duplicated, unknown or null multiplier data fails', () => {
  for (const mutate of [r=>r.second_prz_multiplier_winners.pop(),
    r=>r.third_prz_multiplier_winners[1].mm_multiplier_level='2X',
    r=>r.fourth_prz_multiplier_winners[0].mm_multiplier_level='8X',
    r=>r.local_winners[0].prize_winners=null]) {
    const raw=structuredClone(mega);mutate(raw);assert.throws(()=>parseNewYorkMegaMillions(raw));
  }
});

import {parseNewYorkStateTiers} from '../../tooling/new_york_draw_reports.mjs';
const stateFixtures=['lotto','take5','mfl'].map(name=>JSON.parse(readFileSync(new URL('./fixtures/new_york_'+name+'.json',import.meta.url))));
test('state tiers preserve free plays, annual wording and session',()=>{
  const [lotto,take5,mfl]=stateFixtures.map(parseNewYorkStateTiers);
  assert.equal(lotto.tables[0].tiers.reduce((s,t)=>s+t.reportedWinners,0),10812);
  assert.equal(take5.drawingSession,'Midday');
  assert.equal(take5.tables[0].tiers[3].prizeLabel,'FREE PLAY');
  assert.equal(take5.tables[0].tiers.reduce((s,t)=>s+t.reportedWinners,0),29103);
  assert.equal(mfl.tables[0].tiers[0].prizeLabel,'$1 Million a Year for Life');
  assert.equal(mfl.tables[0].tiers.reduce((s,t)=>s+t.reportedWinners,0),8004);
});
test('state formats reject unknown sessions, lost tiers and altered annual/free-play labels',()=>{
  for(const [index,mutate] of [[0,r=>r.local_winners.pop()], [1,r=>r.draw_time='Night'],
    [1,r=>r.local_winners[3].prize_amount='0'],[2,r=>r.local_winners[0].prize_amount='1000000']]) {
    const r=structuredClone(stateFixtures[index]);mutate(r);assert.throws(()=>parseNewYorkStateTiers(r));
  }
});

import {parseNewYorkSharesOrPick10} from '../../tooling/new_york_draw_reports.mjs';
const shareFixtures=['numbers','win4','pick10'].map(n=>JSON.parse(readFileSync(new URL('./fixtures/new_york_'+n+'.json',import.meta.url))));
test('share counts and published dollars remain separate from tickets and tier payouts',()=>{
  const [numbers,win4,pick10]=shareFixtures.map(parseNewYorkSharesOrPick10);
  assert.equal(numbers.tables[0].tiers.reduce((s,t)=>s+t.reportedShares,0),10918);
  assert.equal(numbers.tables[0].tiers[0].reportedWinners,null);
  assert.equal(numbers.reportedTotalPrizes,699600);
  assert.equal(win4.reportedTotalPrizes,197900);
  assert.equal(win4.tables[0].tiers[0].prizeLabel,null);
  assert.equal(pick10.tables[0].tiers.reduce((s,t)=>s+t.reportedWinners,0),5116);
  assert.equal(pick10.reportedTotalPrizes,33100);
});
test('share tables reject lost pair rows, duplicate wagers, null dollars and missing counts',()=>{
  for(const mutate of [r=>r.local_winners.pop(),r=>r.local_winners[3]=r.local_winners[2],
    r=>r.total_prizes=null,r=>r.local_winners[0].prize_winners=null]) {
    const r=structuredClone(shareFixtures[0]);mutate(r);assert.throws(()=>parseNewYorkSharesOrPick10(r));
  }
});

import {parseNewYorkQuickDraw} from '../../tooling/new_york_draw_reports.mjs';
const quick=JSON.parse(readFileSync(new URL('./fixtures/new_york_quickdraw.json',import.meta.url)));
test('Quick Draw and Money Dots payouts never become counts',()=>{
  const report=parseNewYorkQuickDraw(quick);
  assert.equal(report.drawingSession,'21:00:00');
  assert.deepEqual(report.tables.map(t=>t.reportedTotalPrizes),[1305,45]);
  assert.deepEqual(report.tables.map(t=>t.reportedWinners),[null,null]);
  assert.equal(report.tables[1].drawnPrizeLabel,'5');
  const zero=structuredClone(quick);zero.secondary_prize_value.money_dots_prizes='0';
  zero.secondary_prize_value.money_dots_amount='0';
  assert.equal(parseNewYorkQuickDraw(zero).tables[1].reportedTotalPrizes,0);
});
test('Quick Draw missing payouts, impossible times and changed count fields fail',()=>{
  for(const mutate of [r=>r.jackpot=null,r=>r.secondary_prize_value.money_dots_prizes='',
    r=>r.draw_time='25:00:00',r=>r.local_winners=[{prize_winners:1}]]){
    const r=structuredClone(quick);mutate(r);assert.throws(()=>parseNewYorkQuickDraw(r));
  }
});

import {assertNewYorkReportContinuity} from '../../tooling/new_york_draw_reports.mjs';
test('report transaction rejects lost sessions, duplicate draws and intraday regression',()=>{
 const day={gameName:'NUMBERS',drawingSession:'Midday',drawDate:'2026-10-02',drawNumber:'1'};
 const night={...day,drawingSession:'Evening',drawNumber:'2'};
 assert.throws(()=>assertNewYorkReportContinuity([day,night],[day]));
 assert.throws(()=>assertNewYorkReportContinuity([],[day,day]));
 const q={gameName:'Quick Draw / Money Dots',drawingSession:'21:00:00',drawDate:'2026-10-02',drawNumber:'3'};
 assert.throws(()=>assertNewYorkReportContinuity([q],[{...q,drawingSession:'20:56:00',drawNumber:'2'}]));
 assert.doesNotThrow(()=>assertNewYorkReportContinuity([day,night],[day,night]));
});
