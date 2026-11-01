import copy
import json
import unittest
from pathlib import Path
from tooling.arizona_catalog_links import parse_navigation


class CatalogLinksTest(unittest.TestCase):
    def setUp(self):
        self.capture = json.loads(Path('tooling/fixtures/arizona/scratchers-navigation.json').read_text())
        self.ids = {row['text'].split()[0].lstrip('#') for row in self.capture['links']}

    def test_observed_numbered_catalog(self):
        rows = parse_navigation(self.capture, 'scratchers', self.ids)
        self.assertEqual(len(rows), 58)
        self.assertEqual(next(r for r in rows if r['gameNumber'] == '1493')['title'], 'Ka-Pow')
        self.assertTrue(all(set(r) == {'gameNumber', 'title', 'sourceUrl'} for r in rows))

    def test_missing_duplicate_or_unexpected_identity(self):
        for action in ('missing', 'duplicate', 'unexpected'):
            c = copy.deepcopy(self.capture)
            if action == 'missing': c['links'].pop()
            elif action == 'duplicate': c['links'].append(c['links'][0])
            else: c['links'].append({'text': '#9999 New Game', 'href': '/scratchers/9999-new-game/'})
            with self.assertRaises(ValueError): parse_navigation(c, 'scratchers', self.ids)

    def test_untrusted_or_truncated_url(self):
        for href in ('https://example.com/scratchers/1401-set-for-life/',
                     '/scratchers/1558-holiday-cheer/', '/scratchers/1401-…/',
                     '/scratchers/1401-set-for-life/?x=1', 'javascript:alert(1)'):
            c = copy.deepcopy(self.capture); c['links'][0]['href'] = href
            with self.assertRaises(ValueError): parse_navigation(c, 'scratchers', self.ids)

    def test_provenance_required(self):
        for key in ('sourceUrl', 'captureKind', 'capturedAt'):
            c = copy.deepcopy(self.capture); c.pop(key)
            with self.assertRaises(ValueError): parse_navigation(c, 'scratchers', self.ids)


if __name__ == '__main__': unittest.main()
