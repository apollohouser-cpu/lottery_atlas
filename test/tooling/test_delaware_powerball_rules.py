from pathlib import Path
import unittest
from tooling.delaware_powerball_rules import parse
RAW = (Path(__file__).parents[1]/'fixtures/delaware/powerball_rules.html').read_text()
URL = 'https://www.delottery.com/Drawing-Games/Powerball/Prizes-And-Odds'


class PowerballRulesTest(unittest.TestCase):
    def test_separate_prizes_and_fixed_match5_multiplier(self):
        r = parse(RAW, source_url=URL)
        base, double = r['groups']
        self.assertEqual([len(g['tiers']) for g in r['groups']], [9,9])
        self.assertEqual(set(base['tiers'][1]['powerPlayPrizes'].values()), {'$2,000,000'})
        self.assertNotIn('powerPlayPrizes', double['tiers'][1])
        self.assertEqual(double['tiers'][1]['prize'], '$500,000')
        self.assertIn('conflict', r['coverage'])
        self.assertTrue(any('$150 million' in p for p in r['qualifications']))

    def test_changed_qualifications_rejected(self):
        with self.assertRaises(ValueError):parse(RAW,source_url=URL+'/wrong')
        for old,new in [('$150 million','$200 million'),('not eligible','eligible'),('divided equally','paid in full'),('$500,000','$600,000')]:
            with self.subTest(old=old), self.assertRaises(ValueError):
                parse(RAW.replace(old,new,1),source_url=URL)
