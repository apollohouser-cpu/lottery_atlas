from datetime import date
from pathlib import Path
import unittest
from tooling.delaware_doubleplay_report import parse, SOURCE

RAW = (Path(__file__).parents[1] / 'fixtures/delaware/doubleplay_report.html').read_text()

class DoublePlayReportTest(unittest.TestCase):
    def test_separate_report_retains_categories(self):
        result = parse(RAW, source_url=SOURCE, observed_date=date(2026,11,6))
        self.assertEqual(result['game'], 'Powerball Double Play')
        self.assertEqual(len(result['rows']), 10)
        self.assertEqual(result['rows'][0]['drawDate'], '2026-11-04')
        self.assertEqual([v['publishedCount'] for v in result['rows'][0]['categories']], [0,0,0,0,0,23,18,135,303])
        self.assertNotIn('total', result)

    def test_conflicting_base_table_cannot_contaminate_doubleplay(self):
        base = '<table><thead><tr><th colspan="10">Power Play Winners</th></tr></thead><tbody><tr><td>999999</td></tr></tbody></table>'
        result = parse(RAW.replace('<h3>', base+'<h3>', 1), source_url=SOURCE, observed_date=date(2026,11,6))
        self.assertEqual(len(result['rows']), 10)
        self.assertNotIn(999999, [c['publishedCount'] for r in result['rows'] for c in r['categories']])

    def test_identity_and_category_drift_reject(self):
        for old,new in [('Double Play® Winners','Power Play Winners'), ('Number of Delaware Winners','National Winners'),
                        ('data-label="5+0"','data-label="4+0"'), ('11/04/2026','11/07/2026'), ('303','-1')]:
            with self.subTest(old=old), self.assertRaises(ValueError):
                parse(RAW.replace(old,new,1),source_url=SOURCE,observed_date=date(2026,11,6))

if __name__ == '__main__': unittest.main()
