import copy
import json
from pathlib import Path
import unittest
from tooling.arizona_megamillions import parse_capture


class MegaMillionsTests(unittest.TestCase):
    def setUp(self):
        self.capture = json.loads((Path(__file__).parent / 'fixtures/arizona/mega-millions-tables.json').read_text())

    def test_observed_results_no_global_multiplier_or_counts(self):
        result = parse_capture(self.capture)
        self.assertEqual(len(result), 51)
        self.assertEqual(result[0]['numbers'], [5, 10, 38, 49, 68])
        self.assertEqual(result[0]['megaBall'], 17)
        for row in result:
            self.assertEqual(row['reportStatus'], 'unavailable')
            self.assertNotIn('multiplier', row)
            self.assertNotIn('winnerCount', row)

    def test_invalid_dates_numbers_and_old_mega_ball_range(self):
        for col, value in [(0, ''), (0, '10/29/2026'), (0, '12/31/2026'),
                           (1, '1 2 3 4 71'), (1, '1 1 3 4 5'), (2, '25'), (2, '')]:
            bad = copy.deepcopy(self.capture)
            bad['tables'][0]['rows'][1][col]['text'] = value
            with self.subTest(value=value), self.assertRaises(ValueError): parse_capture(bad)

    def test_missing_scheduled_draw_rejected(self):
        del self.capture['tables'][0]['rows'][3:5]
        with self.assertRaises(ValueError): parse_capture(self.capture)

    def test_wrong_source_and_changed_headers_rejected(self):
        for kind in ('source', 'header'):
            bad = copy.deepcopy(self.capture)
            if kind == 'source': bad['sourceUrl'] = 'https://www.arizonalottery.com/draw-games/powerball/'
            else: bad['tables'][0]['rows'][0][2]['text'] = 'Powerball'
            with self.assertRaises(ValueError): parse_capture(bad)
