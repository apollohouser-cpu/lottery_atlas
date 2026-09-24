import importlib.util,json
from datetime import date
from pathlib import Path
import unittest
spec=importlib.util.spec_from_file_location('ok',Path(__file__).resolve().parents[2]/'tooling/import_oklahoma_scratch_catalog.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
GAME=dict(gameId=95,gameNumber='842',slug='842-all-the-luck',ticketPrice=20,topPrize=200000,startDate='2026-05-21T00:00:00-05:00',endDate=None,pullTab=False,title='All the Luck')
def page(key,value):return '<script>self.__next_f.push('+json.dumps([1,'1:'+json.dumps({key:value})])+')</script>'
def detail():return dict(GAME,claimEndDate=None,totalTickets=725040,prizeDetails=[dict(matches=[dict(prize='$$20',remainingPrizes=100,totalPrizes=200),dict(prize='$$200,000',remainingPrizes=0,totalPrizes=3)])])
class OklahomaTest(unittest.TestCase):
    def test_printed_id_cash_and_zero(self):
        g=m.parse_detail(page('cms',detail()),GAME)
        self.assertEqual(g['id'],'842');self.assertEqual(g['internalGameId'],95)
        self.assertEqual(g['topPrizesRemaining'],0);self.assertEqual(g['prizeTiers'][0]['prizeAmount'],20)
    def test_ended_and_future_excluded(self):
        other=dict(GAME,gameId=96,gameNumber='999',slug='ended',endDate='2026-06-01T00:00:00-05:00')
        games,total=m.parse_listing(page('scratchOffs',[GAME,other]),date(2026,9,20));self.assertEqual(games,[GAME]);self.assertEqual(total,2)
        with self.assertRaises(ValueError):m.parse_listing(page('scratchOffs',[GAME]),date(2026,1,1))
    def test_duplicate_identity_rejected(self):
        with self.assertRaises(ValueError):m.parse_listing(page('scratchOffs',[GAME,GAME]),date(2026,9,20))
    def test_missing_impossible_count(self):
        for value in [None,-1,True,4]:
            d=detail();d['prizeDetails'][0]['matches'][1]['remainingPrizes']=value
            with self.subTest(value=value),self.assertRaises(ValueError):m.parse_detail(page('cms',d),GAME)
    def test_detail_mismatch_deadline_duplicate_tier(self):
        for key,value in [('ticketPrice',10),('claimEndDate','2026-12-01'),('gameNumber','95')]:
            d=detail();d[key]=value
            with self.subTest(key=key),self.assertRaises(ValueError):m.parse_detail(page('cms',d),GAME)
        d=detail();d['prizeDetails'][0]['matches'].append(d['prizeDetails'][0]['matches'][0])
        with self.assertRaises(ValueError):m.parse_detail(page('cms',d),GAME)
    def test_explicit_null_inventory_is_unknown(self):
        d=detail();d['prizeDetails']=None
        g=m.parse_detail(page('cms',d),GAME)
        self.assertIsNone(g['topPrizesRemaining']);self.assertEqual(g['prizeTiers'],[])
        self.assertIn('unknown',g['inventoryNote']);self.assertEqual(g['topPrize'],200000)
    def test_missing_and_malformed_structure_still_fail(self):
        for value in [[],{},[{},{}],[{'matches':[]}]]:
            d=detail();d['prizeDetails']=value
            with self.subTest(value=value),self.assertRaises(ValueError):m.parse_detail(page('cms',d),GAME)
        d=detail();del d['prizeDetails']
        with self.assertRaises(ValueError):m.parse_detail(page('cms',d),GAME)
    def test_mass_inventory_loss_stops_publication(self):
        with self.assertRaises(ValueError):m.validate_inventory_coverage([{'prizeTiers':[]}]*50)
        with self.assertRaises(ValueError):m.validate_inventory_coverage([{'prizeTiers':[1]}]*19)
        m.validate_inventory_coverage([{'prizeTiers':[1]}]*20+[{'prizeTiers':[]}]*6)
if __name__=='__main__':unittest.main()
