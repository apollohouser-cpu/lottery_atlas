import hashlib
from pathlib import Path
import tempfile
import unittest
from tooling.build_connecticut_candidate import verified_capture


class CaptureTest(unittest.TestCase):
    def test_original_bytes_verified_and_changed_bytes_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); (root/'source').write_bytes(b'original')
            manifest = dict(bytes=8, sha256=hashlib.sha256(b'original').hexdigest())
            self.assertEqual(verified_capture(root, 'source', manifest), b'original')
            (root/'source').write_bytes(b'modified')
            with self.assertRaises(ValueError): verified_capture(root, 'source', manifest)

    def test_empty_capture_rejected_even_with_matching_hash(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); (root/'source').write_bytes(b'')
            manifest = dict(bytes=0, sha256=hashlib.sha256(b'').hexdigest())
            with self.assertRaises(ValueError): verified_capture(root, 'source', manifest)


if __name__ == '__main__': unittest.main()
