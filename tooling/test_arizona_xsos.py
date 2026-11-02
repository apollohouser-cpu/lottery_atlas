import copy
import json
from pathlib import Path
import unittest
from tooling.arizona_xsos import parse_capture


class XsOsTests(unittest.TestCase):
    def setUp(self):
        self.capture = json.loads((Path(__file__).parent / 'fixtures/arizona/xsos-tables.json').read_text())

    def test_literal_labels_no_counts(self):
        result = parse_capture(self.capture)
        self.assertEqual(len(result), 8)
        self.assertEqual(result[0]['teamLabels'], ['ARI', 'ATL', 'BAL', 'DET', 'GB', 'LV', 'PIT', 'WAS'])
        self.assertTrue(all(r['reportStatus'] == 'unavailable' for r in result))

    def test_label_image_join_and_unseen_labels_fail(self):
        for kind in ('image', 'duplicate', 'unseen'):
            bad = copy.deepcopy(self.capture)
            cell = bad['tables'][0]['rows'][1][1]
            if kind == 'image': cell['images'][0]['src'] = '/wrong.svg'
            if kind == 'duplicate': cell['text'] = cell['text'].replace('ATL', 'ARI')
            if kind == 'unseen': cell['text'] = cell['text'].replace('ARI', 'ZZZ')
            with self.subTest(kind=kind), self.assertRaises(ValueError): parse_capture(bad)

    def test_missing_week_fails(self):
        del self.capture['tables'][0]['rows'][3:5]
        with self.assertRaises(ValueError): parse_capture(self.capture)
