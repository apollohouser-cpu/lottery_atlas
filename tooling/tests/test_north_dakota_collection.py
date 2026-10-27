import copy
from datetime import datetime, timezone
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from tooling import north_dakota_coverage as coverage
from tooling.tests.test_north_dakota_draws import FIXTURE, markup

ROOT = Path(__file__).parent / 'fixtures/north_dakota'
STAMP = datetime(2026, 10, 27, 18, tzinfo=timezone.utc)


def captures():
    specs = json.loads(coverage.SPEC_PATH.read_text())
    sources = {}
    for game in coverage.GAMES:
        sources[coverage.draws.source_url(game)] = markup(FIXTURE[game]).encode()
        sources[specs[game]['sourceUrl']] = (ROOT / (game+'-rules.html')).read_bytes()
    return sources


class CollectionTests(unittest.TestCase):
    def baseline(self):
        return coverage.collect(captures().__getitem__, lambda: STAMP)

    def test_coupled_provenance_and_gaps(self):
        d = self.baseline()
        self.assertEqual((len(d['results']), len(d['rules']), len(d['sources'])), (10, 5, 10))
        for row in d['results']:
            self.assertEqual(row['reportStatus'], 'unavailable')
            self.assertNotIn('drawId', row)
            self.assertNotIn('drawTimeUtc', row)
        self.assertTrue(all(len(s['sha256']) == 64 and s['bytes'] > 0 for s in d['sources']))

    def test_every_request_failure_retains_exact_bytes(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root)/'coverage.json'
            coverage.refresh(path, captures().__getitem__, lambda: STAMP)
            original = path.read_bytes()
            for failure in range(10):
                count = 0
                def fetch(url):
                    nonlocal count
                    index = count
                    count += 1
                    if index == failure: raise OSError('Injected request failure')
                    return captures()[url]
                with self.subTest(failure=failure), self.assertRaises(OSError):
                    coverage.refresh(path, fetch, lambda: STAMP)
                self.assertEqual(path.read_bytes(), original)
                self.assertEqual(list(Path(root).iterdir()), [path])

    def test_parsed_correction_retains_original_bytes(self):
        source = captures()
        changed = copy.deepcopy(FIXTURE['powerball'])
        changed['rows'][1][1] = '1-2-3-4-5'
        source[coverage.draws.source_url('powerball')] = markup(changed).encode()
        with tempfile.TemporaryDirectory() as root:
            path = Path(root)/'coverage.json'
            coverage.refresh(path, captures().__getitem__, lambda: STAMP)
            original = path.read_bytes()
            with self.assertRaisesRegex(ValueError, 'corrected'):
                coverage.refresh(path, source.__getitem__, lambda: STAMP)
            self.assertEqual(path.read_bytes(), original)

    def test_replace_failure_retains_bytes_and_cleans_temp(self):
        with tempfile.TemporaryDirectory() as root:
            path = Path(root)/'coverage.json'
            coverage.refresh(path, captures().__getitem__, lambda: STAMP)
            original = path.read_bytes()
            with patch.object(coverage.os, 'replace', side_effect=OSError('disk failure')):
                with self.assertRaises(OSError): coverage.refresh(path, captures().__getitem__, lambda: STAMP)
            self.assertEqual(path.read_bytes(), original)
            self.assertEqual(list(Path(root).iterdir()), [path])

    def test_rule_failure_leaves_no_initial_file(self):
        source = captures()
        key = json.loads(coverage.SPEC_PATH.read_text())['2by2']['sourceUrl']
        source[key] = source[key].replace(b'7 consecutive', b'6 consecutive')
        with tempfile.TemporaryDirectory() as root:
            path = Path(root)/'coverage.json'
            with self.assertRaises(ValueError): coverage.refresh(path, source.__getitem__, lambda: STAMP)
            self.assertFalse(path.exists())

    def test_corrections_gaps_and_identity_changes_fail(self):
        old = self.baseline()
        for mutate in [lambda d: d['results'][0]['numbers'].__setitem__(0, 1),
                       lambda d: d['results'][0].update(reportStatus='available'),
                       lambda d: d['results'].pop(),
                       lambda d: d['results'][0].update(game='retired'),
                       lambda d: d.update(state='Wyoming'),
                       lambda d: d['rules'].pop(),
                       lambda d: d.update(updatedAt='2026-10-26T18:00:00Z')]:
            d = copy.deepcopy(old)
            mutate(d)
            with self.assertRaises(ValueError): coverage.continuity(old, d)

    def test_newer_capture_and_window_advancement(self):
        old = self.baseline()
        new = copy.deepcopy(old)
        new['updatedAt'] = '2026-10-28T18:00:00Z'
        for row in new['results']: row['sourceRetrievedAt'] = new['updatedAt']
        self.assertEqual(coverage.continuity(old, new), new)
        # Retain the former newest date and evict only the oldest result.
        new['results'][1] = copy.deepcopy(old['results'][0])
        new['results'][0]['drawDate'] = '2026-10-28'
        coverage.continuity(old, new)
        new['results'][1]['drawDate'] = '2026-10-25'
        with self.assertRaises(ValueError): coverage.continuity(old, new)

    def test_empty_invalid_encoding_and_clock_regression(self):
        for raw in [b'', 'not bytes', b'\xff']:
            with self.assertRaises((ValueError, UnicodeError)):
                coverage.collect(lambda url: raw, lambda: STAMP)
        stamps = iter([STAMP, datetime(2026, 10, 26, tzinfo=timezone.utc)])
        with self.assertRaises(ValueError): coverage.collect(captures().__getitem__, lambda: next(stamps))
        with self.assertRaises(ValueError): coverage.collect(captures().__getitem__, lambda: STAMP.replace(tzinfo=None))
