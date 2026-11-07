from pathlib import Path
import unittest
from tooling.delaware_keno_rules import parse
RAW = (Path(__file__).parents[1]/'fixtures/delaware/keno_rules.html').read_text()
URL = 'https://www.delottery.com/Keno/Prizes-And-Odds'


class KenoRulesTest(unittest.TestCase):
    def test_spot_identity_and_qualified_limits(self):
        r = parse(RAW,source_url=URL)
        self.assertEqual(len(r['groups']),10)
        self.assertEqual(sum(len(g['tiers']) for g in r['groups']),37)
        self.assertEqual(r['groups'][0]['tiers'][-1],{'match':'0','prize':'$4'})
        self.assertEqual(r['groups'][1]['tiers'][-1],{'match':'0','prize':'$2'})
        self.assertEqual([x[0] for x in r['bonusRows'][:5]],['1x','3x','4x','5x','10x'])
        self.assertIn('$900,000',r['coverage'])

    def test_changed_limits_or_spots_fail_closed(self):
        with self.assertRaises(ValueError):parse(RAW,source_url=URL+'/wrong')
        for old,new in [('$900,000','$1,000,000'),('more than two','more than one'),('10 spot game','9 spot game'),('data-label="Prize"','data-label="Count"'),('1 in 240','1 in 200')]:
            with self.subTest(old=old), self.assertRaises(ValueError):
                parse(RAW.replace(old,new,1),source_url=URL)
