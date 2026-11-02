import copy
import json
from pathlib import Path
import unittest
from tooling.arizona_pick3 import parse_capture


class Pick3Tests(unittest.TestCase):
    def setUp(self):
        self.capture = json.loads((Path(__file__).parent / 'fixtures/arizona/pick3-tables.json').read_text())

    def test_observed_sessions(self):
        result = parse_capture(self.capture)
        self.assertEqual([len(r) for r in result.values()], [141, 141])
        self.assertEqual(result['pick-3-evening'][0]['digits'], '181')
        self.assertEqual(result['pick-3-midday'][0]['digits'], '239')
        self.assertTrue(any(r['digits'].startswith('0') for rows in result.values() for r in rows))

    def test_zeros_and_repeats_are_preserved(self):
        self.capture['tables'][0]['rows'][1][1]['text'] = '0 0 0'
        self.assertEqual(parse_capture(self.capture)['pick-3-evening'][0]['digits'], '000')

    def test_invalid_session_or_digits(self):
        for col, value in [(0, '11/1/2026'), (0, '11/1/2026 Night'), (1, '1 8'), (1, '1 8 10')]:
            bad = copy.deepcopy(self.capture)
            bad['tables'][0]['rows'][1][col]['text'] = value
            with self.subTest(value=value), self.assertRaises(ValueError): parse_capture(bad)

    def test_missing_or_duplicate_session_rejected(self):
        bad = copy.deepcopy(self.capture)
        del bad['tables'][0]['rows'][3:5]
        with self.assertRaises(ValueError): parse_capture(bad)
        self.capture['tables'][0]['rows'][3][0]['text'] = '11/1/2026 Evening'
        with self.assertRaises(ValueError): parse_capture(self.capture)
