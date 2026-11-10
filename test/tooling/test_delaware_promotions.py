import unittest
from tooling.delaware_promotions import ComingSoon


class ComingSoonTests(unittest.TestCase):
    def card(self, name='Example', price='1'):
        return f'<div data-gamenumber="532" data-gamename="{name}" data-amount="{price}" data-topprize="2,000" data-gamedescription="Match symbols."></div>'

    def test_navigation_excluded_and_shared_designs_count_once(self):
        parser = ComingSoon()
        parser.feed(self.card('Navigation') + '<section class="coming-soon-game">' + self.card()*2 + '</section>' + self.card('Footer'))
        self.assertEqual(len(parser.games), 1)
        self.assertEqual(parser.games['532']['name'], 'Example')
        self.assertNotIn('remaining', parser.games['532'])

    def test_conflicting_design_and_invalid_price_fail(self):
        for extra in (self.card('Conflict'), self.card(price='0')):
            parser = ComingSoon()
            with self.assertRaises(ValueError):
                parser.feed('<section class="coming-soon-game">' + self.card() + extra)
