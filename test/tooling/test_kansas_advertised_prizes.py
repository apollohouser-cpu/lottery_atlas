import json
from pathlib import Path
import unittest
from tooling.kansas_advertised_prizes import parse_advertised_prizes

FIXTURE = Path(__file__).parents[1] / 'fixtures/kansas/advertised-games.json'
NOW = '2026-10-15T08:45:00Z'


class KansasAdvertisedTests(unittest.TestCase):
    def source(self):
        return json.loads(FIXTURE.read_text())

    def test_direct_amounts_and_date_provenance(self):
        result = parse_advertised_prizes(self.source(), NOW)
        self.assertEqual(4, len(result))
        pb, la, skc, mm = result
        self.assertEqual(562000000, pb['advertisedAnnuityDollars'])
        self.assertEqual(230400000, pb['advertisedCashDollars'])
        self.assertEqual('2026-10-14', pb['drawDate'])
        self.assertEqual('2026-10-15', pb['sourceDrawingDate'])
        self.assertTrue(pb['sourceDrawTimeHasPassed'])
        self.assertFalse(mm['sourceDrawTimeHasPassed'])
        self.assertIsNone(skc['advertisedAnnuityDollars'])
        self.assertEqual(1375000, skc['advertisedCashDollars'])

    def test_lifetime_fixed_historical_products_not_misrepresented(self):
        result = parse_advertised_prizes(self.source(), NOW)
        self.assertEqual({'powerball', 'lotto-america', 'super-kansas-cash', 'megamillions'}, {r['scheduleKey'] for r in result})
        self.assertNotIn('winnerCount', json.dumps(result))

    def test_incomplete_ambiguous_and_bad_fields_reject(self):
        changes = [lambda x: x.pop(0), lambda x: x.append(x[0].copy()),
                   lambda x: x[0].update(gameKey='historical'),
                   lambda x: x[0].update(nextDrawDate=None),
                   lambda x: x[0].update(nextDrawingDate='2026-10-14'),
                   lambda x: x[0].update(nextCashAmount=True),
                   lambda x: x[0].update(nextCashAmount=-1),
                   lambda x: x[0].update(nextAnnuityAmount=1.5)]
        for change in changes:
            rows=self.source();change(rows)
            with self.assertRaises(ValueError):parse_advertised_prizes(rows,NOW)

    def test_cash_only_placeholder_is_not_an_annuity(self):
        rows=self.source()
        next(r for r in rows if r['gameId']==8)['nextAnnuityAmount']=5
        with self.assertRaises(ValueError):parse_advertised_prizes(rows,NOW)

if __name__ == '__main__':
    unittest.main()
