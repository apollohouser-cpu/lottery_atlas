from datetime import date
from pathlib import Path
import unittest
from tooling.delaware_play_report import parse


class PlayReportTest(unittest.TestCase):
    def read(self,n):return (Path(__file__).parents[1]/f'fixtures/delaware/play{n}_report.html').read_text()
    def parse(self,n,raw):return parse(raw,digits=n,source_url=f'https://www.delottery.com/Drawing-Games/Play-{n}/Number-Of-Winners',observed_date=date(2026,11,6))
    def test_totals_not_duplicated_and_missing_payout_not_invented(self):
        r=self.parse(3,self.read(3));self.assertEqual(r['sourceTotals']['Total Winners'],'195');self.assertEqual(r['session'],'day')
        r=self.parse(5,self.read(5));self.assertNotIn('Total Won',r['sourceTotals']);self.assertEqual(r['categories'][1]['source50CentBetWins'],'Varies')
    def test_changed_session_and_responsive_totals_rejected(self):
        for old,new in [('aria-label="Day"','aria-label="Night"'),('Play3Day','Play3Night'),('>195<','>196<'),('11/6/2026','11/7/2026'),('Number of Winners','Number of Tickets')]:
            raw=self.read(3)
            if old=='>195<':raw=raw.replace('195','196',1)
            else:raw=raw.replace(old,new,1)
            with self.subTest(old=old),self.assertRaises(ValueError):self.parse(3,raw)
