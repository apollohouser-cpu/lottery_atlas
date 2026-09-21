import importlib.util
from datetime import date
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('md', Path(__file__).resolve().parents[2] / 'tooling/import_maryland_scratch_catalog.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)
TODAY = date(2026, 9, 21)


def card(gid='791', deadline=''):
    return f'''<li id="ticket_{gid}">
    <div class="price">$5</div><div class="name">THE BIG SPIN®</div>
    <strong class="gamenumber">Game #{gid}</strong>
    <strong class="topprize">BIG SPIN</strong><strong class="topremaining">0</strong>
    <strong class="launchdate">03/20/2026</strong>
    {f'<strong class="lastclaimdate">{deadline}</strong>' if deadline else ''}
    <table><thead><tr><th>Prize Amount</th><th>Start</th><th>Remaining*</th></tr></thead>
    <tbody><tr><td>BIG SPIN</td><td>8</td><td>0</td></tr>
    <tr><td>$50,000</td><td>3</td><td>1</td></tr>
    <tr><td>$250</td><td>10</td><td>2</td></tr>
    <tr><td>250.00 (SPIN)</td><td>10</td><td>3</td></tr>
    <tr><td>$250 (Digital Spin)</td><td>10</td><td>4</td></tr></tbody></table>
    <p>Records Last Updated: 09/19/2026</p><div class="allremaining">10</div></li>'''


class MarylandTest(unittest.TestCase):
    def test_spin_labels_and_zero_counts_remain_separate(self):
        game = m.parse_catalog(card().encode('utf-8'), TODAY)['games'][0]
        self.assertEqual(game['name'], 'THE BIG SPIN®')
        self.assertEqual(game['topPrizeLabel'], 'BIG SPIN')
        self.assertEqual(game['topPrize'], 50000)
        self.assertEqual(game['topPrizesRemaining'], 0)
        self.assertNotIn('prizeAmount', game['prizeTiers'][0])
        self.assertEqual(len(game['prizeTiers']), 5)
        self.assertEqual(game['sourceDate'], '2026-09-19')

    def test_deadline_day_included_and_next_day_excluded(self):
        raw = '<ul>' + card() + card('731', '09/21/2026') + '</ul>'
        self.assertEqual(len(m.parse_catalog(raw, TODAY)['games']), 2)
        self.assertEqual(len(m.parse_catalog(raw, date(2026, 9, 22))['games']), 1)

    def test_future_launch_excluded(self):
        raw = '<ul>' + card() + card('732').replace('03/20/2026', '09/22/2026') + '</ul>'
        self.assertEqual(len(m.parse_catalog(raw, TODAY)['games']), 1)

    def test_inconsistent_inventory_and_identity_rejected(self):
        for raw in [card().replace('class="allremaining">10', 'class="allremaining">11'),
                    card().replace('<td>3</td><td>1', '<td>0</td><td>1'),
                    card().replace('Game #791', 'Game #123'),
                    card().replace('class="topremaining">0', 'class="topremaining">1'),
                    '<ul>' + card() + card() + '</ul>']:
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                m.parse_catalog(raw, TODAY)

    def test_changed_schema_dates_and_prize_labels_rejected(self):
        for raw in [card().replace('Remaining*', 'Claimed'),
                    card().replace('09/19/2026', '09/22/2026'),
                    card().replace('250.00 (SPIN)', 'MYSTERY'),
                    card().replace('250.00 (SPIN)', '$250'),
                    card().replace('Records Last Updated:', 'Retrieved:'),
                    card().replace('<td>4</td>', '<td>-4</td>')]:
            with self.subTest(raw=raw), self.assertRaises(ValueError):
                m.parse_catalog(raw, TODAY)


if __name__ == '__main__':
    unittest.main()
