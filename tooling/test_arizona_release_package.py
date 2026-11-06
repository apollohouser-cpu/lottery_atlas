import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from tooling.package_arizona_release import package, release_bytes


class ReleasePackageTests(unittest.TestCase):
    def setUp(self):
        self.raw = Path('data/arizona_coverage.candidate.json').read_bytes()
        self.directory = tempfile.TemporaryDirectory()
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.source = self.root / 'candidate.json'
        self.output = self.root / 'release.json'
        self.source.write_bytes(self.raw)

    def test_only_release_identity_changes_and_check_is_read_only(self):
        before = json.loads(self.raw)
        after = json.loads(release_bytes(self.raw))
        self.assertTrue(after.pop('productionReady'))
        self.assertEqual(after.pop('recordType'), 'supported-coverage')
        before.pop('productionReady')
        before.pop('recordType')
        self.assertEqual(before, after)
        first = package(self.source, self.output)
        stamp = self.output.stat().st_mtime_ns
        checked = package(self.source, self.output, check=True)
        self.assertEqual(first['sha256'], checked['sha256'])
        self.assertEqual(stamp, self.output.stat().st_mtime_ns)

    def test_unreviewed_input_cannot_replace_existing_release(self):
        self.output.write_bytes(b'previous release')
        self.source.write_bytes(self.raw + b' ')
        with self.assertRaises(ValueError):
            package(self.source, self.output)
        self.assertEqual(self.output.read_bytes(), b'previous release')

    def test_failed_replace_preserves_bytes_and_removes_temporary(self):
        self.output.write_bytes(b'previous release')
        with patch('tooling.package_arizona_release.os.replace', side_effect=OSError('disk failure')):
            with self.assertRaises(OSError):
                package(self.source, self.output)
        self.assertEqual(self.output.read_bytes(), b'previous release')
        self.assertEqual(sorted(p.name for p in self.root.iterdir()), ['candidate.json', 'release.json'])

    def test_source_overwrite_and_changed_release_rejected(self):
        with self.assertRaises(ValueError):
            package(self.source, self.source)
        self.assertEqual(self.source.read_bytes(), self.raw)
        self.output.write_bytes(b'changed')
        with self.assertRaises(ValueError):
            package(self.source, self.output, check=True)
        self.assertEqual(self.output.read_bytes(), b'changed')
