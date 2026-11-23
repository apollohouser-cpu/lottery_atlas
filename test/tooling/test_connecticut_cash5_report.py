from datetime import date
import unittest
from tooling.connecticut_cash5_report import parse


def source():
    return dict(game='cash5', draw=11257, drawFound=True,
        counts=dict(zip(map(str, range(1, 8)), [0, 19, 661, 0, 36, 489, 1861])),
        amounts=dict(zip(map(str, range(1, 8)), [100000, 300, 10, 4350, 65, 5, 2])))


class Cash5Test(unittest.TestCase):
    def parse(self, payload):
        return parse(payload, draw_id=11257, draw_date='2026-11-21', observed_date=date(2026, 11, 22))

    def test_literal_kicker_prizes_and_zeroes_preserved_without_total(self):
        report = self.parse(source())
        self.assertEqual(report['rows'][3], dict(sourceTier='4', match='4 + Kicker',
            reportedWinningTickets=0, reportedPrizeAmount=4350))
        self.assertEqual(report['rows'][4]['reportedPrizeAmount'], 65)
        self.assertNotIn('total', report)

    def test_missing_or_unknown_tiers_rejected(self):
        for kind in ['counts', 'amounts']:
            p = source(); del p[kind]['1']
            with self.assertRaises(ValueError): self.parse(p)
            p = source(); p[kind]['8'] = 1
            with self.assertRaises(ValueError): self.parse(p)

    def test_invalid_numbers_rejected(self):
        for kind, value in [('counts', True), ('counts', -1), ('counts', 1.5),
                            ('amounts', float('nan')), ('amounts', float('inf')), ('amounts', -1)]:
            p = source(); p[kind]['1'] = value
            with self.assertRaises(ValueError): self.parse(p)

    def test_wrong_or_not_found_draw_rejected(self):
        for key, value in [('draw', 11258), ('game', 'lotto'), ('drawFound', False)]:
            p = source(); p[key] = value
            with self.assertRaises(ValueError): self.parse(p)


if __name__ == '__main__': unittest.main()
