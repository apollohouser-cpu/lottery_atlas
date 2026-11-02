import copy
import json
from pathlib import Path
import unittest
from tooling.arizona_one_to_win import parse_capture


class OneToWinTests(unittest.TestCase):
    def setUp(self):
        self.capture = json.loads((Path(__file__).parent / 'fixtures/arizona/one-to-win-tables.json').read_text())

    def test_observed_hourly_results_no_ticket_counts(self):
        rows = parse_capture(self.capture)
        self.assertEqual([r['drawId'] for r in rows], ['36268', '36267', '36266'])
        self.assertEqual([r['number'] for r in rows], [6, 14, 12])
        self.assertEqual(rows[0]['drawTime'], '6:45 AM')
        self.assertEqual(rows[0]['basePrizeAmount'], '$7')
        self.assertTrue(all(r['reportStatus'] == 'unavailable' for r in rows))
        self.assertNotIn('winnerCount', rows[0])

    def test_changed_cells_reject(self):
        for column, value in [(0,'36270'),(1,'8:45 AM'),(1,'6:30 AM'),(2,'$8'),(3,'16'),(4,'unknown')]:
            bad = copy.deepcopy(self.capture)
            bad['tables'][0]['rows'][1][column]['text'] = value
            with self.subTest(column=column,value=value), self.assertRaises(ValueError): parse_capture(bad)

    def test_future_date_missing_row_and_wrong_source_reject(self):
        for change in ('date','gap','source','timezone'):
            bad = copy.deepcopy(self.capture)
            if change == 'date': bad['selectedDate'] = '2026-11-03'
            if change == 'gap': del bad['tables'][0]['rows'][2]
            if change == 'source': bad['sourceUrl'] += 'changed/'
            if change == 'timezone': bad['retrievedAt'] = '2026-11-02T14:00:00'
            with self.subTest(change=change), self.assertRaises(ValueError): parse_capture(bad)
