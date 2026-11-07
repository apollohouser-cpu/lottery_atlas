from pathlib import Path
import unittest
from tooling.delaware_megamillions_rules import parse
RAW = (Path(__file__).parents[1]/'fixtures/delaware/megamillions_rules.html').read_text()
URL = 'https://www.delottery.com/Drawing-Games/Mega-Millions/Prizes-And-Odds'


class MegaRulesTest(unittest.TestCase):
    def test_literal_columns_and_per_board_multiplier(self):
        r = parse(RAW, source_url=URL)
        self.assertEqual(len(r['tiers']), 9)
        self.assertEqual(r['tiers'][1]['sourceAveragePrize'], '$1,000,000')
        self.assertEqual(r['tiers'][1]['prizeRange'], '$2,000,000 - $10,000,000')
        self.assertIn('per board', r['multiplierAssignment'])
        self.assertIn('pari-mutuel', r['qualification'])

    def test_semantic_changes_rejected(self):
        with self.assertRaises(ValueError):
            parse(RAW, source_url=URL+'/wrong')
        for old,new in [('per board','per drawing'),('pari-mutuel','fixed'),('$1,000,000','$9,000,000'),('AVERAGE PRIZE','PAYOUT'),('April 05, 2025','April 05, 2026')]:
            with self.subTest(old=old), self.assertRaises(ValueError):
                parse(RAW.replace(old,new,1),source_url=URL)
