import copy
import json
import unittest
from pathlib import Path
from tooling.arizona_catalog_links import parse_navigation, validate_continuity


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

    def test_fast_play_observed_navigation(self):
        c = json.loads(Path('tooling/fixtures/arizona/fast-play-navigation.json').read_text())
        ids = {'169','171','175','178','179','180','181','182','183','184','185',
               '187','189','192','193','196','198','199','200','201','202','203','204','205','206'}
        self.assertEqual(len(parse_navigation(c, 'fast-play', ids)), 25)
        with self.assertRaises(ValueError): parse_navigation(c, 'scratchers', ids)

    def test_timestamp_and_malformed_rows(self):
        for date in ('not-a-date', '2026-11-01', '2026-11-01T12:00:00'):
            c = copy.deepcopy(self.capture); c['capturedAt'] = date
            with self.assertRaises(ValueError): parse_navigation(c, 'scratchers', self.ids)
        c = copy.deepcopy(self.capture); c['links'][0] = None
        with self.assertRaises(ValueError): parse_navigation(c, 'scratchers', self.ids)

    def test_continuity_blocks_changed_titles_sources_and_duplicates(self):
        baseline = parse_navigation(self.capture, 'scratchers', self.ids)
        validate_continuity(list(reversed(baseline)), baseline)
        for field in ('title', 'sourceUrl', 'gameNumber'):
            changed = copy.deepcopy(baseline); changed[0][field] += 'changed'
            with self.assertRaises(ValueError): validate_continuity(changed, baseline)
        with self.assertRaises(ValueError): validate_continuity(baseline + baseline[:1], baseline)


if __name__ == '__main__': unittest.main()
