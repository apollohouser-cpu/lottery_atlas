import copy
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from tooling.build_delaware_coverage_candidate import read_opening


class OpeningEvidenceTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.entries = []
        for name, suffix in [('instant', ''), ('top-prizes', '/Top-Prizes-Remaining'),
                             ('closeout', '/Close-Out-Schedule')]:
            raw = ('source fixture ' + name).encode()
            (self.root / (name + '.html')).write_bytes(raw)
            self.entries.append({'name': name, 'url': 'https://www.delottery.com/Instant-Games'+suffix,
                                 'retrievedAt': '2026-11-06T17:48:12+00:00', 'status': 200,
                                 'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()})

    def check(self, entries):
        (self.root / 'opening-manifest.json').write_text(json.dumps(entries))
        return read_opening(self.root)

    def test_original_dates_and_bytes_retained(self):
        raw, evidence = self.check(self.entries)
        self.assertEqual(raw['instant'], b'source fixture instant')
        self.assertEqual(evidence['instant']['retrievedAt'], '2026-11-06T17:48:12+00:00')

    def test_changed_bytes_reject_before_composition(self):
        (self.root / 'instant.html').write_bytes(b'altered')
        with self.assertRaises(ValueError): self.check(self.entries)

    def test_duplicate_source_wrong_host_failed_status_naive_date_reject(self):
        with self.assertRaises(ValueError): self.check(self.entries + [self.entries[0]])
        for key, value in [('url', 'https://example.com/Instant-Games'), ('status', 403),
                           ('retrievedAt', '2026-11-06T17:48:12')]:
            entries = copy.deepcopy(self.entries)
            entries[0][key] = value
            with self.subTest(field=key), self.assertRaises(ValueError): self.check(entries)


if __name__ == '__main__': unittest.main()
