import copy
import json
from pathlib import Path
import unittest
from tooling.arizona_lucky_links import parse_capture


class LuckyLinksTests(unittest.TestCase):
    def setUp(self):
        self.capture = json.loads((Path(__file__).parent / 'fixtures/arizona/lucky-links-tables.json').read_text())

    def test_observed_numbers_without_ticket_positions(self):
        rows = parse_capture(self.capture)
        self.assertEqual(len(rows), 9)
        self.assertEqual(rows[0]['drawId'], '31404')
        self.assertEqual(rows[0]['numbers'], [3,6,10,12,13,14,17,20])
        self.assertEqual(rows[0]['superBonus'], 2)
        self.assertEqual(rows[-1]['drawTime'], '5:00 AM')
        self.assertNotIn('grid', rows[0])
        self.assertTrue(all(r['reportStatus'] == 'unavailable' for r in rows))

    def test_range_duplicates_and_schedule_reject(self):
        for col, value in [(2,'03 03 10 12 13 14 17 20'),(2,'03 06 10 12 13 14 17 23'),(2,'03 06'),(3,'6x'),(1,'1:15 PM'),(0,'31405')]:
            bad = copy.deepcopy(self.capture)
            bad['tables'][0]['rows'][1][col]['text'] = value
            with self.subTest(value=value), self.assertRaises(ValueError): parse_capture(bad)
        bad = copy.deepcopy(self.capture)
        bad['tables'][0]['rows'][-3][1]['text'] = '4:00 AM'
        with self.assertRaises(ValueError): parse_capture(bad)

    def test_source_detail_gap_and_future_reject(self):
        for mutation in ('source','detail','gap','future'):
            bad = copy.deepcopy(self.capture)
            if mutation == 'source': bad['sourceUrl'] += 'other'
            if mutation == 'detail': bad['tables'][0]['rows'][2][0]['text'] = 'Changed'
            if mutation == 'gap': del bad['tables'][0]['rows'][3:5]
            if mutation == 'future': bad['retrievedAt'] = '2026-11-02T12:00:00Z'
            with self.subTest(mutation=mutation), self.assertRaises(ValueError): parse_capture(bad)
