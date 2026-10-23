from pathlib import Path
import unittest
from tooling.idaho_instant_catalogs import build_catalog, parse_listing

F = Path(__file__).parent / 'fixtures'


class InstantCatalogTest(unittest.TestCase):
    def raw(self, kind):
        return (F / f'idaho_catalog_{kind}.html').read_bytes()

    def fetch(self, url):
        kind, slug = url.rsplit('/', 2)[1:]
        return (F / f'idaho_{"instaplay" if kind == "instaplay" else "tab"}_{slug}.html').read_bytes()

    def test_complete_join_and_missing_ids(self):
        for kind, count in [('instaplay', 12), ('tabs', 11)]:
            games = build_catalog(self.raw(kind), kind, self.fetch)['games']
            self.assertEqual(len(games), count)
            self.assertTrue(all(g['remainingPrizes'] is None for g in games))
        games = build_catalog(self.raw('instaplay'), 'instaplay', self.fetch)['games']
        self.assertIsNone(next(g for g in games if g['slug'] == 'blackjack')['sourceGameId'])

    def test_every_detail_failure_aborts(self):
        for kind, count in [('instaplay', 12), ('tabs', 11)]:
            for failure in range(count):
                calls = []
                def fetch(url):
                    calls.append(url)
                    if len(calls) == failure + 1: raise OSError('controlled')
                    return self.fetch(url)
                with self.assertRaises(OSError): build_catalog(self.raw(kind), kind, fetch)

    def test_catalog_changes_rejected(self):
        for kind in ['instaplay', 'tabs']:
            raw = self.raw(kind)
            with self.assertRaises(ValueError): parse_listing(raw.replace(b'data-game-id=', b'other-id=', 1), kind)
            with self.assertRaises(ValueError): parse_listing(raw.replace(b'</body>', f'<a href="/games/{kind}/new-game">New</a></body>'.encode()), kind)
            with self.assertRaises(ValueError): parse_listing(raw.replace(b'data-game-type="', b'data-game-type="wrong', 1), kind)

    def test_wrong_detail_identity_rejected(self):
        with self.assertRaises(ValueError):
            build_catalog(self.raw('instaplay'), 'instaplay', lambda url: self.fetch('https://www.idaholottery.com/games/instaplay/blackjack'))
