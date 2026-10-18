from pathlib import Path
import unittest
from lxml import html
from tooling.nebraska_draw_results import SPECS
from tooling.nebraska_regular_schedules import FAMILIES, parse_regular_schedule

FIXTURES = Path(__file__).parents[1] / 'fixtures' / 'nebraska'


class RegularSchedulesTest(unittest.TestCase):
    def raw(self, family):
        return (FIXTURES / (SPECS[family][0][0] + '.html')).read_text()

    def test_all_six_preserve_rules(self):
        for family in FAMILIES:
            with self.subTest(family=family):
                blocks = parse_regular_schedule(self.raw(family), family)
                self.assertGreater(len(blocks), 10)
                self.assertFalse(any('sourceWinners' in b for b in blocks))

    def test_annuity_cash_options_are_distinct_literal_values(self):
        blocks = parse_regular_schedule(self.raw('Millionaire for Life'), 'Millionaire for Life')
        table = next(b for b in blocks if b['kind'] == 'table')
        self.assertEqual(table['rows'], [['$1,000,000 a year for life', '$18,000,000.00'],
                                       ['$100,000 a year for life', '$2,200,000.00']])
        self.assertTrue(any('minimum of 20 years' in b.get('text', '') for b in blocks))

    def test_removed_qualification_or_changed_payout_fails(self):
        for family, old, new in [('Millionaire for Life', 'minimum of 20 years', 'minimum of 10 years'),
                                 ('Pick 4', '$6,000', '$7,000'),
                                 ('Pick 3', '$126', '$125')]:
            raw = self.raw(family)
            self.assertIn(old, raw)
            with self.subTest(family=family), self.assertRaises(ValueError):
                parse_regular_schedule(raw.replace(old, new), family)

    def test_duplicate_missing_or_shifted_table_fails(self):
        raw = self.raw('Pick 4')
        tree = html.fromstring(raw)
        root = tree.xpath('//*[contains(concat(" ",normalize-space(@class)," ")," ld_left ")]')[0]
        table = root.xpath('.//table')[0]
        table.xpath('.//td')[0].getparent().remove(table.xpath('.//td')[0])
        with self.assertRaises(ValueError):
            parse_regular_schedule(html.tostring(tree), 'Pick 4')
        with self.assertRaises(ValueError):
            parse_regular_schedule('<html></html>', 'Pick 4')
        with self.assertRaises(ValueError):
            parse_regular_schedule(raw + raw, 'Pick 4')
