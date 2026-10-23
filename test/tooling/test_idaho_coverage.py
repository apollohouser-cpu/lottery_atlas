from datetime import datetime, timezone
import unittest
from tooling.idaho_coverage import collect


class IdahoCoverageTest(unittest.TestCase):
    def test_missing_timezone_rejected_before_requests(self):
        calls = []
        with self.assertRaises(ValueError):
            collect(lambda url:calls.append(url), now=datetime(2026,10,23))
        self.assertEqual(calls, [])

    def test_invalid_source_aborts_without_partial_result(self):
        for raw in [b'', None, '{}', b'<html>Wrong page</html>']:
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                collect(lambda url:raw, now=datetime(2026,10,23,tzinfo=timezone.utc))

    def test_request_error_propagates(self):
        def fail(url): raise OSError('controlled request failure')
        with self.assertRaises(OSError):
            collect(fail, now=datetime(2026,10,23,tzinfo=timezone.utc))
