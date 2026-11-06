from pathlib import Path
from datetime import date
import unittest
from tooling.delaware_play_results import parse

FIXTURES = Path(__file__).parents[1] / 'fixtures/delaware'


class PlayResultsTest(unittest.TestCase):
    def parse(self, digits=3, raw=None, **overrides):
        args = dict(digits=digits, year=2026, month=11,
                    source_url=f'https://www.delottery.com/Winning-Numbers/Search-Winners/2026/11/Play{digits}',
                    observed_date=date(2026, 11, 6))
        args.update(overrides)
        return parse(raw or (FIXTURES / f'play{digits}_november.html').read_text(), **args)

    def test_three_games_six_explicit_sessions_and_partial_latest_day(self):
        for digits in (3, 4, 5):
            rows = self.parse(digits)['results']
            self.assertEqual(len(rows), 11)
            self.assertEqual(sum(r['session'] == 'day' for r in rows), 6)
            self.assertEqual(sum(r['session'] == 'night' for r in rows), 5)
            self.assertEqual([r['session'] for r in rows if r['drawDate'] == '2026-11-06'], ['day'])
            self.assertTrue(all(len(r['digits']) == digits for r in rows))

    def test_leading_zero_preserved_as_digit(self):
        raw = (FIXTURES / 'play3_november.html').read_text().replace('>1</li>', '>0</li>', 1)
        self.assertEqual(self.parse(raw=raw)['results'][0]['digits'][0], '0')

    def test_corrupt_row_rejected(self):
        raw = (FIXTURES / 'play3_november.html').read_text()
        for old, new in [('li-sun', 'li-unknown'), ('li-sun', 'li-sun li-moon'),
                         ('>1</li>', '>10</li>'), ('11/06/26', '11/07/26'),
                         ('11/06/26', '10/06/26'), ('11/06/26', '11/05/26'),
                         ('data-label="Game"', 'data-label="Other"')]:
            with self.subTest(old=old, new=new), self.assertRaises(ValueError):
                self.parse(raw=raw.replace(old, new, 1))

    def test_identity_rejected(self):
        with self.assertRaises(ValueError):
            self.parse(source_url='https://example.com/')
        with self.assertRaises(ValueError):
            self.parse(4, raw=(FIXTURES / 'play3_november.html').read_text())


if __name__ == '__main__':
    unittest.main()
