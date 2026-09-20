import importlib.util
from pathlib import Path
from datetime import date
import unittest

spec = importlib.util.spec_from_file_location('indiana', Path(__file__).parents[2] / 'tooling/import_indiana_scratch_catalog.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

def fixture(**overrides):
    values = dict(zip(m.FIELDS, ['TEST', '2604', '$75,000', '0', '3', '$5', '09/01/2026', '1 in 4.52']))
    values.update(overrides)
    return '<table class="grid-table"><tbody><tr>' + ''.join(f'<td data-name="{k}">{v}</td>' for k,v in values.items()) + '</tr></tbody></table>'

class IndianaTests(unittest.TestCase):
    def parse(self, raw):
        return m.parse_catalog(raw, date(2026,9,20))
    def test_zero_remaining_and_source_uncertainty(self):
        result = self.parse(fixture())
        self.assertIsNone(result['sourceDate'])
        game = result['games'][0]
        self.assertEqual((game['cost'],game['topPrize'],game['topPrizesRemaining']), (5,75000,0))
        self.assertEqual(game['startDate'], '2026-09-01')
    def test_missing_count_is_not_zero(self):
        for value in ['', '-1', '1.5', 'unknown', '1,00']:
            with self.subTest(value=value), self.assertRaises(ValueError):
                self.parse(fixture(Unclaimed=value))
    def test_impossible_inventory(self):
        with self.assertRaises(ValueError): self.parse(fixture(Unclaimed='4'))
    def test_duplicate_game(self):
        raw=fixture()
        row=raw[raw.index('<tr>'):raw.index('</tr>')+5]
        with self.assertRaises(ValueError): self.parse(raw.replace('</tbody>',row+'</tbody>'))
    def test_future_or_invalid_date(self):
        for value in ['09/21/2026','02/30/2026']:
            with self.subTest(value=value), self.assertRaises(ValueError): self.parse(fixture(ConsumerSalesStartDate=value))
    def test_schema_pagination_and_noncash_fail_closed(self):
        for raw in [fixture().replace('data-name="Odds"','data-name="Changed"'), fixture()+'<div class="grid-pager"><a href="?page=2">Next</a></div>',fixture(TopPrize='LIFE')]:
            with self.subTest(raw=raw), self.assertRaises(ValueError): self.parse(raw)

if __name__ == '__main__': unittest.main()
