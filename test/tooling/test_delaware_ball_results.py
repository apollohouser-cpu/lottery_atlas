from pathlib import Path
from datetime import date
import unittest
from tooling.delaware_ball_results import parse

FIXTURES = Path(__file__).parents[1] / 'fixtures/delaware'


class BallResultsTest(unittest.TestCase):
    def parse(self, game, raw=None, **changes):
        args = dict(game=game, year=2026, month=11, observed_date=date(2026, 11, 6),
                    source_url=f'https://www.delottery.com/Winning-Numbers/Search-Winners/2026/11/{game}')
        args.update(changes)
        return parse(raw or (FIXTURES / f'{game}_november.html').read_text(), **args)

    def test_observed_variants(self):
        self.assertEqual(len(self.parse('MultiWin')['results']), 5)
        mm = self.parse('MegaMillions')['results']
        self.assertEqual(len(mm), 1)
        self.assertEqual(mm[0]['specialBall'], 3)
        self.assertNotIn('allStarBonus', mm[0])
        la = self.parse('LottoAmerica')['results']
        self.assertEqual([r['allStarBonus'] for r in la], [3, 4])

    def test_source_and_title_rejected(self):
        with self.assertRaises(ValueError):
            self.parse('MultiWin', source_url='https://example.com/')
        with self.assertRaises(ValueError):
            self.parse('MultiWin', raw=(FIXTURES / 'MegaMillions_november.html').read_text())

    def test_ball_semantics_rejected(self):
        for game, old, new in [('MultiWin', '>35</li>', '>36</li>'),
                              ('MultiWin', '>35</li>', '>05</li>'),
                              ('MegaMillions', 'ball-color-yellow-orange', 'ball-color-blue'),
                              ('MegaMillions', '>03</li>', '>25</li>'),
                              ('LottoAmerica', '>3X</strong>', '>10X</strong>'),
                              ('LottoAmerica', '11/02/26', '11/04/26'),
                              ('MultiWin', '11/05/26', '12/05/26')]:
            raw = (FIXTURES / f'{game}_november.html').read_text()
            with self.subTest(game=game, old=old), self.assertRaises(ValueError):
                self.parse(game, raw.replace(old, new, 1))


if __name__ == '__main__':
    unittest.main()
