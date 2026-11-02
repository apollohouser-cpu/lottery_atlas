import copy
import json
from pathlib import Path
import unittest
from tooling.arizona_two_to_win import parse_capture


class MoneyRollTests(unittest.TestCase):
    def setUp(self):
        self.capture = json.loads((Path(__file__).parent / 'fixtures/arizona/money-roll-tables.json').read_text())

    def test_literal_ordered_dice_and_repeats(self):
        rows = parse_capture(self.capture, 'money-roll')
        self.assertEqual(len(rows), 6)
        self.assertEqual(rows[0]['diceLabels'], ['ONE', 'FIVE', 'FOUR', 'TWO', 'THREE'])
        self.assertEqual(rows[1]['diceLabels'], ['THREE', 'THREE', 'FOUR', 'SIX', 'THREE'])
        self.assertEqual(rows[0]['drawId'], '27652')
        self.assertEqual(rows[0]['superBonus'], 3)
        self.assertNotIn('digits', rows[0])
        self.assertTrue(all(r['reportStatus'] == 'unavailable' for r in rows))

    def test_invalid_dice_and_time_reject(self):
        for col, value in [(2,'ONE\nTWO\nTHREE\nFOUR\nSEVEN'),(2,'1 2 3 4 5'),(2,'ONE\nTWO'),(1,'9:30 AM'),(0,'27655'),(3,'6x')]:
            bad = copy.deepcopy(self.capture)
            bad['tables'][0]['rows'][1][col]['text'] = value
            with self.subTest(value=value), self.assertRaises(ValueError): parse_capture(bad, 'money-roll')

    def test_wrong_source_detail_and_missing_hour_reject(self):
        with self.assertRaises(ValueError): parse_capture(self.capture, '5-in-a-line')
        bad = copy.deepcopy(self.capture)
        bad['tables'][0]['rows'][2][0]['text'] = 'Changed'
        with self.assertRaises(ValueError): parse_capture(bad, 'money-roll')
        bad = copy.deepcopy(self.capture)
        del bad['tables'][0]['rows'][3:5]
        with self.assertRaises(ValueError): parse_capture(bad, 'money-roll')
