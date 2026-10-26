import unittest
from pathlib import Path
from tooling.import_new_mexico_reports import parse_double_play

RAW=(Path(__file__).parent/'fixtures/new_mexico/double_play_report.html').read_text()
DRAW=dict(game='powerball',variant='double_play',session=None,date='2026-10-24')
class NewMexicoReportTests(unittest.TestCase):
    def test_exact_report(self):
        r=parse_double_play(RAW,DRAW)
        self.assertEqual((9,664,5967),(len(r['tiers']),r['totalPrizesWon'],r['totalPrizeValue']))
        self.assertEqual(0,r['tiers'][0]['sourceWinners'])
        self.assertEqual('source Winners / prizes won',r['countUnit'])
    def test_date_variant_session_join(self):
        for field,value in [('date','2026-10-21'),('variant','base'),('game','lottoamerica'),('session','DAY')]:
            with self.subTest(field=field),self.assertRaises(ValueError):parse_double_play(RAW,dict(DRAW,**{field:value}))
    def test_geography_and_title(self):
        for old,new in [('New Mexico','National'),('Double Play','Powerball')]:
            with self.subTest(old=old),self.assertRaises(ValueError):parse_double_play(RAW.replace(old,new),DRAW)
    def test_count_total_mutation(self):
        for old,new in [('>431<','>430<'),('>664<','>665<'),('$5,967','$5,968')]:
            self.assertIn(old,RAW)
            with self.subTest(old=old),self.assertRaises(ValueError):parse_double_play(RAW.replace(old,new),DRAW)
    def test_invalid_count(self):
        for value in ['-1','unknown','1.5','01']:
            with self.subTest(value=value),self.assertRaises(ValueError):parse_double_play(RAW.replace('>431<','>'+value+'<'),DRAW)
    def test_changed_prize_or_tier(self):
        for old,new in [('$500,000','$500,001'),('1 White Ball + Powerball','2 White Balls + Powerball')]:
            with self.subTest(old=old),self.assertRaises(ValueError):parse_double_play(RAW.replace(old,new),DRAW)
    def test_missing_duplicate_table(self):
        with self.assertRaises(ValueError):parse_double_play(RAW+RAW,DRAW)
        with self.assertRaises(ValueError):parse_double_play(RAW.replace('<table','<div').replace('</table>','</div>'),DRAW)
if __name__=='__main__':unittest.main()
