from pathlib import Path
import unittest
from tooling.delaware_xsos_rules import parse, SOURCE

RAW = (Path(__file__).parents[1] / 'fixtures/delaware/xsos_rules.html').read_text()


class XsOsRulesTest(unittest.TestCase):
    def test_literal_qualified_schedule(self):
        result = parse(RAW, source_url=SOURCE)
        self.assertEqual(len(result['tiers']), 5)
        self.assertEqual(result['tiers'][0], {'match': 'Match 8', 'prize': 'Jackpot', 'odds': '1:10,518,300'})
        self.assertEqual(result['tiers'][1]['prize'], '$20,000')
        self.assertIn('Lower-tier prizes may become pari-mutuel', result['qualification'])
        self.assertIn('1:12.16', result['overallOddsText'])

    def test_missing_or_changed_qualifications_fail_closed(self):
        with self.assertRaises(ValueError):
            parse(RAW, source_url=SOURCE+'/other')
        for old, new in [('Delaware Lottery', 'Other Lottery'),
                         ('>Match 8<', '>Match 7<'),
                         ('data-label="Prize"', 'data-label="Payout"'),
                         ('1:54,783', 'unknown'),
                         ('Lower-tier prizes may', 'Lower-tier prizes never'),
                         ('Overall odds of winning', 'Other odds'),
                         ('Jackpot', '$0')]:
            with self.subTest(old=old), self.assertRaises(ValueError):
                parse(RAW.replace(old, new, 1), source_url=SOURCE)
