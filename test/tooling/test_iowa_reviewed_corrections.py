import copy
import json
from pathlib import Path
import unittest
from tooling.collect_iowa_draws import check_continuity, REVIEWED_CORRECTIONS

class ReviewedCorrectionsTest(unittest.TestCase):
    def test_exact_forward_transitions_only(self):
        baseline = json.loads(Path('data/iowa_coverage.generated.json').read_text())['draws']
        for change in REVIEWED_CORRECTIONS:
            old = copy.deepcopy(baseline)
            i = next(i for i,r in enumerate(old['results']) if r['group'] == change['group'] and r['drawDate'] == change['drawDate'])
            old['results'][i] = copy.deepcopy(change['before'])
            new = copy.deepcopy(old)
            new['results'][i] = copy.deepcopy(change['after'])
            check_continuity(old, new)
            with self.assertRaises(ValueError): check_continuity(new, old)
            bad = copy.deepcopy(new)
            if bad['results'][i].get('report') is not None:
                bad['results'][i]['report']['tiers'][0]['sourceWinners'] += 1
            else: bad['results'][i]['numbers'][0] = 9
            with self.assertRaises(ValueError): check_continuity(old, bad)
