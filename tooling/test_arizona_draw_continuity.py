import copy
import json
from pathlib import Path
import unittest
from tooling.arizona_daily_lotto import parse_capture as daily
from tooling.arizona_megamillions import parse_capture as mega
from tooling.arizona_draw_continuity import select_latest


class ContinuityTests(unittest.TestCase):
    def setUp(self):
        root = Path(__file__).parent / 'fixtures/arizona'
        self.draws = {}
        for game, filename, parser in [
            ('fantasy-5', 'fantasy5-tables.json', lambda c: daily(c, 'fantasy-5')),
            ('triple-twist', 'triple-twist-tables.json', lambda c: daily(c, 'triple-twist')),
            ('mega-millions', 'mega-millions-tables.json', mega),
            ('the-pick', 'the-pick-tables.json', lambda c: daily(c, 'the-pick')),
        ]:
            self.draws[game] = parser(json.loads((root / filename).read_text()))

    def test_observed_latest_two_and_old_tail_removal(self):
        shorter = {g: rows[:-1] for g, rows in self.draws.items()}
        self.assertEqual(select_latest(shorter, self.draws),
                         {g: rows[:2] for g, rows in self.draws.items()})

    def test_each_group_rejects_correction_or_missing_overlap(self):
        for game in self.draws:
            for change in ('correction', 'missing', 'regression'):
                bad = copy.deepcopy(self.draws)
                if change == 'correction': bad[game][2]['numbers'] = [1, 2, 3, 4, 5]
                if change == 'missing': del bad[game][2]
                if change == 'regression': del bad[game][0]
                with self.subTest(game=game, change=change), self.assertRaises(ValueError):
                    select_latest(bad, self.draws)

    def test_missing_group_and_duplicate_dates_fail(self):
        bad = copy.deepcopy(self.draws)
        bad.pop('fantasy-5')
        with self.assertRaises(ValueError): select_latest(bad, self.draws)
        bad = copy.deepcopy(self.draws)
        bad['mega-millions'][1] = bad['mega-millions'][0]
        with self.assertRaises(ValueError): select_latest(bad, self.draws)

    def test_mislabeled_group_fails(self):
        bad = copy.deepcopy(self.draws)
        bad['fantasy-5'][0]['game'] = 'triple-twist'
        with self.assertRaises(ValueError): select_latest(bad, self.draws)
