import importlib.util,json
from pathlib import Path
import unittest
spec=importlib.util.spec_from_file_location('sd',Path(__file__).resolve().parents[2]/'tooling/import_south_dakota_scratch_catalog.py');m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
GAME=dict(id='1197',name='PLINKO',cost=10,slug='plinko')
def inventory():return dict(gameId='1197',validationStatus='ACTIVE',ticketPrice=1000,prizeTiers=[dict(tierNumber=2,prizeAmount=7500000,winningTickets=2,paidTickets=0),dict(tierNumber=1,prizeAmount=1000,winningTickets=100,paidTickets=20)])
def listing(options=('active',)):
    g=dict(acf=dict(igtIdentifier='1197'),title='PLINKO',slug='plinko',gameTypes=dict(nodes=[dict(slug='scratch-tickets')]),gamePrices=dict(nodes=[dict(slug='10')]),gameOptions=dict(edges=[dict(node=dict(slug=o)) for o in options]))
    root={'props': {'pageProps': {'post': {'blocks': [{'attributes': {'games': [{'node': g}]}}]}}}}
    return '<script id="__NEXT_DATA__">'+json.dumps(root)+'</script>'
class SouthDakotaTest(unittest.TestCase):
    def test_cents_conversion_and_unsorted_top_tier(self):
        g=m.parse_inventory(json.dumps(inventory()),GAME)
        self.assertEqual(g['topPrize'],75000);self.assertEqual(g['topPrizesRemaining'],2)
        self.assertEqual(g['prizeTiers'][1]['remaining'],80)
    def test_active_subset_and_conflicting_status(self):
        games,n=m.parse_listing(listing());self.assertEqual(games,[GAME]);self.assertEqual(n,1)
        for options in [('closed',),('active','upcoming')]:
            with self.subTest(options=options),self.assertRaises(ValueError):m.parse_listing(listing(options))
    def test_inventory_identity_status_price(self):
        for key,value in [('gameId','999'),('validationStatus','CLOSED'),('ticketPrice',10)]:
            d=inventory();d[key]=value
            with self.subTest(key=key),self.assertRaises(ValueError):m.parse_inventory(json.dumps(d),GAME)
    def test_missing_negative_and_impossible_counts(self):
        for value in [None,-1,True,3]:
            d=inventory();d['prizeTiers'][0]['paidTickets']=value
            with self.subTest(value=value),self.assertRaises(ValueError):m.parse_inventory(json.dumps(d),GAME)
    def test_duplicate_tier_rejected(self):
        d=inventory();d['prizeTiers'].append(d['prizeTiers'][0])
        with self.assertRaises(ValueError):m.parse_inventory(json.dumps(d),GAME)
if __name__=='__main__':unittest.main()
