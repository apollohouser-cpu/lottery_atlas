import copy
import json
from pathlib import Path
import tempfile
import unittest

from arizona_symbol_reviews import reconstruct, load_reviews


class SymbolReviewTests(unittest.TestCase):
    def setUp(self):
        self.fixture = json.loads(Path('test/fixtures/arizona_symbol_review.json').read_text())

    def result(self, fixture=None):
        f = fixture or self.fixture
        return reconstruct(f['product'], f['review'], f['dom'])

    def test_labels_preserve_inline_multipliers_and_annuity(self):
        text = self.result()['text']
        self.assertIn('"[symbol: 10X]" or "[symbol: 50X]" MULTIPLIER', text)
        self.assertIn('"[symbol: LIFE]" symbol, win $250,000 A YEAR FOR 20 YEARS!', text)
        self.assertNotIn('<img', text)

    def test_changed_source_or_rule_rejected(self):
        for key in ('sourceUrl', 'rules'):
            f = copy.deepcopy(self.fixture)
            if key == 'sourceUrl':
                f['product'][key] += '?different'
            else:
                f['product'][key]['text'] += ' changed prize'
            with self.assertRaises(ValueError):
                self.result(f)

    def test_changed_html_text_or_image_order_rejected(self):
        for old, new in [('250,000', '500,000'), ('1401-10x-symbol', '1401-50x-symbol')]:
            f = copy.deepcopy(self.fixture)
            f['dom']['html'] = f['dom']['html'].replace(old, new)
            with self.assertRaises(ValueError):
                self.result(f)

    def test_missing_extra_or_blank_labels_rejected(self):
        for mode in ('missing', 'extra', 'blank'):
            f = copy.deepcopy(self.fixture)
            if mode == 'missing':
                f['review']['symbols'].pop()
            elif mode == 'extra':
                f['review']['symbols'].append(f['review']['symbols'][0])
            else:
                f['review']['symbols'][0]['visualLabel'] = ''
            with self.assertRaises(ValueError):
                self.result(f)

    def test_incomplete_or_unexpected_manifest_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder) / 'reviewed-symbols.json'
            path.write_text('[]')
            with self.assertRaises(ValueError):
                load_reviews(folder, {'scratchers': [self.fixture['product']]})
            path.write_text(json.dumps([self.fixture['review']]))
            with self.assertRaises(ValueError):
                load_reviews(folder, {})

    def test_corrupt_evidence_rejected(self):
        with tempfile.TemporaryDirectory() as folder:
            path = Path(folder)
            (path / 'reviewed-symbols.json').write_text(json.dumps([self.fixture['review']]))
            (path / '1401-dom.json').write_text('{}')
            with self.assertRaisesRegex(ValueError, 'evidence changed'):
                load_reviews(folder, {'scratchers': [self.fixture['product']]})
