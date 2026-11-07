import copy
import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from tooling.validate_delaware_instant_evidence import validate
from test.tooling.test_delaware_scratch_catalog import card, IMAGE


class InstantEvidenceTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.catalog = self.root / 'catalog.html'
        self.catalog.write_text(card('Design A') + card('Design B'))
        self.image = b'\xff\xd8\xfffixture'
        (self.root / '528.jpg').write_bytes(self.image)
        self.manifest = {'complete': True,
                         'catalogSha256': hashlib.sha256(self.catalog.read_bytes()).hexdigest(),
                         'entries': [{'gameId': '528', 'names': ['Design A', 'Design B'], 'url': IMAGE,
                                      'status': 200, 'file': '528.jpg', 'contentType': 'image/jpeg',
                                      'retrievedAt': '2026-11-07T12:00:00+00:00',
                                      'bytes': len(self.image), 'sha256': hashlib.sha256(self.image).hexdigest()}]}

    def run_manifest(self, manifest):
        (self.root / 'manifest.json').write_text(json.dumps(manifest))
        return validate(self.catalog, self.root)

    def test_shared_designs_preserved_once_with_source_time(self):
        rows = self.run_manifest(self.manifest)
        self.assertEqual(len(rows), 1)
        self.assertEqual(rows[0]['names'], ['Design A', 'Design B'])
        self.assertEqual(rows[0]['retrievedAt'], '2026-11-07T12:00:00+00:00')

    def test_missing_duplicate_and_failed_capture_reject(self):
        for entries in [[], self.manifest['entries'] * 2]:
            with self.subTest(entries=len(entries)), self.assertRaises(ValueError):
                self.run_manifest(dict(self.manifest, entries=entries))
        with self.assertRaises(ValueError):
            self.run_manifest(dict(self.manifest, complete=False))

    def test_changed_identity_source_path_and_date_reject(self):
        for key, value in [('gameId', '999'), ('names', ['Other']), ('url', IMAGE+'?other'),
                           ('file', '../528.jpg'), ('status', 403), ('retrievedAt', '2026-11-07T12:00:00')]:
            m = copy.deepcopy(self.manifest)
            m['entries'][0][key] = value
            with self.subTest(field=key), self.assertRaises(ValueError):
                self.run_manifest(m)

    def test_tampered_image_and_catalog_reject(self):
        (self.root / '528.jpg').write_bytes(self.image+b'changed')
        with self.assertRaises(ValueError): self.run_manifest(self.manifest)
        (self.root / '528.jpg').write_bytes(self.image)
        self.catalog.write_text(card('Changed'))
        with self.assertRaises(ValueError): self.run_manifest(self.manifest)


if __name__ == '__main__': unittest.main()
