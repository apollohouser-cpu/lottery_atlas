import copy
import json
from pathlib import Path
import unittest

from tooling.arizona_powerball import parse_capture


class PowerballCaptureTests(unittest.TestCase):
    def setUp(self):
        self.capture = json.loads((Path(__file__).parent / 'fixtures/arizona/powerball-tables.json').read_text())

    def test_observed_tables_remain_separate_and_date_only(self):
        result = parse_capture(self.capture)
        self.assertEqual([len(result[k]) for k in result], [77, 60])
        self.assertEqual(result['powerball'][0]['numbers'], [2, 4, 18, 50, 56])
        self.assertEqual(result['powerball-double-play'][0]['numbers'], [16, 52, 55, 58, 67])
        for draws in result.values():
            self.assertTrue(all(d['reportStatus'] == 'unavailable' for d in draws))
            self.assertTrue(all('drawTime' not in d and 'winnerCount' not in d for d in draws))

    def test_table_order_does_not_define_identity(self):
        before = parse_capture(self.capture)
        self.capture['tables'].reverse()
        self.assertEqual(parse_capture(self.capture), before)

    def test_rejects_invalid_results_and_templates(self):
        for column, value in [(0, ''), (0, '11/30/2026'), (0, '10/30/2026'),
                              (1, '2 2 18 50 56'), (1, '2 4 18 50 70'),
                              (2, '27'), (3, '6')]:
            with self.subTest(column=column, value=value):
                bad = copy.deepcopy(self.capture)
                bad['tables'][0]['rows'][1][column]['text'] = value
                with self.assertRaises(ValueError):
                    parse_capture(bad)

    def test_rejects_missing_duplicate_and_changed_tables(self):
        for change in ('missing', 'duplicate', 'header', 'footer', 'duplicate_date'):
            bad = copy.deepcopy(self.capture)
            if change == 'missing': bad['tables'].pop()
            if change == 'duplicate': bad['tables'][1] = bad['tables'][0]
            if change == 'header': bad['tables'][0]['rows'][0][0]['text'] = 'Date'
            if change == 'footer': bad['tables'][0]['rows'].pop()
            if change == 'duplicate_date': bad['tables'][0]['rows'][3][0]['text'] = '10/31/2026'
            with self.subTest(change=change), self.assertRaises(ValueError):
                parse_capture(bad)

    def test_provenance_required(self):
        for key, value in [('sourceUrl', 'https://example.com/'),
                           ('captureKind', 'http'), ('retrievedAt', '2026-11-01T19:00:00')]:
            bad = copy.deepcopy(self.capture)
            bad[key] = value
            with self.assertRaises(ValueError):
                parse_capture(bad)


if __name__ == '__main__':
    unittest.main()
