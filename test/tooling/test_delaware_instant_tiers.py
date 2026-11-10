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
        self.assertEqual([len(t['tiers']) for t in tables], [11, 14, 31, 23, 30, 31, 26, 31, 34, 36, 23, 41, 36, 31, 22, 30, 18, 24, 30, 31, 22, 28, 37, 28, 42])
        self.assertEqual(tables[1]['tiers'][0]['oddsOneIn'], '12.50')
        self.assertEqual(tables[2]['tiers'][-1]['oddsOneIn'], '78,000')
        self.assertEqual(tables[2]['printedPrizeTotal'], 95975)
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

    def test_crossword_columns_preserve_game_identity(self):
        table = next(t for t in compose(self.images) if t['gameId'] == '467')
        self.assertEqual(table['tiers'][0]['game2'], '')
        self.assertEqual(table['tiers'][1]['game2'], '3 WORDS')
        spec = copy.deepcopy(self.spec)
        row = next(t for t in spec['tables'] if t['gameId'] == '467')['tiers'][0]
        row['game1'], row['game2'] = row['game2'], row['game1']
        with self.assertRaises(ValueError): compose(self.images, spec)

    def test_main_bonus_columns_cannot_be_swapped(self):
        table = next(t for t in compose(self.images) if t['gameId'] == '522')
        self.assertEqual(table['tiers'][1]['mainPrize'], '')
        self.assertEqual(table['tiers'][1]['bonusPrize'], '$50')
        spec = copy.deepcopy(self.spec)
        row = next(t for t in spec['tables'] if t['gameId'] == '522')['tiers'][1]
        row['mainPrize'], row['bonusPrize'] = row['bonusPrize'], row['mainPrize']
        with self.assertRaises(ValueError): compose(self.images, spec)

    def test_bad_values_omissions_or_duplicates_fail(self):
        for key, value in [('win', 51), ('printedWinners', True),
                           ('printedPrizeValue', 1), ('oddsOneIn', 'NaN'),
                           ('oddsOneIn', '7,80,00'), ('oddsOneIn', '1e3'),
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
