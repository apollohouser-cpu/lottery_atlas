import copy
import json
from pathlib import Path
import unittest
from tooling.delaware_instant_tiers import compose_exclusions


class ExclusionTest(unittest.TestCase):
    def setUp(self):
        self.exclusions = json.loads(Path('tooling/delaware_instant_exclusions.json').read_text())
        self.images = [dict(gameId=e['gameId'], sourceUrl=e['sourceUrl'], sha256=e['sourceSha256'],
                            retrievedAt='2026-11-07T13:02:00+00:00') for e in self.exclusions]

    def test_complete_disclosures_preserve_source_dates(self):
        result = compose_exclusions(self.images, [], self.exclusions)
        self.assertEqual(len(result), 6)
        self.assertTrue(all(e['status'] == 'excluded' and e['reason'] for e in result))
        self.assertTrue(all(e['sourceRetrievedAt'] == self.images[0]['retrievedAt'] for e in result))

    def test_omitted_duplicate_changed_or_unexplained_exclusion_fails(self):
        cases = [self.exclusions[:-1], self.exclusions + [self.exclusions[0]]]
        for key, value in [('reason', ''), ('sourceSha256', 'changed'), ('sourceUrl', 'changed')]:
            changed = copy.deepcopy(self.exclusions)
            changed[0][key] = value
            cases.append(changed)
        for case in cases:
            with self.assertRaises(ValueError): compose_exclusions(self.images, [], case)

    def test_excluded_game_cannot_also_be_reviewed(self):
        with self.assertRaises(ValueError):
            compose_exclusions(self.images, [{'gameId': self.images[0]['gameId']}], self.exclusions)
