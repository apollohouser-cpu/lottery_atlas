import importlib.util
from datetime import date
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('idaho', Path(__file__).resolve().parents[2] / 'tooling/import_idaho_scratch_catalog.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
TODAY = date(2026,9,21)
GAME = dict(id='1919',name='Mega Cash',path='/games/scratch/mega-cash',cost=5,topPrize=1000,tiers={1000:0,25:3})


def table(headers,rows,attrs=''):
    return '<table '+attrs+'><thead><tr>'+''.join('<th>'+h+'</th>' for h in headers)+'</tr></thead><tbody>'+''.join('<tr>'+''.join('<td>'+c+'</td>' for c in row)+'</tr>' for row in rows)+'</tbody></table>'


def catalog():
    return '<li data-game-id="1919"><h5>Mega Cash</h5><a class="image-link" href="/games/scratch/mega-cash"></a><span class="game__info-price">$5.00</span><span class="game__info-top-prize-value">$1,000</span>'+table(['Prize','Remaining'],[['$1000','0'],['$25','3']],'class="scratch-prizes"')+'</li>'


def detail():
    return '<section class="section-game"><header><h5>Mega Cash</h5></header><img src="/sites/default/files/1919_scratched.jpg"><ul class="list-badges"><li><h4>$1,000</h4>Top Prize</li><li><h4>$5.00</h4>Ticket</li></ul><div id="tab3">'+table(['Number of Prizes','Prize Amount','Remaining Prizes','Odds'],[['2','$1,000','0','1:1000'],['5','$25','3','1:50'],['100','$5','*not available','1:10']],'class="prize-chart-table"')+'<p>Prizes are updated once daily. Prizes below $25 are not available.</p><p>Launch Date: 09/08/2026</p></div></section>'


class IdahoTest(unittest.TestCase):
    def test_zero_inventory_unknown_dates_and_lower_tiers(self):
        g=m.parse_detail(detail(),m.parse_catalog(catalog())['1919'],{},TODAY)
        self.assertEqual(g['topPrizesRemaining'],0)
        self.assertIsNone(g['sourceDate'])
        self.assertEqual(g['unavailableRemainingPrizeAmounts'],[5])
        self.assertEqual(len(g['prizeTiers']),2)
        self.assertEqual(g['originalTopPrizes'],2)
        self.assertIn('not zero',g['inventoryNote'])

    def test_missing_launch_not_invented_and_future_excluded(self):
        g=m.parse_detail(detail().replace('Launch Date: 09/08/2026',''),GAME,{},TODAY)
        self.assertEqual(m.parse_detail(detail().replace('09/08/2026','9/8/2026'),GAME,{},TODAY)['startDate'],'2026-09-08')
        self.assertNotIn('startDate',g)
        self.assertIn('Launch date not published',g['inventoryNote'])
        self.assertIsNone(m.parse_detail(detail(),GAME,{},date(2026,9,7)))

    def test_detail_mismatches_fail(self):
        for raw in [detail().replace('Mega Cash','Other'),detail().replace('1919_scratched','1920_scratched'),detail().replace('$5.00','$10.00'),detail().replace('>3<','>6<'),detail().replace('*not available','0'),detail().replace('>0<','>1<'),detail().replace('Remaining Prizes','Claims'),detail().replace('once daily','weekly')]:
            with self.subTest(raw=raw),self.assertRaises(ValueError):m.parse_detail(raw,GAME,{},TODAY)

    def test_duplicate_and_malformed_catalog(self):
        for raw in [catalog()+catalog(),catalog().replace('$25','$5'),catalog().replace('/games/scratch/mega-cash','https://example.com/game'),catalog().replace('>3<','>-1<'),catalog().replace('Remaining','Claims')]:
            with self.subTest(raw=raw),self.assertRaises(ValueError):m.parse_catalog(raw)

    def test_end_inclusive_and_claim_conflict_preserved(self):
        raw=table(['Number','Game Name','Official Game End','Last Day to Claim'],[['1919','Mega Cash','September 21, 2026','March 20, 2027']])
        with self.assertRaises(ValueError):m.parse_claims(table(['Number','Game Name','Official Game End','Last Day to Claim'],[]))
        claims=m.parse_claims(raw)
        self.assertIsNotNone(m.parse_detail(detail(),GAME,claims,TODAY))
        self.assertIsNone(m.parse_detail(detail(),GAME,claims,date(2026,9,22)))
        conflict=m.parse_claims(raw.replace('March 20','March 19'))
        self.assertFalse(conflict['1919']['windowMatches'])
        self.assertEqual(conflict['1919']['claim'],date(2027,3,19))
        with self.assertRaises(ValueError):m.parse_detail(detail(),GAME,conflict,TODAY)
        with self.assertRaises(ValueError):m.parse_claims(raw.replace('March 20, 2027','March 20, 2026'))

if __name__ == '__main__':unittest.main()
