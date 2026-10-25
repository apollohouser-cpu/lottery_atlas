from datetime import date
import json
from pathlib import Path
import sys
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[2]/'tooling'))
import import_oklahoma_fast_play as m

GAME = dict(gameId=8, title='Example Progressive', slug='254-example-progressive',
            ticketPrice=30, topPrize=590000, progressive=True,
            startDate='2026-06-04T00:00:00-05:00', endDate=None)

def page(key, value):
    return '<script>self.__next_f.push('+json.dumps([1, '1:'+json.dumps({key:value})])+')</script>'

def detail():
    return dict(GAME, gameNumber='254', totalTickets=500000, prizeDetails=[dict(matches=[
        dict(prize='$$1,000', remainingPrizes=0, totalPrizes=20),
        dict(prize='JACKPOT', remainingPrizes=3, totalPrizes=3)])])

class FastPlayTest(unittest.TestCase):
    def test_unprefixed_slug_uses_detail_printed_number(self):
        game=dict(GAME,slug='mega-bucks-progressive')
        d=detail();d['slug']=game['slug']
        selected,_=m.parse_listing(page('fastPlayGames',[game]),date(2026,10,25))
        self.assertEqual(m.parse_detail(page('cms',d),selected[0])['id'],'254')

    def test_estimate_never_becomes_tier(self):
        d=detail();d['topPrize']=600000
        g=m.parse_detail(page('cms',d),GAME)
        self.assertEqual(g['progressiveEstimate'],600000)
        self.assertIsNone(g['prizeTiers'][1]['prizeAmount'])
        self.assertEqual(g['prizeTiers'][0]['remainingPrizes'],0)
        self.assertEqual(g['id'],'254');self.assertEqual(g['internalGameId'],8)
    def test_zero_estimate_unavailable(self):
        d=detail();d['topPrize']=0
        self.assertIsNone(m.parse_detail(page('cms',d),GAME)['progressiveEstimate'])
    def test_explicit_null_distinct_from_missing(self):
        d=detail();d['prizeDetails']=None
        self.assertEqual(m.parse_detail(page('cms',d),GAME)['inventoryStatus'],'unavailable')
        del d['prizeDetails']
        with self.assertRaises(ValueError):m.parse_detail(page('cms',d),GAME)
    def test_identity_and_status_fail_closed(self):
        for key,value in [('gameNumber','8'),('title','Other'),('gameId',True),('ticketPrice',3),('endDate','2026-10-01T00:00:00Z'),('progressive',False)]:
            d=detail();d[key]=value
            with self.subTest(key=key),self.assertRaises(ValueError):m.parse_detail(page('cms',d),GAME)
    def test_counts_reject_missing_bool_negative_overflow(self):
        for value in [None,True,-1,4,1.5]:
            d=detail();d['prizeDetails'][0]['matches'][1]['remainingPrizes']=value
            with self.subTest(value=value),self.assertRaises(ValueError):m.parse_detail(page('cms',d),GAME)
    def test_duplicate_numeric_aliases(self):
        d=detail();d['prizeDetails'][0]['matches'].append(dict(prize='$$1000',remainingPrizes=1,totalPrizes=2))
        with self.assertRaises(ValueError):m.parse_detail(page('cms',d),GAME)
    def test_bad_structure_and_jackpot_loss(self):
        for value in [[],{},[{}],[{'matches':[]}],[{},{}]]:
            d=detail();d['prizeDetails']=value
            with self.subTest(value=value),self.assertRaises(ValueError):m.parse_detail(page('cms',d),GAME)
        d=detail();d['prizeDetails'][0]['matches'].pop()
        with self.assertRaises(ValueError):m.parse_detail(page('cms',d),GAME)
    def test_listing_eligibility_local_date(self):
        ended=dict(GAME,gameId=9,slug='255-ended',endDate='2026-07-01T00:00:00Z')
        future=dict(GAME,gameId=10,slug='256-future',startDate='2027-01-01T00:00:00Z')
        local=dict(GAME,gameId=11,slug='257-local',startDate='2026-10-26T01:00:00Z')
        games,total=m.parse_listing(page('fastPlayGames',[GAME,ended,future,local]),date(2026,10,25))
        self.assertEqual(len(games),2);self.assertEqual(total,4)
    def test_new_active_contract_and_duplicate_fail(self):
        for games in [[GAME,GAME],[dict(GAME,progressive=False)],[dict(GAME,startDate='2026-01-01')],[dict(GAME,gameId=True)]]:
            with self.subTest(games=games),self.assertRaises(ValueError):m.parse_listing(page('fastPlayGames',games),date(2026,10,25))

if __name__=='__main__':unittest.main()
