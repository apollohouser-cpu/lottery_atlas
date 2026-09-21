import importlib.util
from datetime import date, datetime
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('me', Path(__file__).resolve().parents[2] / 'tooling/import_maine_scratch_catalog.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
TODAY = date(2026, 9, 21)
STAMP = datetime(2026, 9, 21, 5)
ITEM = dict(price=5, name='Example', url='https://www.maine.gov/tools/whatsnew/index.php?topic=Lottery_Scratch&id=123&v=article')
PAGE = '<p>Maximum Award: $100,000 Game #721 On Sale - July 2, 2026</p>'
HEADERS = ['Price Point', 'Game No.', 'Game Name', 'Percent Unsold', 'Total Unclaimed', 'Top Prize Level(s)', 'Top Prize(s) Unclaimed']


def report(rows):
    return '<p>as of September 21, 2026 5:00 AM</p><table><tr>' + ''.join('<th>'+h+'</th>' for h in HEADERS) + '</tr>' + ''.join('<tr>'+''.join('<td>'+c+'</td>' for c in row)+'</tr>' for row in rows) + '</table>'


class MaineTest(unittest.TestCase):
    def test_report_continuation_and_money_not_ticket_counts(self):
        raw = report([['$5.00', '721', 'Example', '10.5', '$250,000.00', '$100000', '0'], ['', '', '', '', '', '$1000', '2']])
        inventory, stamp = m.report(raw, TODAY)
        self.assertEqual(stamp, STAMP)
        self.assertEqual(len(inventory['721']['tiers']), 2)
        self.assertEqual(m.detail(PAGE, ITEM, inventory, stamp, {}, TODAY)['topPrizesRemaining'], 0)

    def test_colon_launch_date(self):
        game = m.detail(PAGE.replace('On Sale -', 'On Sale:'), ITEM, {}, STAMP, {}, TODAY)
        self.assertEqual(game['startDate'], '2026-07-02')

    def test_missing_top_tier_stays_unknown(self):
        for inventory in [{}, {'721': dict(price=5, tiers=[dict(prizeAmount=1000, remaining=2)])}]:
            game = m.detail(PAGE, ITEM, inventory, STAMP, {}, TODAY)
            self.assertIsNone(game['topPrizesRemaining'])
            self.assertEqual(game['topPrize'], 100000)
            self.assertIn('unknown, not zero', game['inventoryNote'])

    def test_blank_maximum_exclusion_and_unexpected_missing_rejected(self):
        self.assertIsNone(m.detail('<p>Game #725</p>', ITEM, {}, STAMP, {}, TODAY))
        with self.assertRaises(ValueError):
            m.detail('<p>Game #721</p>', ITEM, {}, STAMP, {}, TODAY)

    def test_claim_deadline_inclusive_and_shipment_semantics(self):
        dates = {'721': [(date(2026, 1, 1), TODAY)]}
        game = m.detail(PAGE, ITEM, {}, STAMP, dates, TODAY)
        self.assertIn('retailer sales may continue', game['inventoryNote'])
        self.assertEqual(game['shipmentEndDate'], '2026-01-01')
        self.assertIsNone(m.detail(PAGE, ITEM, {}, STAMP, dates, date(2026, 9, 22)))
        with self.assertRaises(ValueError):
            m.detail(PAGE, ITEM, {}, STAMP, {'721': [(TODAY, date(2026, 1, 1))]}, TODAY)
        self.assertIsNotNone(m.detail(PAGE, ITEM, {}, STAMP, {'468': [(TODAY, date(2026, 1, 1))]}, TODAY))

    def test_report_schema_and_orphan_continuation_rejected(self):
        valid = ['$5.00', '721', 'Example', '10.5', '$250,000.00', '$100000', '2']
        for rows in [[['', '', '', '', '', '$1000', '2']], [valid, valid], [[*valid[:3], '101', *valid[4:]]], [[*valid[:6], '-1']]]:
            with self.subTest(rows=rows), self.assertRaises(ValueError):
                m.report(report(rows), TODAY)
        with self.assertRaises(ValueError):
            m.report(report([valid]).replace('Top Prize(s) Unclaimed', 'Claims'), TODAY)

    def test_price_mismatch_and_unverified_higher_tier_rejected(self):
        for inventory in [{'721': dict(price=10, tiers=[])}, {'721': dict(price=5, tiers=[dict(prizeAmount=200000, remaining=1)])}]:
            with self.subTest(inventory=inventory), self.assertRaises(ValueError):
                m.detail(PAGE, ITEM, inventory, STAMP, {}, TODAY)


if __name__ == '__main__':
    unittest.main()
