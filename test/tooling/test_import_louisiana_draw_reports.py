from datetime import datetime, timezone
from pathlib import Path
import json
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'tooling'))
from import_louisiana_draw_reports import refresh

FIXTURES = Path(__file__).resolve().parents[1] / 'fixtures/louisiana'
NOW = datetime(2026, 10, 13, 12, tzinfo=timezone.utc)


def fetch_fixture(url):
    slug = url.rstrip('/').split('/')[-1]
    return (FIXTURES / (('pick3' if slug == 'pick-3' else slug)+'.html')).read_bytes()


class RefreshTests(unittest.TestCase):
    def test_complete_atomic_refresh_and_unchanged_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory)/'reports.json'
            first = refresh(target, fetch_fixture, NOW); data = target.read_bytes()
            second = refresh(target, fetch_fixture, NOW.replace(hour=13))
            self.assertEqual(len(first['reports']), 14)
            self.assertEqual(first, second)
            self.assertEqual(target.read_bytes(), data)
            self.assertEqual(list(Path(directory).glob('*.tmp')), [])

    def test_fetch_or_parse_failure_preserves_file(self):
        for corrupt in [False, True]:
            with self.subTest(corrupt=corrupt), tempfile.TemporaryDirectory() as directory:
                target = Path(directory)/'reports.json'; refresh(target, fetch_fixture, NOW)
                data = target.read_bytes()
                def fail(url):
                    if 'pick-5' in url:
                        if corrupt: return b'<html>broken</html>'
                        raise OSError('request failed')
                    return fetch_fixture(url)
                with self.assertRaises((OSError, ValueError)): refresh(target, fail, NOW)
                self.assertEqual(target.read_bytes(), data)

    def test_date_and_source_regressions_preserve_file(self):
        for field, value in [('drawDate', '2026-10-13'), ('sourceUpdatedAt', '2026-10-13T00:00:00-05:00')]:
            with self.subTest(field=field), tempfile.TemporaryDirectory() as directory:
                target = Path(directory)/'reports.json'; previous = refresh(target, fetch_fixture, NOW)
                previous['reports'][0][field] = value
                target.write_text(json.dumps(previous)); data = target.read_bytes()
                with self.assertRaises(ValueError): refresh(target, fetch_fixture, NOW)
                self.assertEqual(target.read_bytes(), data)

    def test_replace_failure_keeps_previous_and_cleans_temporary(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory)/'reports.json'; previous = refresh(target, fetch_fixture, NOW)
            previous['coverage'] = 'older coverage'; target.write_text(json.dumps(previous)); data = target.read_bytes()
            with patch.object(Path, 'replace', side_effect=OSError('disk failure')):
                with self.assertRaises(OSError): refresh(target, fetch_fixture, NOW)
            self.assertEqual(target.read_bytes(), data)
            self.assertEqual(list(Path(directory).glob('*.tmp')), [])


if __name__ == '__main__': unittest.main()
