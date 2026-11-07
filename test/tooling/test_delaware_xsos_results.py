from datetime import date
from pathlib import Path
import unittest
from tooling.delaware_xsos_results import parse

FIXTURES = Path(__file__).parents[1] / 'fixtures/delaware'
RAW = (FIXTURES / 'xsos_november.html').read_text()
URL = 'https://www.delottery.com/Winning-Numbers/Search-Winners/2026/11/PowerballXsAndOs'


class XsOsResultsTest(unittest.TestCase):
    def parse(self, raw=RAW, source_url=URL, month=11):
        return parse(raw, year=2026, month=month, source_url=source_url,
                     observed_date=date(2026, 11, 6))

    def test_source_logos_and_previous_month(self):
        rows = self.parse()['results']
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]['drawDate'], '2026-11-01')
        self.assertEqual([t['code'] for t in rows[0]['teams']],
                         ['ARI', 'ATL', 'BAL', 'DET', 'GB', 'LV', 'PIT', 'WAS'])
        self.assertEqual(rows[0]['teams'][0]['name'], 'Arizona Cardinals')
        self.assertNotIn('numbers', rows[0])
        october = self.parse((FIXTURES / 'xsos_october.html').read_text(),
                             URL.replace('/11/', '/10/'), 10)['results']
        self.assertEqual(len(october), 4)
        self.assertEqual(october[0]['drawDate'], '2026-10-25')

    def test_changed_identity_structure_and_dates_fail_closed(self):
        with self.assertRaises(ValueError):
            self.parse(source_url=URL+'/other')
        for old, new in [('Search Winners | Delaware Lottery', 'Other'),
                         ('November 1, 2026', 'November 8, 2026'),
                         ('Winning logos for', 'Wrong date'),
                         ('pb-xsos-draw-results', 'missing-results'),
                         ('pb-xsos-draw-logo"', 'missing-logo"'),
                         ('Logo/ari', 'Logo/atl'),
                         ('>ARI<', '>123<'),
                         ('>Arizona Cardinals<', '><')]:
            with self.subTest(old=old), self.assertRaises(ValueError):
                self.parse(RAW.replace(old, new, 1))


if __name__ == '__main__':
    unittest.main()
