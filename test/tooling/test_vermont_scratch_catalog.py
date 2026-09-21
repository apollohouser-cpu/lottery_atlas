import importlib.util
from datetime import date
from pathlib import Path
import unittest

spec=importlib.util.spec_from_file_location('vt',Path(__file__).resolve().parents[2]/'tooling/import_vermont_scratch_catalog.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
TODAY=date(2026,9,21)
GAME=dict(id='1824',name='Bank Vault',path='/bank-vault',price=5,tiers=[dict(prizeAmount=20000,remaining=0),dict(prizeAmount=500,remaining=4)])
DATES={'1824':dict(top=20000,start=date(2025,1,10),end=date(2026,4,10),claim=date(2027,4,10))}

def field(name,value):
    return f'<div class="field-name-{name}"><div class="field-item">{value}</div></div>'

def page():
    value='<div class="instant-ticket-right-half"><h3><span class="fieldAsTitle">$20,000</span></h3></div>'
    for name,text in [('field-game-id','1824'),('field-price','$5'),('field-ticket-start-date','01/10/2025'),('field-last-day-to-cash','04/10/2027'),('field-number-of-tickets','420,000'),('field__of-tickets-sold','98')]:
        value+=field(name,text)
    for amount,count in [('$20,000','0'),('$500','4')]:
        value+=f'<div class="field-name-field-unclaimed-top-prizes"><div class="field-label">{amount}</div><div class="field-item">{count}</div></div>'
    return '<html>'+value+'</html>'

def report():
    headers=['Price','Game #','Game Name','Top Prizes','Unclaimed Top Prizes','Total Unclaimed','% Sold','# Of Tickets']
    cells=['$5','1824','<a href="/bank-vault">Bank Vault</a>','$20,000<br>$500','0<br>4','$73,790','98','420,000']
    return '<table id="tblData"><thead><tr>'+''.join('<th>'+h+'</th>' for h in headers)+'</tr></thead><tbody><tr>'+''.join('<td>'+c+'</td>' for c in cells)+'</tr></tbody></table>'

class VermontTest(unittest.TestCase):
    def test_zero_counts_unknown_dates_and_end_notice(self):
        game=m.parse_detail(page(),GAME,DATES,TODAY)
        self.assertEqual(game['topPrizesRemaining'],0)
        self.assertIsNone(game['sourceDate'])
        self.assertIn('not published',game['inventoryNote'])
        self.assertIn('2027-04-10',game['inventoryNote'])

    def test_deadline_inclusive_and_future_launch(self):
        self.assertIsNotNone(m.parse_detail(page(),GAME,DATES,date(2027,4,10)))
        self.assertIsNone(m.parse_detail(page(),GAME,DATES,date(2027,4,11)))
        self.assertIsNone(m.parse_detail(page(),GAME,DATES,date(2024,1,1)))

    def test_identity_price_top_and_tier_mismatch_rejected(self):
        for raw in [page().replace('1824','1825'),page().replace('>$5<','>$10<'),page().replace('>$20,000<','>$30,000<',1),page().replace('>4<','>5<'),page().replace('>4<','>-1<'),page().replace('04/10/2027','04/11/2027')]:
            with self.subTest(raw=raw),self.assertRaises(ValueError):
                m.parse_detail(raw,GAME,DATES,TODAY)

    def test_report_parallel_lists_and_duplicate_identity(self):
        self.assertEqual(m.parse_report(report())['1824']['tiers'],GAME['tiers'])
        row=report().split('<tbody>')[1].split('</tbody>')[0]
        for raw in [report().replace('0<br>4','0'),report().replace('</tbody>',row+'</tbody>'),report().replace('$20,000<br>$500','$500<br>$500'),report().replace('Unclaimed Top Prizes','Claims')]:
            with self.subTest(raw=raw),self.assertRaises(ValueError):m.parse_report(raw)

    def test_tbd_and_mixed_year_formats(self):
        self.assertIsNone(m.parse_date('TBD'))
        self.assertEqual(m.parse_date('4/10/27'),m.parse_date('04/10/2027'))
        dates={'1824':{**DATES['1824'],'claim':None,'end':None}}
        raw=page().replace(field('field-last-day-to-cash','04/10/2027'),'')
        game=m.parse_detail(raw,GAME,dates,TODAY)
        self.assertNotIn('lastDayToRedeem',game)
        self.assertNotIn('endDate',game)

if __name__=='__main__':unittest.main()
