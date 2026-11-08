from datetime import date
from pathlib import Path
import unittest
from tooling.delaware_megamillions_report import parse, SOURCE
RAW=(Path(__file__).parents[1]/'fixtures/delaware/megamillions_report.html').read_text()

class MegaReportTest(unittest.TestCase):
    def test_literal_counts_prizes_and_totals_stay_separate(self):
        r=parse(RAW,source_url=SOURCE,observed_date=date(2026,11,6))['rows'][0]
        self.assertEqual(r['drawDate'],'2026-11-03')
        self.assertEqual(len(r['categories']),41)
        self.assertEqual(r['categories'][0]['publishedCount'],0)
        self.assertEqual(r['categories'][0]['sourcePrize'],'$505,000,000.00')
        self.assertEqual([v['publishedCount'] for v in r['sourceMultiplierTotals']],[466,354,146,78,29])
        self.assertNotIn('totalPayout',r)

    def test_identity_date_and_columns_fail_closed(self):
        for old,new in [('Number of Delaware Winners','National Winners'),('11/03/2026','11/04/2026'),
                        ('11%2F03%2F2026','11%2F04%2F2026'),('Baseline Prize','Paid Prize'),
                        ('$2,000,000','$2,000,001'),('5 + Mega Jackpot','5 + Other')]:
            self.assertIn(old,RAW)
            with self.subTest(old=old),self.assertRaises(ValueError):
                parse(RAW.replace(old,new,1),source_url=SOURCE,observed_date=date(2026,11,6))

    def test_duplicate_report_rejects(self):
        from lxml import html
        tree=html.fromstring(RAW)
        panel=tree.xpath('//div[@id="headingWinners20261103"]')[0].getparent()
        tree.append(html.fromstring(html.tostring(panel)))
        with self.assertRaises(ValueError):parse(html.tostring(tree),source_url=SOURCE,observed_date=date(2026,11,6))

if __name__=='__main__':unittest.main()
