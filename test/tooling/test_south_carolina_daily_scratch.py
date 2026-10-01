import importlib.util
import unittest
from pathlib import Path

spec = importlib.util.spec_from_file_location('sc_daily', Path(__file__).parents[2] / 'tooling/import_south_carolina_daily_scratch.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def page(tables):
    return '<h1>Daily Scratch-Off Winners for September 29, 2026</h1>Last Update on <strong>09/30/2026 10:00:03 AM</strong>' + tables


def table(count=2, payout=1000):
    return f'<strong>Daily Scratch-Off Winners for SAME TITLE</strong><tr><td data-th="Prize Amount">$500</td><td data-th="Number of Winners">{count}</td><td data-th="Total Prizes">${payout}</td></tr><strong>End of Daily Scratch-Offs Winners for SAME TITLE</strong>'


class DailyScratchTest(unittest.TestCase):
    def test_claim_day_and_publication_are_distinct(self):
        result = module.parse(page(table()))
        self.assertEqual(result['claimDate'], '2026-09-29')
        self.assertEqual(result['updatedAt'], '2026-09-30T10:00:03-04:00')

    def test_duplicate_titles_preserve_counts(self):
        game = module.parse(page(table() + table(3, 1500)))['games'][0]
        self.assertEqual(game['groupedOfficialEntries'], 2)
        self.assertEqual(game['prizeTiers'], [{'amount': 500, 'claimedYesterday': 5}])

    def test_bad_payout_rejected(self):
        with self.assertRaises(ValueError):
            module.parse(page(table(2, 999)))

    def test_missing_boundary_rejected(self):
        with self.assertRaises(ValueError):
            module.parse(page(table().replace('Daily Scratch-Off Winners for SAME', 'Missing SAME')))

    def test_missing_date_rejected(self):
        with self.assertRaises(ValueError):
            module.parse(table())


if __name__ == '__main__':
    unittest.main()
