from datetime import date
import unittest
from tooling.connecticut_play_reports import parse


def source(game='play3day'):
    return dict(game=game, draw=123, drawFound=True,
                counts={str(n):0 for n in range(1,25 if game.startswith('play3') else 41)})


class PlaysTest(unittest.TestCase):
    def parse(self,p,game='play3day'):
        return parse(p,game=game,draw_id=123,draw_date='2026-11-22',observed_date=date(2026,11,22))

    def test_overlapping_groups_preserved_without_distinct_ticket_total(self):
        p=source();p['counts']['4']=3
        r=self.parse(p)
        self.assertEqual(r['rows'][0]['reportedWinningPlays'],3)
        self.assertEqual(r['rows'][1]['reportedWinningPlays'],3)
        self.assertEqual(r['countLabel'],'Winning Plays')
        self.assertNotIn('total',r)
        self.assertEqual(r['rows'][0]['minimumWagerPrizeLabel'],'$250.00')

    def test_all_four_sessions_have_complete_mapping(self):
        for game,n in [('play3day',14),('play3night',14),('play4day',18),('play4night',18)]:
            r=self.parse(source(game),game)
            self.assertEqual(len(r['rows']),n)
            self.assertEqual(r['session'],'Day' if game.endswith('day') else 'Night')

    def test_wrong_session_missing_tier_or_invalid_count_rejected(self):
        p=source('play3night')
        with self.assertRaises(ValueError):self.parse(p)
        p=source();del p['counts']['24']
        with self.assertRaises(ValueError):self.parse(p)
        for value in [True,-1,1.5]:
            p=source();p['counts']['1']=value
            with self.assertRaises(ValueError):self.parse(p)


if __name__=='__main__':unittest.main()
