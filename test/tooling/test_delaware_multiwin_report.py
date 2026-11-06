from datetime import date
from pathlib import Path
import unittest
from tooling.delaware_multiwin_report import SOURCE, parse

RAW = (Path(__file__).parents[1] / 'fixtures/delaware/multiwin_report.html').read_text()


class MultiWinReportTest(unittest.TestCase):
    def parse(self, raw=RAW, **kwargs):
        return parse(raw, source_url=kwargs.get('source_url', SOURCE),
                     observed_date=kwargs.get('observed_date', date(2026, 11, 6)))

    def test_observed_categories_keep_distinct_six_number_groups(self):
        result = self.parse()
        self.assertEqual(len(result['rows']), 10)
        first = result['rows'][0]
        self.assertEqual(first['drawDate'], '2026-11-05')
        six = [c for c in first['categories'] if c['label'] == '6N']
        self.assertEqual([(c['group'], c['publishedCount']) for c in six],
                         [('Win in A Line', 0), ('Combination Win', 487)])
        self.assertNotIn('total', first)

    def test_wrong_source_and_title_rejected(self):
        with self.assertRaises(ValueError):
            self.parse(source_url=SOURCE + '/other')
        with self.assertRaises(ValueError):
            self.parse(RAW.replace('Number Of Winners - Multi Win Lotto', 'Other report'))

    def test_group_and_row_contracts_rejected(self):
        for before, after in [('colspan="4"', 'colspan="5"'),
                              ('data-label="10+N"', 'data-label="9N"'),
                              ('>1468<', '>-1<'), ('>1468<', '><')]:
            with self.subTest(before=before), self.assertRaises(ValueError):
                self.parse(RAW.replace(before, after, 1))

    def test_future_duplicate_and_reordered_dates_rejected(self):
        with self.assertRaises(ValueError):
            self.parse(observed_date=date(2026, 11, 4))
        for replacement in ['11/05/2026', '11/06/2026']:
            with self.subTest(replacement=replacement), self.assertRaises(ValueError):
                self.parse(RAW.replace('11/04/2026', replacement))


if __name__ == '__main__':
    unittest.main()
