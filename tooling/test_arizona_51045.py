import copy
import json
from pathlib import Path
import unittest
from tooling.arizona_51045 import parse_capture


class FiveTenFortyFiveTests(unittest.TestCase):
    def setUp(self):
        self.capture = json.loads((Path(__file__).parent / 'fixtures/arizona/51045-tables.json').read_text())

    def test_observed_results_and_bullseye(self):
        rows = parse_capture(self.capture)
        self.assertEqual(len(rows), 9)
        self.assertEqual(rows[0]['drawId'], '36264')
        self.assertEqual(rows[0]['numbers'], [3,6,11,13,14,16,18,19,33,34])
        self.assertEqual(rows[0]['bullseye'], 3)
        self.assertEqual(rows[1]['superBonus'], 5)
        self.assertTrue(all(r['reportStatus'] == 'unavailable' for r in rows))

    def test_range_duplicates_bullseye_and_schedule_reject(self):
        for col, value in [(2,'03 03 11 13 14 16 18 19 33 34'),(2,'03 06 11 13 14 16 18 19 33 46'),(2,'03 06'),(3,'45'),(4,'7x'),(1,'12:20 PM'),(0,'36265')]:
            bad = copy.deepcopy(self.capture)
            bad['tables'][0]['rows'][1][col]['text'] = value
            with self.subTest(value=value), self.assertRaises(ValueError): parse_capture(bad)

    def test_bonus_multiple_digits_preserved(self):
        for bonus in (10,12,20):
            changed = copy.deepcopy(self.capture)
            changed['tables'][0]['rows'][1][4]['text'] = f'{bonus}x'
            self.assertEqual(parse_capture(changed)[0]['superBonus'], bonus)

    def test_source_detail_gap_future_reject(self):
        for mutation in ('source','detail','gap','future'):
            bad = copy.deepcopy(self.capture)
            if mutation == 'source': bad['sourceUrl'] += 'other'
            if mutation == 'detail': bad['tables'][0]['rows'][2][0]['text'] = 'Changed'
            if mutation == 'gap': del bad['tables'][0]['rows'][3:5]
            if mutation == 'future': bad['retrievedAt'] = '2026-11-02T12:00:00Z'
            with self.subTest(mutation=mutation), self.assertRaises(ValueError): parse_capture(bad)
