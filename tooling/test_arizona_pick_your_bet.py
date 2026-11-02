import copy
import json
from pathlib import Path
import unittest
from tooling.arizona_pick_your_bet import parse_capture


class PickYourBetTests(unittest.TestCase):
    def setUp(self):
        self.capture = json.loads((Path(__file__).parent / 'fixtures/arizona/pick-your-bet-tables.json').read_text())

    def test_literal_number_and_categories(self):
        rows = parse_capture(self.capture)
        self.assertEqual(len(rows), 8)
        self.assertEqual(rows[0]['drawId'], '21069')
        self.assertEqual(rows[0]['winningNumber'], '35')
        self.assertEqual(rows[0]['parity'], 'Odd')
        self.assertEqual(rows[0]['band'], 'High')
        self.assertEqual(rows[4]['winningNumber'], '07')
        self.assertEqual(rows[0]['superBonus'], 2)
        self.assertTrue(all(r['reportStatus'] == 'unavailable' for r in rows))
        self.assertNotIn('winnerCount', rows[0])

    def test_categories_range_and_schedule_reject(self):
        for col, value in [(2,'35 - Even - High'),(2,'35 - Odd - Low'),(2,'39 - Odd - High'),(2,'00 - Even - Low'),(2,'7 - Odd - Low'),(1,'11:30 AM'),(0,'21070'),(3,'6x')]:
            bad = copy.deepcopy(self.capture)
            bad['tables'][0]['rows'][1][col]['text'] = value
            with self.subTest(value=value), self.assertRaises(ValueError): parse_capture(bad)

    def test_source_detail_gap_and_future_reject(self):
        for mutation in ('source','detail','gap','future'):
            bad = copy.deepcopy(self.capture)
            if mutation == 'source': bad['sourceUrl'] += 'other'
            if mutation == 'detail': bad['tables'][0]['rows'][2][0]['text'] = 'Changed'
            if mutation == 'gap': del bad['tables'][0]['rows'][3:5]
            if mutation == 'future': bad['retrievedAt'] = '2026-11-02T12:00:00Z'
            with self.subTest(mutation=mutation), self.assertRaises(ValueError): parse_capture(bad)
