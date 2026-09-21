import importlib.util
from datetime import date
from pathlib import Path
import unittest
spec=importlib.util.spec_from_file_location('la',Path(__file__).resolve().parents[2]/'tooling/import_louisiana_scratch_catalog.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
GAME=dict(number='1605',price='10',top_prize='200000',start_date='03/24/2025',game=dict(name='Example',link='https://louisianalottery.com/game/1605-example/'))
def detail():return '''<title>1605 - Example</title><li><em>$10</em>Ticket Price</li><ul class="hero__game-meta"><li>Launch Date: <time datetime="2025-03-24">Mar 24, 2025</time></li></ul><table><caption>Scratch-offs Prize Payouts</caption><thead><tr><th>Tier Prize</th><th>Odds of Winning</th><th>Total</th><th>Claimed</th><th>Remaining</th></tr></thead><tbody><tr><td>$200,000</td><td>1 in 100</td><td>4</td><td>4</td><td>0</td></tr><tr><td>TICKET</td><td>1 in 10</td><td>100</td><td>20</td><td>80</td></tr></tbody></table><p>Last Updated: 09/20/2026 09:42:49 PM CDT</p>'''
class LouisianaTest(unittest.TestCase):
    def test_zero_count_and_categorical_ticket(self):
        g=m.parse_detail(detail(),GAME,date(2026,9,20))
        self.assertEqual(g['topPrizesRemaining'],0);self.assertNotIn('prizeAmount',g['prizeTiers'][1])
        self.assertEqual(g['sourceTimestamp'],'2026-09-20T21:42:49-05:00')
    def test_expired_detail_never_becomes_inventory(self):
        self.assertIsNone(m.parse_detail(detail()+'This game expired on Feb 4, 2026.',GAME,date(2026,9,20)))
        raw=detail().replace('</ul>','<li>Final Redemption Date: Sep 19, 2026</li></ul>')
        self.assertIsNone(m.parse_detail(raw,GAME,date(2026,9,20)))
    def test_claim_deadline_is_inclusive(self):
        raw=detail().replace('</ul>','<li>Final Redemption Date: Sep 20, 2026</li></ul>')
        self.assertEqual(m.parse_detail(raw,GAME,date(2026,9,20))['lastDayToRedeem'],'2026-09-20')
    def test_inventory_mismatch_and_negative_rejected(self):
        for raw in [detail().replace('<td>80</td>','<td>81</td>'),detail().replace('<td>0</td>','<td>-1</td>')]:
            with self.subTest(raw=raw),self.assertRaises(ValueError):m.parse_detail(raw,GAME,date(2026,9,20))
    def test_identity_price_and_timestamp_rejected(self):
        for raw in [detail().replace('1605 -','9999 -'),detail().replace('<em>$10','<em>$20'),detail().replace('CDT','XYZ')]:
            with self.subTest(raw=raw),self.assertRaises(ValueError):m.parse_detail(raw,GAME,date(2026,9,20))
if __name__=='__main__':unittest.main()
