import copy
import json
from pathlib import Path
import unittest
from tooling.arizona_two_to_win import parse_capture


class TwoToWinTests(unittest.TestCase):
    def setUp(self):
        self.capture = json.loads((Path(__file__).parent / 'fixtures/arizona/two-to-win-tables.json').read_text())

    def test_observed_results_keep_order_repeats_and_bonus(self):
        rows = parse_capture(self.capture)
        self.assertEqual(len(rows), 5)
        self.assertEqual([r['digits'] for r in rows[:2]], ['61', '99'])
        self.assertEqual([r['superBonus'] for r in rows[:2]], [1, 2])
        self.assertEqual(rows[0]['drawId'], '27646')
        self.assertTrue(all(r['reportStatus'] == 'unavailable' for r in rows))
        bad = copy.deepcopy(self.capture)
        bad['tables'][0]['rows'][1][2]['text'] = '0 1'
        self.assertEqual(parse_capture(bad)[0]['digits'], '01')

    def test_bad_cells_and_discontinuity_fail(self):
        for column, value in [(0,'27650'),(1,'9:20 AM'),(1,'8:45 AM'),(2,'61'),(2,'6 11'),(3,'6x'),(4,'Changed')]:
            bad = copy.deepcopy(self.capture)
            bad['tables'][0]['rows'][1][column]['text'] = value
            with self.subTest(column=column,value=value), self.assertRaises(ValueError): parse_capture(bad)

    def test_missing_pair_future_and_changed_detail_fail(self):
        for change in ('gap','future','detail','source'):
            bad = copy.deepcopy(self.capture)
            if change == 'gap': del bad['tables'][0]['rows'][3:5]
            if change == 'future': bad['selectedDate'] = '2026-11-03'
            if change == 'detail': bad['tables'][0]['rows'][2][0]['text'] = 'Changed'
            if change == 'source': bad['sourceUrl'] = 'https://www.arizonalottery.com/quick-draw/one-to-win/'
            with self.subTest(change=change), self.assertRaises(ValueError): parse_capture(bad)
