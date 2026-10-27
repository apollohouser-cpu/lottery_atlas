from pathlib import Path
import unittest
from tooling.north_dakota_catalog import parse_catalog
from tooling.collect_north_dakota_coverage import official_fetch

SOURCE = (Path(__file__).parent/'fixtures/north_dakota/catalog.html').read_text()


class CatalogTests(unittest.TestCase):
    def test_current_and_retired_distinct(self):
        d = parse_catalog(SOURCE)
        self.assertEqual(len(d['currentGames']), 5)
        self.assertEqual(d['retired'], [{'game':'lucky-for-life','finalDrawDate':'2026-02-21'}])

    def test_changed_status_price_and_identity_rejected(self):
        for old,new in [('has ended','is active'), ('February 21, 2026','February 22, 2026'), ('$2','$3'), ('/games/powerball','/games/new-game')]:
            self.assertIn(old, SOURCE)
            with self.assertRaises(ValueError): parse_catalog(SOURCE.replace(old,new))

    def test_missing_extra_and_unclosed_cards(self):
        for text in ['', SOURCE+SOURCE, SOURCE.replace('gamepage','not-card',1), SOURCE.replace('</div>','',1)]:
            with self.assertRaises(ValueError): parse_catalog(text)

    def test_unreviewed_transport_url_rejected_without_network(self):
        for url in ['http://www.lottery.nd.gov/games/', 'https://wrong.invalid/', 'https://www.lottery.nd.gov/games/?changed=1']:
            with self.assertRaises(ValueError): official_fetch(url)
