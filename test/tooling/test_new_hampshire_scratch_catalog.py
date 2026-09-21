import copy
from datetime import date
import importlib.util
from pathlib import Path
import unittest
spec=importlib.util.spec_from_file_location('nh',Path(__file__).resolve().parents[2]/'tooling/import_new_hampshire_scratch_catalog.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)

def fixture():
 c=dict(type='scratch',name='Test',configuration={'dataServices':{'gameDataServiceId':'uid'}},price={'priceInCents':500,'priceFormatted':'$5'},topPrizeDisplay='$1,000,000*',startDate='01/01/2026')
 g=dict(gameId='123',salesChannel='RETAIL',ticketCostOptionsInCents=[500])
 state={'cmsGames':{'gamesByDataServiceId':{'uid':c}},'instantGames':{'instantGamesByDataServiceId':{'uid':g}}}
 inv=dict(lastUpdated='2026-09-21T03:06:59.475Z',prizesRemaining=[dict(id='tier',instantGameId='uid',prizeAmountInDollars=1000000,startingCount=4,remainingCount=0,ticketCostOptionsInCents=[500])])
 rows={'123':['123','$5','Test','1/1/2026','9/20/2026','9/21/2026','9/21/2027']}
 return state,inv,rows

class NewHampshireTest(unittest.TestCase):
 def test_zero_annuity_cash_and_utc_date(self):
  c=m.parse_catalog(*fixture(),date(2026,9,21));g=c['games'][0]
  self.assertEqual(g['topPrizesRemaining'],0);self.assertEqual(g['topPrize'],700000)
  self.assertIn('25 years',g['topPrizeLabel']);self.assertEqual(g['sourceDate'],'2026-09-21')
  self.assertIn('not dated',g['inventoryNote'])
 def test_explicit_top_prize_field_without_dollar_sign(self):
  s,i,r=fixture();s['cmsGames']['gamesByDataServiceId']['uid']['topPrizeDisplay']='1,000,000*'
  self.assertEqual(m.parse_catalog(s,i,r,date(2026,9,21))['games'][0]['topPrize'],700000)
 def test_conflicting_starts_preserved_without_normalization(self):
  s,i,r=fixture();r['123'][3]='1/2/2026';g=m.parse_catalog(s,i,r,date(2026,9,21))['games'][0]
  self.assertNotIn('startDate',g);self.assertEqual(g['cmsStartDate'],'2026-01-01');self.assertEqual(g['scheduleOnSaleDate'],'2026-01-02')
 def test_missing_schedule_explicitly_excluded(self):
  s,i,r=fixture();s['cmsGames']['gamesByDataServiceId']['other']=copy.deepcopy(s['cmsGames']['gamesByDataServiceId']['uid']);s['cmsGames']['gamesByDataServiceId']['other']['configuration']['dataServices']['gameDataServiceId']='other'
  s['instantGames']['instantGamesByDataServiceId']['other']={**s['instantGames']['instantGamesByDataServiceId']['uid'],'gameId':'456'}
  i['prizesRemaining'].append({**i['prizesRemaining'][0],'id':'tier2','instantGameId':'other'})
  c=m.parse_catalog(s,i,r,date(2026,9,21));self.assertEqual(c['excludedMissingScheduleIds'],['456']);self.assertEqual(len(c['games']),1);self.assertIn('456',c['games'][0]['inventoryNote'])
 def test_invalid_counts_price_identity_and_timestamps_fail(self):
  for field,value in [('remainingCount',5),('remainingCount',-1),('remainingCount',True),('ticketCostOptionsInCents',[100]),('prizeAmountInDollars',500)]:
   s,i,r=fixture();i['prizesRemaining'][0][field]=value
   with self.subTest(field=field,value=value),self.assertRaises(ValueError):m.parse_catalog(s,i,r,date(2026,9,21))
  s,i,r=fixture();i['prizesRemaining']*=2
  with self.assertRaises(ValueError):m.parse_catalog(s,i,r,date(2026,9,21))
  s,i,r=fixture();i['lastUpdated']='2026-09-21T03:00:00'
  with self.assertRaises(ValueError):m.parse_catalog(s,i,r,date(2026,9,21))
 def test_inclusive_expiration_and_future_launch(self):
  self.assertEqual(len(m.parse_catalog(*fixture(),date(2027,9,21))['games']),1)
  for day in [date(2027,9,22),date(2025,12,31)]:
   with self.assertRaises(ValueError):m.parse_catalog(*fixture(),day)
 def test_schedule_duplicate_mobile_rows_and_invalid_dates(self):
  headers=['Game Number','Price','Game Name','On Sale','Sale End','Close Date','Expiration Date']
  cells=fixture()[2]['123'];row='<tr>'+''.join('<td>'+v+'</td>' for v in cells)+'</tr>'
  raw='<table><tr>'+''.join('<th>'+v+'</th>' for v in headers)+'</tr>'+row+'<tr><td class="table__cell--stacked-header">Game Number</td><td>123</td></tr></table>'
  self.assertEqual(len(m.schedule(raw)),1)
  with self.assertRaises(ValueError):m.schedule(raw.replace('</table>',row+'</table>'))
  with self.assertRaises(ValueError):m.date('7/22026')
  s,i,r=fixture();r['123'][5]='9/19/2026'
  with self.assertRaises(ValueError):m.parse_catalog(s,i,r,date(2026,9,21))

if __name__=='__main__':unittest.main()
