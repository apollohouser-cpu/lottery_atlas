import copy
import json
from pathlib import Path
import unittest

from tooling.arizona_regular_draws import SOURCES, parse_captures, select_refresh


class RegularDrawTests(unittest.TestCase):
    def setUp(self):
        root = Path(__file__).parent / 'fixtures/arizona'
        names = {'powerball-xs-os': 'xsos', 'fantasy-5': 'fantasy5',
                 'pick-3': 'pick3', 'pick-4': 'pick4'}
        self.captures = {s: json.loads((root / (names.get(s, s) + '-tables.json')).read_text())
                         for s in SOURCES}

    def test_all_groups_keep_source_times_and_unavailable_reports(self):
        result = select_refresh(self.captures, self.captures)
        self.assertEqual(len(result['groups']), 11)
        self.assertEqual(sum(map(len, result['groups'].values())), 22)
        for group, rows in result['groups'].items():
            self.assertTrue(all(r['reportStatus'] == 'unavailable' for r in rows))
            self.assertTrue(all(r['sourceUrl'] == result['provenance'][group]['sourceUrl'] for r in rows))
            capture = next(c for c in self.captures.values()
                           if c['sourceUrl'] == rows[0]['sourceUrl'])
            self.assertEqual(result['provenance'][group]['retrievedAt'], capture['retrievedAt'])

    def test_each_missing_source_rejects_whole_collection(self):
        for source in SOURCES:
            bad = copy.deepcopy(self.captures)
            del bad[source]
            with self.subTest(source=source), self.assertRaises(ValueError):
                select_refresh(bad, self.captures)

    def test_each_bad_header_rejects_whole_collection(self):
        for source in SOURCES:
            bad = copy.deepcopy(self.captures)
            bad[source]['tables'][0]['rows'][0][0]['text'] = 'Changed'
            with self.subTest(source=source), self.assertRaises(ValueError):
                select_refresh(bad, self.captures)

    def test_each_retrieval_regression_rejected(self):
        for source in SOURCES:
            older = copy.deepcopy(self.captures)
            newer = copy.deepcopy(self.captures)
            newer[source]['retrievedAt'] = '2026-11-03T00:00:00+00:00'
            with self.subTest(source=source), self.assertRaises(ValueError):
                select_refresh(older, newer)

    def test_extra_source_and_swapped_identity_rejected(self):
        bad = copy.deepcopy(self.captures)
        bad['quick-draw'] = bad['powerball']
        with self.assertRaises(ValueError): parse_captures(bad)
        bad = copy.deepcopy(self.captures)
        bad['pick-3'], bad['pick-4'] = bad['pick-4'], bad['pick-3']
        with self.assertRaises(ValueError): parse_captures(bad)
