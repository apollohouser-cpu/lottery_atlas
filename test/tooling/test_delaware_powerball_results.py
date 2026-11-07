from datetime import date
from pathlib import Path
import unittest
from tooling.delaware_powerball_results import parse

RAW = (Path(__file__).parents[1] / 'fixtures/delaware/powerball_november.html').read_text()
URL = 'https://www.delottery.com/Winning-Numbers/Search-Winners/2026/11/PowerBall'


class PowerballResultsTest(unittest.TestCase):
    def parse(self, raw=RAW, source_url=URL):
        return parse(raw, year=2026, month=11, source_url=source_url, observed_date=date(2026, 11, 6))

    def test_pairs_preserve_independent_draws(self):
        rows = self.parse()['results']
        self.assertEqual(len(rows), 4)
        self.assertEqual(rows[0]['numbers'], [15, 34, 41, 53, 56])
        self.assertEqual(rows[1]['numbers'], [3, 6, 23, 58, 65])
        self.assertEqual(rows[0]['powerPlay'], 2)
        self.assertNotIn('powerPlay', rows[1])
        self.assertEqual(rows[0]['drawDate'], rows[1]['drawDate'])

    def test_changed_identity_and_pairs_rejected(self):
        with self.assertRaises(ValueError):
            self.parse(source_url=URL+'/other')
        for old, new in [('>Double play<', '>Another game<'),
                         ('>2X<', '>6X<'), ('>21</li>', '>27</li>'),
                         ('>56</li>', '>15</li>'), ('>65</div>', '>70</div>'),
                         ('ball-color-black">03', 'ball-color-red">03'),
                         ('11/02/26', '11/04/26'), ('11/04/26', '11/07/26'),
                         ('powerball-search-results-secondary-balls', 'missing-secondary')]:
            with self.subTest(old=old), self.assertRaises(ValueError):
                self.parse(RAW.replace(old, new, 1))


if __name__ == '__main__':
    unittest.main()
