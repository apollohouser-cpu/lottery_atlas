from datetime import date
import unittest
from tooling.connecticut_state_reports import parse, CONFIG


def source(game):
    keys = list(map(str, range(1, len(CONFIG[game])+1)))
    return dict(game=game, draw=1, drawFound=True,
                counts={k: 0 for k in keys}, amounts={k: 18_000_000 for k in keys})


class ReportTest(unittest.TestCase):
    def parse(self, payload, game):
        return parse(payload, game=game, draw_id=1, draw_date='2026-11-21', observed_date=date(2026,11,22))

    def test_life_values_not_misrepresented_as_cash_or_annual(self):
        rows = self.parse(source('mfl'), 'mfl')['rows']
        self.assertEqual(rows[0]['prizeLabel'], '$1,000,000 a Year for Life')
        self.assertNotIn('reportedPrizeAmount', rows[0])
        self.assertNotIn('reportedPrizeAmount', rows[1])
        self.assertEqual(rows[2]['reportedPrizeAmount'], 18_000_000)

    def test_lotto_source_prize_and_zero_count_preserved(self):
        payload = source('lotto'); payload['amounts']['2'] = 1574
        row = self.parse(payload, 'lotto')['rows'][1]
        self.assertEqual((row['match'],row['reportedPrizeAmount'],row['reportedWinningTickets']), ('5',1574,0))

    def test_changed_tier_identity_or_bad_number_rejected(self):
        for game in CONFIG:
            for mutation in ['tier','game','count','amount']:
                p = source(game)
                if mutation=='tier': del p['counts']['1']
                elif mutation=='game': p['game']='other'
                elif mutation=='count': p['counts']['1']=True
                else: p['amounts']['1']=float('inf')
                with self.assertRaises(ValueError):self.parse(p,game)


if __name__ == '__main__': unittest.main()
