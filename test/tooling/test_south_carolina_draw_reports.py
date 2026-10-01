import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('sc_draw', Path(__file__).parents[2] / 'tooling/south_carolina_draw_reports.py')
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)


def fixture():
    headers = ['Match', 'Base Prize (For Reference Only)', 'Prize Amount', 'Prize Winners']
    rows = ''.join(f'<tr><td>Tier {i}</td><td>$5</td><td>$10 - $50</td><td>1</td></tr>' for i in range(9))
    return '<div class="drawResultsaccordion"><span>9/29/2026</span><table><tr>' + ''.join(f'<th>{h}</th>' for h in headers) + '</tr>' + rows + '<tr><td colspan="3">Total Prize Winners</td><td>9</td></tr></table>This table represents September 29, 2026, South Carolina winners ONLY.'


class DrawReportsTest(unittest.TestCase):
    def test_ranges_do_not_become_payouts(self):
        report = module.parse_mega_millions(fixture())[0]
        self.assertEqual(report['reportedWinners'], 9)
        self.assertIsNone(report['reportedPayout'])
        self.assertIsNone(report['sourcePublicationDate'])
        self.assertEqual(report['tiers'][0][2], '$10 - $50')

    def test_total_mismatch_rejected(self):
        with self.assertRaises(ValueError):
            module.parse_mega_millions(fixture().replace('<td>9</td>', '<td>10</td>'))

    def test_scope_date_mismatch_rejected(self):
        with self.assertRaises(ValueError):
            module.parse_mega_millions(fixture().replace('September 29', 'September 28'))

    def test_duplicate_draw_rejected(self):
        with self.assertRaises(ValueError):
            module.parse_mega_millions(fixture() * 2)

    def test_duplicate_tier_rejected(self):
        with self.assertRaises(ValueError):
            module.parse_mega_millions(fixture().replace('Tier 8', 'Tier 7'))

    def test_negative_count_rejected(self):
        with self.assertRaises(ValueError):
            module.parse_mega_millions(fixture().replace('<td>1</td>', '<td>-1</td>'))


if __name__ == '__main__':
    unittest.main()
