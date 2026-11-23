from datetime import date
import unittest
from tooling.connecticut_powerball_report import parse


def source():
    keys = list(map(str, range(1,19)))
    p = dict(game='powerball', draw=1, drawFound=True, counts={k:0 for k in keys},
             amounts={k:100 for k in keys}, multipliers={k:dict(pp_amount=200) for k in keys})
    p['counts']['4']=3; p['multipliers']['4']['powerplay']=2
    return p


class PowerballTest(unittest.TestCase):
    def parse(self, p):
        return parse(p,draw_id=1,draw_date='2026-11-21',observed_date=date(2026,11,22))

    def test_separate_counts_and_double_play(self):
        r=self.parse(source());self.assertEqual(len(r['rows']),9);self.assertEqual(len(r['doublePlayRows']),9)
        self.assertEqual(r['rows'][3]['reportedWinningTickets'],3)
        self.assertEqual(r['rows'][3]['withPowerPlay'],2)
        self.assertIsNone(r['rows'][0]['withPowerPlay'])
        self.assertNotIn('reportedPrizeAmount',r['rows'][0])
        self.assertNotIn('withPowerPlay',r['doublePlayRows'][0])

    def test_invalid_tiers_or_counts_rejected(self):
        p=source();del p['counts']['18']
        with self.assertRaises(ValueError):self.parse(p)
        p=source();p['counts']['1']=True
        with self.assertRaises(ValueError):self.parse(p)

    def test_powerplay_on_double_play_rejected(self):
        p=source();p['multipliers']['10']['powerplay']=0
        with self.assertRaises(ValueError):self.parse(p)


if __name__=='__main__':unittest.main()
