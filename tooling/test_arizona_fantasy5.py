import copy
import json
from pathlib import Path
import unittest
from tooling.arizona_fantasy5 import parse_capture


class Fantasy5Tests(unittest.TestCase):
    def setUp(self):
        self.capture = json.loads((Path(__file__).parent / 'fixtures/arizona/fantasy5-tables.json').read_text())

    def test_observed_date_only_results(self):
        results = parse_capture(self.capture)
        self.assertEqual(len(results), 179)
        self.assertEqual(results[0]['numbers'], [5, 14, 18, 32, 40])
        self.assertEqual(results[1]['drawDate'], '2026-10-30')
        self.assertTrue(all(r['reportStatus'] == 'unavailable' and 'winnerCount' not in r for r in results))

    def test_invalid_values_fail_closed(self):
        for column, value in [(0, ''), (0, '12/31/2026'), (0, '10/30/2026'),
                              (1, ''), (1, '1 2 3 4 42'), (1, '1 1 3 4 5')]:
            bad = copy.deepcopy(self.capture)
            bad['tables'][0]['rows'][1][column]['text'] = value
            with self.subTest(value=value), self.assertRaises(ValueError):
                parse_capture(bad)

    def test_missing_day_rejected(self):
        del self.capture['tables'][0]['rows'][3:5]
        with self.assertRaises(ValueError): parse_capture(self.capture)

    def test_source_and_structure_rejected(self):
        for kind in ('source', 'timezone', 'header', 'footer', 'table'):
            bad = copy.deepcopy(self.capture)
            if kind == 'source': bad['sourceUrl'] = 'https://example.com/'
            if kind == 'timezone': bad['retrievedAt'] = '2026-11-02T02:00:00'
            if kind == 'header': bad['tables'][0]['rows'][0][0]['text'] = 'Date'
            if kind == 'footer': bad['tables'][0]['rows'].pop()
            if kind == 'table': bad['tables'].append(bad['tables'][0])
            with self.subTest(kind=kind), self.assertRaises(ValueError): parse_capture(bad)
