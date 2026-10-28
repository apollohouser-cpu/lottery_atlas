import copy
import gzip
import json
from datetime import datetime, timezone
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch
from urllib.parse import urlparse, parse_qs
from tooling import montana_coverage as coverage

FIXTURES = Path(__file__).with_name('fixtures') / 'montana'
STAMP = datetime(2026, 10, 28, 10, tzinfo=timezone.utc)

class CollectionTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.raw = {}
        for url in coverage.source_urls():
            parsed = urlparse(url)
            slug = parsed.path.strip('/')
            if url == coverage.ENDING_URL:
                raw = b'isolated PDF transport fixture; parser tested separately'
            elif slug == 'games':
                raw = gzip.decompress((FIXTURES / 'games.html.gz').read_bytes())
            elif slug in ('scratch-games', 'treasure-play'):
                query = parse_qs(parsed.query)
                page = next(iter(query.values()))[0] if query else ''
                raw = gzip.decompress((FIXTURES / 'catalog' / (slug + ('-' + page if page else '') + '.html.gz')).read_bytes())
            else:
                if slug == 'montana-millionaire':
                    raw = (FIXTURES / 'raffle-offer.html').read_bytes()
                else:
                    raw = gzip.decompress((FIXTURES / (slug + '-coupled.html.gz')).read_bytes())
            cls.raw[url] = raw

    def setUp(self):
        # PDF byte/visual contract has separate parser tests; never a public fixture
        # containing the original notice's administrative footer.
        self.pdf = patch.object(coverage, 'parse_endings', side_effect=lambda raw, retrieved_at: {'sourceRetrievedAt': retrieved_at, 'rows': [], 'sourceUrl': coverage.ENDING_URL})
        self.pdf.start()
        self.addCleanup(self.pdf.stop)

    def collect(self):
        return coverage.collect(self.raw.__getitem__, lambda: STAMP)

    def test_all_components_and_provenance(self):
        data = self.collect()
        self.assertEqual(len(data['sources']), 24)
        self.assertEqual(len(data['results']), 14)
        self.assertEqual(len(data['rules']), 6)
        self.assertEqual(len(data['catalogs']['scratch']['entries']), 57)
        self.assertTrue(all(r['reportStatus'] == 'unavailable' for r in data['results']))
        self.assertEqual([s['url'] for s in data['sources']], coverage.source_urls())
        for source in data['sources']:
            self.assertEqual(source['bytes'], len(self.raw[source['url']]))

    def test_each_request_failure_retains_snapshot(self):
        with TemporaryDirectory() as directory:
            path = Path(directory) / 'snapshot.json'
            coverage.refresh(path, self.raw.__getitem__, lambda: STAMP)
            old = path.read_bytes()
            for failed in coverage.source_urls():
                def fetch(url):
                    if url == failed:
                        raise OSError('controlled request failure')
                    return self.raw[url]
                with self.assertRaises(OSError):
                    coverage.refresh(path, fetch, lambda: STAMP)
                self.assertEqual(path.read_bytes(), old)
                self.assertEqual(list(Path(directory).iterdir()), [path])

    def test_disk_replace_failure_retains_snapshot(self):
        with TemporaryDirectory() as directory:
            path = Path(directory) / 'snapshot.json'
            coverage.refresh(path, self.raw.__getitem__, lambda: STAMP)
            old = path.read_bytes()
            with patch.object(coverage.os, 'replace', side_effect=OSError('disk failure')):
                with self.assertRaises(OSError):
                    coverage.refresh(path, self.raw.__getitem__, lambda: STAMP)
            self.assertEqual(path.read_bytes(), old)
            self.assertEqual(list(Path(directory).iterdir()), [path])

    def test_corrections_regressions_and_boundary_changes_rejected(self):
        old = self.collect()
        changes = [lambda d: d['results'][0]['numbers'].reverse(),
                   lambda d: d['results'].pop(),
                   lambda d: d.update(updatedAt='2026-10-27T10:00:00+00:00'),
                   lambda d: d['status']['regularFamilies'].pop(),
                   lambda d: d['catalogs']['scratch']['entries'].pop(),
                   lambda d: d['raffle'].update(edition='2027'),
                   lambda d: d['rules'].pop()]
        for change in changes:
            candidate = copy.deepcopy(old)
            change(candidate)
            with self.assertRaises(ValueError):
                coverage.continuity(old, candidate)

    def test_refresh_capture_advances_without_changing_results(self):
        old = self.collect()
        new = coverage.collect(self.raw.__getitem__, lambda: datetime(2026, 10, 28, 11, tzinfo=timezone.utc))
        self.assertEqual(coverage.continuity(old, new), new)

    def test_clock_regression_and_invalid_body_rejected(self):
        stamps = iter([STAMP, datetime(2026, 10, 27, 10, tzinfo=timezone.utc)])
        with self.assertRaises(ValueError):
            coverage.collect(self.raw.__getitem__, lambda: next(stamps))
        for body in (b'', 'text'):
            with self.assertRaises(ValueError):
                coverage.collect(lambda url: body, lambda: STAMP)

if __name__ == '__main__':
    unittest.main()
