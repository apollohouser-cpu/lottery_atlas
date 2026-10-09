import test from 'node:test';
import assert from 'node:assert/strict';
import {claimDate, archivePage} from '../../tooling/north_carolina_archive.mjs';
const page = (n, next='') => `<span id="ctl00_MainContent_WinnersListDataPager"><a>Previous</a>&nbsp;<span>${n}</span>&nbsp;${next}<a disabled="disabled">End</a></span><th>Claimed</th><a href="/Winner?id=1">Example</a>`;
test('claim dates reject rollover and preserve date-only noon convention',()=>{
 assert.equal(claimDate('02/28/2026').toISOString(),'2026-02-28T12:00:00.000Z');
 for(const date of ['02/30/2026','13/01/2026','01/01/2099','2026-01-01']) assert.throws(()=>claimDate(date));
});
test('pagination requires current identity and exact next route, never silent empty',()=>{
 assert.equal(archivePage(page(1,'<a href="/WinnersAll?g=PB&amp;p=2">Next</a>'),{code:'PB'},1).hasNext,true);
 assert.equal(archivePage(page(2),{code:'PB'},2).hasNext,false);
 for(const html of ['',page(2),page(1,'<a href="/WinnersAll?g=MM&amp;p=2">Next</a>'),page(1)+'<a href="/Winner?id=1">Duplicate</a>']) assert.throws(()=>archivePage(html,{code:'PB'},1));
});

import {archiveRows} from '../../tooling/north_carolina_archive.mjs';
const row = (prize, location='Sample Market, Example City') => `<td>${prize}</td><td>10/07/2026</td><td><a href="/Winner?id=1">Example</a></td><td>${location}</td>`;
test('every linked row is accounted for and shared prize markers stay explicit',()=>{
 assert.equal(archiveRows(row('$5,000'))[0].sharedPrize,false);
 assert.equal(archiveRows(row('$50,000<sup>*</sup>'))[0].sharedPrize,true);
 assert.equal(archiveRows(row('$50,000*'))[0].sharedPrize,true);
 for(const html of [row('$4,999'),row('$5,00'),row('$5,000?'),row('$5,000').replace('<td>$','<td class="changed">$')]) assert.throws(()=>archiveRows(html));
});
