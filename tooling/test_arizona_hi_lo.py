import copy
import json
from pathlib import Path
import unittest
from tooling.arizona_hi_lo import parse_capture


class HiLoTests(unittest.TestCase):
    def setUp(self):
        self.capture = json.loads((Path(__file__).parent / 'fixtures/arizona/hi-lo-tables.json').read_text())

    def test_observed_category_totals_not_numbers_or_winners(self):
        rows = parse_capture(self.capture)
        self.assertEqual(len(rows), 11)
        self.assertEqual(rows[0]['drawId'], '21082')
        self.assertEqual(rows[0]['highNumberTotal'], 9)
        self.assertEqual(rows[0]['lowNumberTotal'], 11)
        self.assertEqual(rows[0]['superBonus'], 1)
        self.assertNotIn('numbers', rows[0])
        self.assertNotIn('winnerCount', rows[0])
        self.assertTrue(all(r['reportStatus'] == 'unavailable' for r in rows))

    def test_invalid_totals_and_schedule_reject(self):
        for col, value in [(2,'Hi - 9 | Lo - 10'),(2,'Hi - 21 | Lo - 0'),(2,'Hi - -1 | Lo - 21'),(2,'Lo - 9 | Hi - 11'),(3,'6x'),(1,'2:15 PM'),(0,'21083')]:
            bad = copy.deepcopy(self.capture)
            bad['tables'][0]['rows'][1][col]['text'] = value
            with self.subTest(value=value), self.assertRaises(ValueError): parse_capture(bad)

    def test_valid_extremes_preserve_labels(self):
        for high, low in [(0,20),(20,0),(4,16),(16,4)]:
            changed = copy.deepcopy(self.capture)
            changed['tables'][0]['rows'][1][2]['text'] = f'Hi - {high} | Lo - {low}'
            self.assertEqual(parse_capture(changed)[0]['highNumberTotal'], high)

    def test_source_detail_gap_and_future_reject(self):
        for mutation in ('source','detail','gap','future','footer'):
            bad = copy.deepcopy(self.capture)
            if mutation == 'source': bad['sourceUrl'] += 'other'
            if mutation == 'detail': bad['tables'][0]['rows'][2][0]['text'] = 'Changed'
            if mutation == 'gap': del bad['tables'][0]['rows'][3:5]
            if mutation == 'future': bad['retrievedAt'] = '2026-11-02T12:00:00Z'
            if mutation == 'footer': bad['tables'][0]['rows'][-1][0]['text'] = 'Changed'
            with self.subTest(mutation=mutation), self.assertRaises(ValueError): parse_capture(bad)
