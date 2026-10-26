import unittest
from pathlib import Path
from lxml import html
from tooling.import_new_mexico_reports import parse_mega_millions
RAW=(Path(__file__).parent/'fixtures/new_mexico/megamillions_report.html').read_text()
DRAW=dict(game='megamillions',variant='base',date='2026-10-23',session=None,multiplier=None)
class MegaMillionsReportTests(unittest.TestCase):
    def test_all_per_play_groups(self):
        r=parse_mega_millions(RAW,DRAW)
        self.assertEqual((41,1054,20989),(len(r['tiers']),r['totalPrizesWon'],r['totalPrizeValue']))
        for m in [2,3,4,5,10]:self.assertEqual(8,len([t for t in r['tiers'] if t['multiplier']==m]))
    def test_exact_identity(self):
        for key,value in [('game','powerball'),('date','2026-10-20'),('session','DAY'),('variant','double_play'),('multiplier',3)]:
            with self.subTest(key=key),self.assertRaises(ValueError):parse_mega_millions(RAW,dict(DRAW,**{key:value}))
    def test_wrong_geography_or_multiplier(self):
        for old,new in [('New Mexico','National'),('With Multiplier 2X','With Multiplier 3X')]:
            with self.subTest(old=old),self.assertRaises(ValueError):parse_mega_millions(RAW.replace(old,new),DRAW)
    def test_missing_and_reordered_group(self):
        for remove in [True,False]:
            t=html.fromstring(RAW);tables=t.xpath('//table')
            if remove:tables[1].getparent().remove(tables[1])
            else:tables[2].addnext(tables[1])
            with self.subTest(remove=remove),self.assertRaises(ValueError):parse_mega_millions(html.tostring(t),DRAW)
    def test_changed_count_prize_and_total(self):
        for old,new in [('>303<','>302<'),('$2,000,000','$2,000,001'),('$20,989','$20,990'),('>1,054<','>1,055<')]:
            self.assertIn(old,RAW)
            with self.subTest(old=old),self.assertRaises(ValueError):parse_mega_millions(RAW.replace(old,new),DRAW)
    def test_unknown_jackpot_value_fails_closed(self):
        t=html.fromstring(RAW);r=t.xpath('//table')[0].xpath('.//tr')[-1];r.xpath('./td|./th')[1].text='1'
        with self.assertRaises(ValueError):parse_mega_millions(html.tostring(t),DRAW)
    def test_changed_spans(self):
        with self.assertRaises(ValueError):parse_mega_millions(RAW.replace('rowspan="2"','rowspan="3"',1),DRAW)
if __name__=='__main__':unittest.main()
