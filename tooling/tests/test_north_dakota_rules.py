from pathlib import Path
import unittest
from tooling.north_dakota_rules import parse_rules

ROOT = Path(__file__).parent / 'fixtures/north_dakota'
GAMES = ['powerball', 'mega-millions', 'millionaire-for-life', 'lotto-america', '2by2']


def walk(node):
    if isinstance(node, str):
        return
    yield node
    for child in node['children']:
        yield from walk(child)


class NorthDakotaRuleTests(unittest.TestCase):
    def source(self, game='powerball'):
        return (ROOT / (game + '-rules.html')).read_text()

    def test_five_retained_contracts_and_physical_rows(self):
        counts = [13, 13, 12, 13, 11]
        for game, count in zip(GAMES, counts):
            doc = parse_rules(self.source(game), game)['document']
            self.assertEqual(sum(n['tag'] == 'tr' for n in walk(doc)), count)

    def test_merged_cells_preserved(self):
        doc = parse_rules(self.source('2by2'), '2by2')['document']
        self.assertTrue(any(n['attrs'].get('rowspan') == '3' for n in walk(doc)))
        self.assertTrue(any(n['attrs'].get('rowspan') == '2' and n['children'] == ['Free Ticket'] for n in walk(doc)))

    def test_price_prize_and_conditions_changes_rejected(self):
        for game, old, new in [('powerball', '$50,000', '$60,000'),
                               ('2by2', '7 consecutive', '6 consecutive'),
                               ('millionaire-for-life', '20 year minimum', '10 year minimum'),
                               ('mega-millions', 'randomly assigned', 'always assigned')]:
            text = self.source(game)
            self.assertIn(old, text)
            with self.assertRaises(ValueError): parse_rules(text.replace(old, new), game)

    def test_span_and_link_changes_rejected(self):
        text = self.source('2by2')
        with self.assertRaises(ValueError): parse_rules(text.replace('rowspan="3"', 'rowspan="2"'), '2by2')
        text = self.source('mega-millions')
        self.assertIn('href=', text)
        with self.assertRaises(ValueError): parse_rules(text.replace('href="', 'href="https://wrong.invalid/'), 'mega-millions')

    def test_missing_duplicate_unbalanced_sections(self):
        text = self.source()
        for changed in ['', text + text, text.replace('</table>', '', 1), text.replace('colspan="8"', 'colspan="0"', 1)]:
            with self.assertRaises(ValueError): parse_rules(changed, 'powerball')

    def test_wrong_game_and_unknown_markup(self):
        with self.assertRaises(ValueError): parse_rules(self.source(), 'lucky-for-life')
        with self.assertRaises(ValueError): parse_rules(self.source(), 'mega-millions')
        with self.assertRaises(ValueError): parse_rules(self.source().replace('<h2>', '<script>'), 'powerball')

    def test_indentation_does_not_change_contract(self):
        text = self.source()
        self.assertEqual(parse_rules(text, 'powerball'), parse_rules(text.replace('\n', '\n  '), 'powerball'))
