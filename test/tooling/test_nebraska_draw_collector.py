from datetime import datetime, timezone
import json
from pathlib import Path
import tempfile
import unittest
from urllib.parse import parse_qs, urlparse
from unittest.mock import patch

from tooling.collect_nebraska_draws import collect
from tooling.nebraska_draw_results import SPECS

FIXTURES = Path(__file__).parents[1] / 'fixtures' / 'nebraska'
NOW = datetime(2026, 10, 16, 18, tzinfo=timezone.utc)


class CollectorTest(unittest.TestCase):
    def fetch(self, url):
        family = parse_qs(urlparse(url).query)['gamename'][0]
        return (FIXTURES / (SPECS[family][0][0] + '.html')).read_bytes()

    def test_complete_output_is_explicit_private_stage(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'snapshot.json'
            result = collect(path, fetch=self.fetch, now=NOW)
            self.assertEqual(json.loads(path.read_text()), result)
            self.assertEqual(len(result['results']), 22)
            self.assertEqual(result['stage'], 'private-validation-only')

    def test_each_network_failure_preserves_bytes_and_date(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'snapshot.json'
            collect(path, fetch=self.fetch, now=NOW)
            before = path.read_bytes()
            for failed in SPECS:
                def fail(url):
                    if parse_qs(urlparse(url).query)['gamename'][0] == failed:
                        raise TimeoutError('source timeout')
                    return self.fetch(url)
                with self.subTest(family=failed), self.assertRaises(TimeoutError):
                    collect(path, fetch=fail, now=NOW)
                self.assertEqual(path.read_bytes(), before)

    def test_validation_and_replace_failure_preserve_bytes(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'snapshot.json'
            collect(path, fetch=self.fetch, now=NOW)
            before = path.read_bytes()
            with self.assertRaises(ValueError):
                collect(path, fetch=lambda _: b'<html>unavailable</html>', now=NOW)
            self.assertEqual(path.read_bytes(), before)
            with patch('tooling.collect_nebraska_draws.os.replace', side_effect=OSError('disk error')):
                with self.assertRaises(OSError):
                    collect(path, fetch=self.fetch, now=NOW)
            self.assertEqual(path.read_bytes(), before)
            self.assertEqual(list(Path(folder).iterdir()), [path])

    def test_no_baseline_failure_creates_no_output(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'snapshot.json'
            with self.assertRaises(ValueError):
                collect(path, fetch=lambda _: b'<html>unavailable</html>', now=NOW)
            self.assertFalse(path.exists())


if __name__ == '__main__':
    unittest.main()
