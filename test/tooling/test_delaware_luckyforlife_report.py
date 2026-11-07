from datetime import date
from pathlib import Path
import unittest
from tooling.delaware_luckyforlife_report import parse,SOURCE
RAW=(Path(__file__).parents[1]/'fixtures/delaware/luckyforlife_report.html').read_text()


class LegacyReportTest(unittest.TestCase):
    def parse(self,raw=RAW):return parse(raw,source_url=SOURCE,observed_date=date(2026,11,6))
    def test_historical_rows_not_current_activity(self):
        r=self.parse();self.assertEqual(r['status'],'historical/legacy');self.assertIsNone(r['sourceGeography'])
        self.assertEqual(len(r['rows']),10);self.assertEqual(r['rows'][0]['drawDate'],'2026-02-21')
        self.assertEqual(r['rows'][0]['categories'][7],{'label':'2+0','publishedCount':626})
    def test_identity_date_and_count_corruption_rejected(self):
        for old,new in [('Lucky For Life','Powerball'),('02/20/2026','02/21/2026'),('02/21/2026','11/07/2026'),('data-label="2+0"','data-label="2+1"'),('626','-1')]:
            with self.subTest(old=old),self.assertRaises(ValueError):self.parse(RAW.replace(old,new,1))
