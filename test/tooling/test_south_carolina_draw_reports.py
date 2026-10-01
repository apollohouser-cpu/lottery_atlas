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

class AdditionalDrawReportsTest(unittest.TestCase):
    def table(self, headers, labels, counts, total):
        rows = ''.join('<tr>' + ''.join('<td>' + str(v) + '</td>' for v in [label, '$500', *values]) + '</tr>' for label, values in zip(labels, counts))
        return '<table class="small-table"><tr>' + ''.join('<th>' + h + '</th>' for h in headers) + '</tr>' + rows + '<tr>' + ''.join('<td>' + str(v) + '</td>' for v in ['Total Winning Tickets', '', *total]) + '</tr></table>'

    def test_xo_preserves_historical_tier_amounts(self):
        table = self.table(['Match', 'Powerball Xs & 0s™ Prizes', 'Total Winners'], ['Jackpot (Match 8)', 'Match 7', 'Match 6', 'Match 5', 'Match 4'], [[0], [1], [2], [3], [4]], [10])
        raw = '<div class="drawResultsaccordion"><span class="">9/27/2026</span>' + table + 'This table represents September 27, 2026, South Carolina winners ONLY'
        report = module.parse_powerball_xo(raw)[0]
        self.assertEqual(report['reportedWinners'], 10)
        self.assertEqual(report['tiers'][1][1], '$500')
        self.assertIsNone(report['reportedPayout'])
        with self.assertRaises(ValueError):
            module.parse_powerball_xo(raw.replace('<td>10</td>', '<td>11</td>'))

    def test_palmetto_columns_are_not_added(self):
        table = self.table(['Match', 'Prizes', 'Winners', 'Total'], ['Match 5', 'Match 4', 'Match 3', 'Match 2'], [[0, 0], [1, 1], [2, 2], [3, 3]], [6, 6])
        raw = '<div class="text-center lightblue-bg">September 30, 2026</div>' + table
        report = module.parse_palmetto(raw)[0]
        self.assertEqual(report['reportedWinners'], 6)
        self.assertIsNone(report['reportedPayout'])
        with self.assertRaises(ValueError):
            module.parse_palmetto(raw.replace('<td>6</td>', '<td>7</td>'))
