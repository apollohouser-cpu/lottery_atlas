import importlib.util
from datetime import date
from pathlib import Path
import json
import unittest

spec = importlib.util.spec_from_file_location('ct', Path(__file__).resolve().parents[2] / 'tooling/import_connecticut_scratch_catalog.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
TODAY = date(2026, 9, 21)
GAME = dict(gameNo=1860, gameName='Example', displayNameHtml='<p>Example</p>', ticketCostRaw=30,
            topPrizeRaw=1500000, topPrize='$$1,500,000', displayTopPrize='$$2,000,000',
            status='active', startDate='2026-04-15', stopDate='2099-12-31', endValDate='2099-12-30',
            totalTopPrizes=3, topPrizesRemaining=2)


def page():
    return '''<p>Game # 1860 Active Top Prize $2,000,000 Price $30 Overall Odds 1 in 3.54
    Game Start Apr. 15, 2026 Game End TBD Last Day to Claim TBD Total Tickets 100
    How to Play Top prize paid as an annuity or one-time gross cash option of $1,500,000.
    Prizes Remaining As of September 20, 2026</p>
    <table class="scratch-prizes-table"><thead><tr><th>Prize Amount</th><th>Total Prizes</th><th>Unclaimed Prizes</th></tr></thead>
    <tbody><tr><td>$2,000,000</td><td>3</td><td>0</td></tr><tr><td>$30</td><td>100</td><td>10</td></tr></tbody></table>'''


class ConnecticutTest(unittest.TestCase):
    def test_detail_dated_count_and_cash_option(self):
        game = m.detail(page(), GAME, TODAY)
        self.assertEqual(game['topPrize'], 1500000)
        self.assertEqual(game['topPrizeLabel'], '$2,000,000 annuity')
        self.assertEqual(game['topPrizesRemaining'], 0)
        self.assertEqual(game['sourceDate'], '2026-09-20')
        self.assertNotIn('lastDayToRedeem', game)
        self.assertNotIn('endDate', game)
        self.assertIn('game 1725', game['inventoryNote'])

    def test_disputed_game_excluded(self):
        self.assertIsNone(m.detail('', {**GAME, 'gameNo': 1725}, TODAY))

    def test_conflicting_cash_identity_price_inventory_fail(self):
        for raw in [page().replace('cash option of $1,500,000', 'cash option of $1,400,000'),
                    page().replace('Game # 1860', 'Game # 1861'),
                    page().replace('Price $30', 'Price $20'),
                    page().replace('<td>0</td>', '<td>4</td>'),
                    page().replace('September 20, 2026', 'September 22, 2026')]:
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                m.detail(raw, GAME, TODAY)

    def test_ended_claim_date_inclusive_then_excluded(self):
        game = {**GAME, 'status': 'ended', 'stopDate': '2026-09-01', 'endValDate': '2026-09-21'}
        raw = page().replace('Active', 'Ended').replace('Game End TBD', 'Game End Sep. 1, 2026').replace('Last Day to Claim TBD', 'Last Day to Claim Sep. 21, 2026')
        result = m.detail(raw, game, TODAY)
        self.assertIn('Sales ended 2026-09-01', result['inventoryNote'])
        self.assertIsNone(m.detail(raw, game, date(2026, 9, 22)))

    def test_missing_display_name_uses_source_name(self):
        self.assertEqual(m.detail(page(), {**GAME, 'displayNameHtml': None}, TODAY)['name'], 'Example')

    def test_listing_duplicate_and_changed_status_rejected(self):
        def wrap(games):
            return '<script>self.__next_f.push(' + json.dumps([1, '1:' + json.dumps({'games': games}, separators=(',', ':'))]) + ')</script>'
        self.assertEqual(len(m.listing(wrap([GAME]))), 1)
        for rows in [[GAME, GAME], [{**GAME, 'status': 'unknown'}], [{**GAME, 'ticketCostRaw': -1}]]:
            with self.subTest(rows=rows), self.assertRaises(ValueError):
                m.listing(wrap(rows))


if __name__ == '__main__':
    unittest.main()
