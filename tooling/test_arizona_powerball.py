import copy
import json
from pathlib import Path
import unittest

from tooling.arizona_powerball import parse_capture, select_refresh


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

    def test_refresh_selects_latest_two_without_mutating_inputs(self):
        before = copy.deepcopy(self.capture)
        selected = select_refresh(self.capture, before)
        self.assertEqual(self.capture, before)
        self.assertEqual({k: len(v) for k, v in selected.items()},
                         {'powerball': 2, 'powerball-double-play': 2})

    def test_refresh_rejects_valid_but_corrected_numbers(self):
        bad = copy.deepcopy(self.capture)
        bad['tables'][0]['rows'][1][1]['text'] = '3 4 18 50 56'
        with self.assertRaisesRegex(ValueError, 'corrected'):
            select_refresh(bad, self.capture)

    def test_refresh_rejects_missing_overlapping_row_and_latest_regression(self):
        for index in (1, 5):
            bad = copy.deepcopy(self.capture)
            del bad['tables'][0]['rows'][index:index+2]
            with self.subTest(index=index), self.assertRaises(ValueError):
                select_refresh(bad, self.capture)

    def test_refresh_rejects_retrieval_regression(self):
        bad = copy.deepcopy(self.capture)
        bad['retrievedAt'] = '2026-11-01T00:00:00Z'
        with self.assertRaisesRegex(ValueError, 'acquisition'):
            select_refresh(bad, self.capture)

    def test_refresh_allows_old_tail_to_roll_off(self):
        new = copy.deepcopy(self.capture)
        for table in new['tables']:
            del table['rows'][-3:-1]
        self.assertEqual(select_refresh(new, self.capture),
                         select_refresh(self.capture, self.capture))

    def test_synthetic_date_advance_preserves_retained_overlap(self):
        new = copy.deepcopy(self.capture)
        new['retrievedAt'] = '2026-11-03T08:00:00Z'
        for table in new['tables']:
            pair = copy.deepcopy(table['rows'][1:3])
            pair[0][0]['text'] = '11/2/2026'
            table['rows'][1:1] = pair
        selected = select_refresh(new, self.capture)
        self.assertTrue(all([r['drawDate'] for r in draws] ==
                            ['2026-11-02', '2026-10-31']
                            for draws in selected.values()))


if __name__ == '__main__':
    unittest.main()
