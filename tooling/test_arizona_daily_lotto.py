import copy
import json
from pathlib import Path
import unittest
from tooling.arizona_daily_lotto import parse_capture


class DailyLottoTests(unittest.TestCase):
    def setUp(self):
        self.capture = json.loads((Path(__file__).parent / 'fixtures/arizona/triple-twist-tables.json').read_text())

    def test_triple_twist_single_draw_not_three_ticket_rows(self):
        result = parse_capture(self.capture, 'triple-twist')
        self.assertEqual(len(result), 180)
        self.assertEqual(result[0]['drawDate'], '2026-11-01')
        self.assertEqual(result[0]['numbers'], [11, 21, 26, 28, 41, 42])
        self.assertTrue(all(r['reportStatus'] == 'unavailable' for r in result))
        self.assertNotIn('winnerCount', result[0])

    def test_game_contract_cannot_be_swapped(self):
        for game in ('fantasy-5', 'unknown'):
            with self.assertRaises(ValueError): parse_capture(self.capture, game)

    def test_exact_six_distinct_numbers_in_range(self):
        for value in ('1 2 3 4 5', '1 2 3 4 5 43', '1 2 3 4 5 5', ''):
            bad = copy.deepcopy(self.capture)
            bad['tables'][0]['rows'][1][1]['text'] = value
            with self.subTest(value=value), self.assertRaises(ValueError):
                parse_capture(bad, 'triple-twist')

    def test_missing_daily_result_fails(self):
        del self.capture['tables'][0]['rows'][3:5]
        with self.assertRaises(ValueError): parse_capture(self.capture, 'triple-twist')
