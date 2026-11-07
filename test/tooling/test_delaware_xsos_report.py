from datetime import date
from pathlib import Path
import unittest
from tooling.delaware_xsos_report import parse, SOURCE

RAW = (Path(__file__).parents[1] / 'fixtures/delaware/xsos_report.html').read_text()


class XsOsReportTest(unittest.TestCase):
    def parse(self, raw=RAW, source_url=SOURCE):
        return parse(raw, source_url=source_url, observed_date=date(2026, 11, 6))

    def test_preserves_qualified_categories(self):
        result = self.parse()
        self.assertEqual(result['sourceGeography'], 'Delaware')
        self.assertEqual(len(result['rows']), 8)
        self.assertEqual(result['rows'][0]['drawDate'], '2026-11-01')
        self.assertEqual([c['publishedCount'] for c in result['rows'][0]['categories']], [0, 0, 3, 39, 243])
        self.assertNotIn('total', result)
        self.assertNotIn('payout', result['rows'][0])

    def test_rejects_semantic_drift(self):
        with self.assertRaises(ValueError):
            self.parse(source_url=SOURCE+'/other')
        for old, new in [('Number of Delaware Winners', 'National Winners'),
                         ('>Match 8<', '>Match 9<'),
                         ('data-label="Match 7"', 'data-label="Match 8"'),
                         ('11/01/2026', '11/08/2026'),
                         ('10/25/2026', '11/01/2026'),
                         ('>243<', '>-1<'), ('>243<', '>1.5<'),
                         ('data-label="Match 8"', 'colspan="2" data-label="Match 8"')]:
            with self.subTest(old=old), self.assertRaises(ValueError):
                self.parse(RAW.replace(old, new, 1))


if __name__ == '__main__':
    unittest.main()
