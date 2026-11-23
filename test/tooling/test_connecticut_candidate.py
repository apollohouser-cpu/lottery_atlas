import hashlib
from pathlib import Path
import tempfile
import unittest
from tooling.build_connecticut_candidate import verified_capture, verify_report_request


class CaptureTest(unittest.TestCase):
    def test_original_bytes_verified_and_changed_bytes_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); (root/'source').write_bytes(b'original')
            manifest = dict(bytes=8, sha256=hashlib.sha256(b'original').hexdigest())
            self.assertEqual(verified_capture(root, 'source', manifest), b'original')
            (root/'source').write_bytes(b'modified')
            with self.assertRaises(ValueError): verified_capture(root, 'source', manifest)

    def test_report_bound_to_exact_game_draw_and_date(self):
        draw = dict(drawId='123', drawDate='2026-11-21')
        url = 'https://ctlottery.com/api/winning-payouts?game=lotto&draw=123&date=2026-11-21'
        self.assertEqual(verify_report_request(dict(url=url), 'lotto', draw), (123, '2026-11-21'))
        for changed in [url.replace('lotto', 'mfl'), url.replace('123', '124'),
                        url.replace('2026-11-21', '2026-11-20'), url+'&draw=123',
                        url.replace('ctlottery.com', 'example.com')]:
            with self.assertRaises(ValueError): verify_report_request(dict(url=changed), 'lotto', draw)

    def test_empty_capture_rejected_even_with_matching_hash(self):
        with tempfile.TemporaryDirectory() as directory:
            root = Path(directory); (root/'source').write_bytes(b'')
            manifest = dict(bytes=0, sha256=hashlib.sha256(b'').hexdigest())
            with self.assertRaises(ValueError): verified_capture(root, 'source', manifest)


if __name__ == '__main__': unittest.main()
