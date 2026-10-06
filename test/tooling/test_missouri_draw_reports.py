import sys
from pathlib import Path
import unittest
from html import escape
sys.path.insert(0, str(Path(__file__).resolve().parents[2] / 'tooling'))
from missouri_draw_reports import MM_MATCHES, parse_mega_millions


def fixture():
    prizes = ['Jackpot', '$2,000,000-$10,000,000', '$20,000-$100,000', '$1,000-$5,000', '$400-$2,000', '$20-$100', '$20-$100', '$14-$70', '$10-$50']
    counts = [0, 0, 0, 4, 10, 151, 132, 913, 2399]
    rows = ''.join('<tr><td>'+escape(m)+'</td><td>'+str(c)+'</td><td>'+p+'</td></tr>' for m, c, p in zip(MM_MATCHES, counts, prizes))
    return '<html><div class="block-megamillions-prizes-paid"><div class="content"><div class="h1 text-center">Friday, Oct 02, 2026</div><table><thead><tr><th>Numbers Matched</th><th>Number of MO Prizes</th><th>Prize amount</th></tr></thead><tbody>'+rows+'<tr><td>Grand Total MO Winners:</td><td>3,609</td><td>Grand Total Won:</td><td>$73,798</td><td></td></tr><tr><td>Location(s) of Jackpot Winner(s): N/A</td></tr></tbody></table></div></div></html>'


class ReportTests(unittest.TestCase):
    def test_literal_ranges_and_source_units(self):
        report = parse_mega_millions(fixture(), '2026-10-02')
        self.assertEqual(report['sourceWinnerCount'], 3609)
        self.assertEqual(report['sourcePayoutDollars'], 73798)
        self.assertEqual(report['tiers'][1]['prizeLabel'], '$2,000,000-$10,000,000')
        self.assertTrue(all(t['cashPrize'] is None for t in report['tiers']))
        self.assertIsNone(report['distinctTicketCount'])
        self.assertFalse(report['finalityVerified'])

    def test_reject_partial_wrong_date_identity_and_columns(self):
        for raw in [fixture().replace('</html>', ''), fixture().replace('Oct 02', 'Oct 03'), fixture().replace('Friday', 'Thursday'), fixture().replace('Number of MO Prizes', 'National Prizes'), fixture().replace('5 White balls</td>', '4 White balls</td>'), fixture().replace('<td>2399</td>', '<td></td>')]:
            with self.subTest(raw=raw[-100:]), self.assertRaises(ValueError):
                parse_mega_millions(raw, '2026-10-02')

    def test_reject_inconsistent_totals_or_prize_ranges(self):
        for raw in [fixture().replace('3,609', '3,608'), fixture().replace('$73,798', '$1'), fixture().replace('$14-$70', '$70-$14'), fixture().replace('$14-$70', '$14'), fixture().replace('<td>2399</td>', '<td>-1</td>')]:
            with self.assertRaises(ValueError):
                parse_mega_millions(raw, '2026-10-02')

if __name__ == '__main__': unittest.main()
