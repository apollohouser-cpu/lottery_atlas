import hashlib
import json
from pathlib import Path
import tempfile
import unittest
from tooling.build_delaware_report_candidate import build


class ReportCandidateTest(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory()
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        fixture_root = Path(__file__).resolve().parents[1] / 'fixtures/delaware'
        self.entries = []
        for slug, fixture in [('Multi-Win-Lotto', 'multiwin_report.html'),
                              ('Powerball-Xs-And-Os', 'xsos_report.html'),
                              ('Powerball', 'doubleplay_report.html'),
                              ('Mega-Millions', 'megamillions_report.html'),
                              ('Play-3', 'play3_report.html'), ('Play-4', 'play4_report.html'),
                              ('Play-5', 'play5_report.html'), ('Lucky-For-Life', 'luckyforlife_report.html')]:
            raw = (fixture_root / fixture).read_bytes()
            filename = f'Drawing-Games_{slug}_Number-Of-Winners.html'
            (self.root / filename).write_bytes(raw)
            self.entries.append({'file': filename, 'url': f'https://www.delottery.com/Drawing-Games/{slug}/Number-Of-Winners',
                                 'status': 200, 'retrievedAt': '2026-11-07T12:00:00+00:00',
                                 'bytes': len(raw), 'sha256': hashlib.sha256(raw).hexdigest()})

    def run_build(self):
        (self.root / 'rules-history-manifest.json').write_text(json.dumps(self.entries))
        return build(self.root)

    def test_session_and_legacy_boundaries_preserved(self):
        data = self.run_build()
        reports = {r['family']: r['report'] for r in data['reports']}
        self.assertEqual(len(reports), 8)
        self.assertEqual(reports['Powerball-Double-Play']['game'], 'Powerball Double Play')
        self.assertNotIn('Powerball', reports)
        self.assertEqual(reports['Play-3']['session'], 'day')
        self.assertEqual(reports['Play-3']['drawDate'], '2026-11-06')
        self.assertEqual(reports['Lucky-For-Life']['status'], 'historical/legacy')
        self.assertNotIn('Lotto-America', reports)
        self.assertNotIn('results', data)

    def test_altered_capture_rejects(self):
        p = self.root / self.entries[0]['file']
        p.write_bytes(p.read_bytes() + b'changed')
        with self.assertRaises(ValueError): self.run_build()

    def test_duplicate_manifest_and_wrong_source_reject(self):
        self.entries.append(self.entries[0])
        with self.assertRaises(ValueError): self.run_build()
        self.entries.pop()
        self.entries[0]['url'] = self.entries[1]['url']
        with self.assertRaises(ValueError): self.run_build()


if __name__ == '__main__': unittest.main()
