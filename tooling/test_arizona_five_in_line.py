import copy
import json
from pathlib import Path
import unittest
from tooling.arizona_two_to_win import parse_capture


class FiveInLineTests(unittest.TestCase):
    def setUp(self):
        self.capture = json.loads((Path(__file__).parent / 'fixtures/arizona/five-in-line-tables.json').read_text())

    def test_observed_order_repeats_and_bonus(self):
        rows = parse_capture(self.capture, '5-in-a-line')
        self.assertEqual(len(rows), 6)
        self.assertEqual([r['digits'] for r in rows[:3]], ['64972', '85271', '15800'])
        self.assertEqual(rows[4]['superBonus'], 5)
        self.assertEqual(rows[0]['drawId'], '33027')
        self.assertTrue(all(r['reportStatus'] == 'unavailable' for r in rows))
        self.capture['tables'][0]['rows'][1][2]['text'] = '0 0 1 1 2'
        self.assertEqual(parse_capture(self.capture, '5-in-a-line')[0]['digits'], '00112')

    def test_wrong_contract_width_time_and_detail_fail(self):
        with self.assertRaises(ValueError): parse_capture(self.capture)
        for index, column, value in [(1,2,'6 1'),(1,1,'9:20 AM'),(2,0,'Changed'),(1,3,'6x'),(1,0,'33029')]:
            bad = copy.deepcopy(self.capture)
            bad['tables'][0]['rows'][index][column]['text'] = value
            with self.subTest(value=value), self.assertRaises(ValueError): parse_capture(bad, '5-in-a-line')

    def test_missing_hour_and_future_date_fail(self):
        bad = copy.deepcopy(self.capture)
        del bad['tables'][0]['rows'][3:5]
        with self.assertRaises(ValueError): parse_capture(bad, '5-in-a-line')
        bad = copy.deepcopy(self.capture)
        bad['selectedDate'] = '2026-11-03'
        with self.assertRaises(ValueError): parse_capture(bad, '5-in-a-line')
