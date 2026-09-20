import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location('washington', Path(__file__).resolve().parents[2] / 'tooling/import_washington_scratch_catalog.py')
m = importlib.util.module_from_spec(spec)
spec.loader.exec_module(m)

def page(label='$40,000/yr/25 years', paid='5', remaining='0', date='9/19/2026 12:30:07 AM', price=20, gid='1780'):
    return f'''<p>Updated: {date}</p><div class="prizes-remaining-item"><header><img alt="Example"><p>${price} | {gid}</p><p>Last Day To Redeem: 10/21/26</p></header><table><tr><th>Prize Amount</th><th>Total Prizes</th><th>Prizes Paid</th><th>Prizes Remaining</th></tr><tr><td>{label}</td><td>5</td><td>{paid}</td><td>{remaining}</td></tr><tr><td>$1,000</td><td>10</td><td>3</td><td>7</td></tr></table></div>'''

class WashingtonTest(unittest.TestCase):
    def test_annuity_is_not_concatenated_digits(self):
        game = m.parse_page(page(), 20)[2][0]
        self.assertEqual(game['topPrize'], 1000000)
        self.assertEqual(game['topPrizeLabel'], '$40,000/yr/25 years')
        self.assertEqual(game['topPrizesRemaining'], 0)
        self.assertEqual(game['lastDayToRedeem'], '2026-10-21')

    def test_special_prize_count_stays_with_special_tier(self):
        for label in ['LIFE', 'BRONCO']:
            with self.subTest(label=label):
                game = m.parse_page(page(label=label, paid='3', remaining='2'), 20)[2][0]
                self.assertEqual((game['topPrizeLabel'], game['topPrize'], game['topPrizesRemaining']), (label, 1000, 2))

    def test_malformed_inventory_is_rejected(self):
        for value in [page(paid='4'), page(paid='-1', remaining='6'), page(label='UNKNOWN'), page().replace('Prizes Paid','Claims'), page()+page()]:
            with self.subTest(value=value):
                with self.assertRaises(ValueError): m.parse_page(value, 20)

    def test_category_must_match(self):
        with self.assertRaises(ValueError): m.parse_page(page(), 10)
        with self.assertRaises(ValueError): m.build_catalog({20: page()})

    def test_all_categories_same_source_date_unique_games(self):
        pages = {p:page(price=p, gid=str(p)) for p in m.PRICES}
        self.assertEqual(len(m.build_catalog(pages)['games']), 7)
        pages[1] = page(price=1, gid='1', date='9/18/2026 12:30:07 AM')
        with self.assertRaises(ValueError): m.build_catalog(pages)
        pages[1] = page(price=1, gid='20')
        with self.assertRaises(ValueError): m.build_catalog(pages)

if __name__ == '__main__': unittest.main()
