import copy
from datetime import date
from pathlib import Path
import unittest

from tooling.nebraska_draw_collection import assemble_collection
from tooling.nebraska_draw_results import SPECS

FIXTURES = Path(__file__).parents[1] / 'fixtures' / 'nebraska'


class CollectionTest(unittest.TestCase):
    def setUp(self):
        self.pages = {family: (FIXTURES / (groups[0][0] + '.html')).read_text()
                      for family, groups in SPECS.items()}
        self.today = date(2026, 10, 16)

    def collect(self, **kwargs):
        return assemble_collection(self.pages, today=self.today, **kwargs)

    def test_complete_collection_keeps_reports_separate(self):
        result = self.collect()
        self.assertEqual(len(result['results']), 22)
        self.assertEqual(len(result['familyReports']), 10)
        self.assertEqual(len({r['group'] for r in result['results']}), 11)
        self.assertTrue(all('tiers' not in r and 'sourceWinners' not in r
                            for r in result['results']))
        self.assertEqual(self.collect(previous=result), result)

    def test_missing_extra_and_corrupt_family_fail_without_mutating_baseline(self):
        baseline = self.collect()
        original = copy.deepcopy(baseline)
        for family in SPECS:
            with self.subTest(family=family):
                raw = self.pages.pop(family)
                with self.assertRaises(ValueError):
                    self.collect(previous=baseline)
                self.pages[family] = '<html>unavailable</html>'
                with self.assertRaises(ValueError):
                    self.collect(previous=baseline)
                self.pages[family] = raw
        self.pages['unexpected'] = ''
        with self.assertRaises(ValueError):
            self.collect(previous=baseline)
        self.assertEqual(baseline, original)

    def test_result_and_report_date_regression_rejected(self):
        for section in ('result', 'report'):
            baseline = self.collect()
            if section == 'result':
                baseline['results'][0]['drawDate'] = '2026-10-17'
            else:
                baseline['familyReports'][0]['reports'][0]['drawDate'] = '2026-10-17'
            with self.subTest(section=section), self.assertRaises(ValueError):
                self.collect(previous=baseline)

    def test_prior_variant_loss_rejected(self):
        baseline = self.collect()
        baseline['familyReports'][0]['reports'].append(
            dict(variant='unexpected-prior-variant', drawDate='2026-10-14'))
        with self.assertRaises(ValueError):
            self.collect(previous=baseline)


if __name__ == '__main__':
    unittest.main()
