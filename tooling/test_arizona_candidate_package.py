import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from compile_arizona_candidate import package
from test_arizona_snapshot import fixture_snapshot


class CandidatePackageTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.snapshot = self.root / 'source.json'
        self.output = self.root / 'candidate.json'
        self.captures = fixture_snapshot()
        self.write_source(self.captures)

    def write_source(self, captures):
        self.snapshot.write_text(json.dumps({
            'schemaVersion': 1, 'status': 'private-development-snapshot',
            'productionReady': False, 'captures': captures,
            'validated': {'untrusted': 'not used'},
        }))

    def test_repeatable_and_check_does_not_mutate(self):
        first = package(self.snapshot, self.snapshot, self.output)
        before = self.output.stat().st_mtime_ns
        second = package(self.snapshot, self.snapshot, self.output, check=True)
        self.assertEqual(first['sha256'], second['sha256'])
        self.assertEqual(before, self.output.stat().st_mtime_ns)
        data = json.loads(self.output.read_text())
        self.assertNotIn('captures', data)
        self.assertFalse(data['productionReady'])

    def test_invalid_late_component_keeps_existing_bytes(self):
        self.output.write_bytes(b'previous artifact')
        bad = copy.deepcopy(self.captures)
        bad['endings']['fast-play']['tables'][0]['rows'][-2][1]['text'] = '11/31/2026'
        self.write_source(bad)
        with self.assertRaises(ValueError):
            package(self.snapshot, self.snapshot, self.output)
        self.assertEqual(self.output.read_bytes(), b'previous artifact')

    def test_failed_replace_keeps_previous_and_removes_temporary(self):
        self.output.write_bytes(b'previous artifact')
        with patch('compile_arizona_candidate.os.replace', side_effect=OSError('storage failure')):
            with self.assertRaises(OSError):
                package(self.snapshot, self.snapshot, self.output)
        self.assertEqual(self.output.read_bytes(), b'previous artifact')
        self.assertEqual(sorted(p.name for p in self.root.iterdir()), ['candidate.json', 'source.json'])

    def test_check_rejects_changed_bytes_and_source_overwrite(self):
        self.output.write_bytes(b'changed artifact')
        with self.assertRaises(ValueError):
            package(self.snapshot, self.snapshot, self.output, check=True)
        before = self.snapshot.read_bytes()
        with self.assertRaises(ValueError):
            package(self.snapshot, self.snapshot, self.snapshot)
        self.assertEqual(self.snapshot.read_bytes(), before)

    def test_valid_but_changed_ending_date_rejected_against_retained(self):
        retained = self.root / 'retained.json'
        retained.write_bytes(self.snapshot.read_bytes())
        self.output.write_bytes(b'previous artifact')
        changed = copy.deepcopy(self.captures)
        changed['endings']['fast-play']['tables'][0]['rows'][-2][1]['text'] = '11/3/2026'
        self.write_source(changed)
        with self.assertRaises(ValueError):
            package(self.snapshot, retained, self.output)
        self.assertEqual(self.output.read_bytes(), b'previous artifact')
