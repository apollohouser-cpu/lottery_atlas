from pathlib import Path
import unittest
from tooling.delaware_multiwin_rules import parse, SOURCE

RAW = (Path(__file__).parents[1] / 'fixtures/delaware/multiwin_rules.html').read_text()


class MultiWinRulesTest(unittest.TestCase):
    def test_preserves_distinct_six_match_rules(self):
        result = parse(RAW, source_url=SOURCE)
        line, combination = result['groups']
        self.assertEqual([len(g['tiers']) for g in result['groups']], [4, 6])
        self.assertEqual(line['tiers'][0], {'match': '6 numbers', 'prize': '$50,000 +'})
        self.assertEqual(combination['tiers'][4], {'match': '6 numbers', 'prize': '$3'})
        self.assertIn('any three lines', result['zeroMatchQualification'])
        self.assertNotIn('totalMoney', result)

    def test_changed_groups_and_qualifications_rejected(self):
        with self.assertRaises(ValueError):
            parse(RAW, source_url=SOURCE+'/other')
        for old, new in [('Delaware Lottery', 'Other'),
                         ('>Combination win<', '>Win in a line<'),
                         ('$50,000 +', '$50,000'),
                         ('any three lines', 'one line'),
                         ('are 1:5.7!', 'are unknown!'),
                         ('data-label="Win"', 'data-label="Payout"'),
                         ('<strong>10</strong>', '<strong>11</strong>')]:
            with self.subTest(old=old), self.assertRaises(ValueError):
                parse(RAW.replace(old, new, 1), source_url=SOURCE)
