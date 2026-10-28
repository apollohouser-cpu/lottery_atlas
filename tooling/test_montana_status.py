import gzip
import unittest
from pathlib import Path
from tooling.montana_status import parse_status

FIXTURES = Path(__file__).with_name('fixtures') / 'montana'

class StatusTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.games = gzip.decompress((FIXTURES / 'games.html.gz').read_bytes()).decode()
        cls.mfl = (FIXTURES / 'millionaire-for-life-rules.html').read_text()

    def test_current_and_retired_boundaries(self):
        result = parse_status(self.games, self.mfl)
        self.assertEqual(len(result['regularFamilies']), 6)
        self.assertEqual(result['inventoryStatus'], 'unavailable')
        self.assertEqual(result['retiredGames'][0]['game'], 'lucky-for-life')
        result['regularFamilies'].clear()
        self.assertEqual(len(parse_status(self.games, self.mfl)['regularFamilies']), 6)

    def test_new_or_replaced_product_requires_scope_review(self):
        html = self.games.replace('https://montanalottery.com/powerball/', 'https://montanalottery.com/new-game/')
        with self.assertRaises(ValueError):
            parse_status(html, self.mfl)

    def test_missing_navigation_and_wrong_identity(self):
        for html in [self.games.replace('id="games"', 'id="absent"'), self.games.replace('Games - Montana Lottery', 'Wrong identity')]:
            with self.assertRaises(ValueError):
                parse_status(html, self.mfl)

    def test_retired_source_contract_required(self):
        with self.assertRaises(ValueError):
            parse_status(self.games, '')

if __name__ == '__main__':
    unittest.main()
