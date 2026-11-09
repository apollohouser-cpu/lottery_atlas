import copy
import json
from pathlib import Path
import unittest

from tooling.delaware_instant_tiers import compose


class ReviewedTierTest(unittest.TestCase):
    def setUp(self):
        self.spec = json.loads(Path('tooling/delaware_reviewed_instant_tiers.json').read_text())
        self.images = [{'gameId': t['gameId'], 'sourceUrl': t['sourceUrl'],
                        'sha256': t['sourceSha256'], 'names': ['Catalog title'],
                        'retrievedAt': '2026-11-07T13:02:00+00:00'} for t in self.spec['tables']]

    def test_reviewed_tables_preserve_literal_odds_and_run_meaning(self):
        tables = compose(self.images)
        self.assertEqual([len(t['tiers']) for t in tables], [11, 14])
        self.assertEqual(tables[1]['tiers'][0]['oddsOneIn'], '12.50')
        for table in tables:
            self.assertFalse(table['actualClaimsAvailable'])
            self.assertFalse(table['remainingInventoryAvailable'])
            self.assertEqual(table['sourceRetrievedAt'], self.images[0]['retrievedAt'])

    def test_source_changes_or_missing_identity_fail(self):
        for key, value in [('sha256', 'bad'), ('sourceUrl', 'bad')]:
            images = copy.deepcopy(self.images)
            images[0][key] = value
            with self.assertRaises(ValueError): compose(images)
        with self.assertRaises(ValueError): compose(self.images[1:])

    def test_bad_values_omissions_or_duplicates_fail(self):
        for key, value in [('win', 51), ('printedWinners', True),
                           ('printedPrizeValue', 1), ('oddsOneIn', 'NaN'),
                           ('oddsOneIn', '0'), ('combination', '')]:
            spec = copy.deepcopy(self.spec)
            spec['tables'][0]['tiers'][0][key] = value
            with self.subTest(key=key, value=value), self.assertRaises(ValueError):
                compose(self.images, spec)
        for action in ('omit', 'duplicate', 'summary'):
            spec = copy.deepcopy(self.spec)
            if action == 'omit': spec['tables'][0]['tiers'].pop()
            if action == 'duplicate': spec['tables'][0]['tiers'].append(spec['tables'][0]['tiers'][0])
            if action == 'summary': spec['tables'][0]['printedPrizeTotal'] += 1
            with self.assertRaises(ValueError): compose(self.images, spec)
