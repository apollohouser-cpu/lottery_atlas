from datetime import datetime, timezone
import json
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[2]/'tooling'))
import import_oklahoma_draws as m
NOW = datetime(2026,10,25,7,tzinfo=timezone.utc)
def record(slug):
    gid,count,low,high,special=m.CONTRACTS[slug]
    balls=[dict(data=low+i,type='NORMAL',order=i) for i in range(count)]
    if special:balls.append(dict(data=1,type='SPECIAL',order=count))
    return dict(id=1,gameId=gid,drawDateTimeUTC='2026-10-24T02:00:00Z',drawingDateUTC='2026-10-24',jackpotStatus='COMPLETE',resultData=balls,prizeTiers=[{'unverified':'never export'}],multiplier=2 if slug in ('powerball','lotto-america') else None)
def cms(slug):
    gid=m.CONTRACTS[slug][0];r=record(slug)
    if slug=='powerball':
        nested=record(slug);nested.update(id=2,multiplier=None,drawDateTimeUTC='2026-10-24T02:30:00Z');r['doublePlayResult']=nested
    return dict(gameId=gid,gameNumber=str(gid),slug=slug,endDate=None,jackpotResults=dict(game=dict(gameId=gid),jackpotResults=[r]))
def parse(d,slug):
    raw='<script>self.__next_f.push('+json.dumps([1,'1:'+json.dumps({'cms':d})])+')</script>'
    return m.parse_results(raw,slug,NOW)
class DrawTest(unittest.TestCase):
    def test_all_contracts_dates_and_no_reports(self):
        for slug in m.CONTRACTS:
            rows=parse(cms(slug),slug)['results']
            self.assertEqual(rows[0]['date'],'2026-10-23')
            self.assertEqual(rows[0]['reportStatus'],'unavailable')
            self.assertNotIn('prizeTiers',rows[0])
            self.assertNotIn('never export',json.dumps(rows))
    def test_pick_repeated_digits_and_session_unknown(self):
        d=cms('pick3');r=d['jackpotResults']['jackpotResults'][0]
        for b in r['resultData']:b['data']=0
        row=parse(d,'pick3')['results'][0]
        self.assertEqual(row['numbers'],[0,0,0]);self.assertIsNone(row['session'])
    def test_range_type_order_and_cardinality(self):
        for key,value in [('data',70),('data',True),('type','SPECIAL'),('order',1)]:
            d=cms('powerball');d['jackpotResults']['jackpotResults'][0]['resultData'][0][key]=value
            with self.subTest(key=key,value=value),self.assertRaises(ValueError):parse(d,'powerball')
        d=cms('pick3');d['jackpotResults']['jackpotResults'][0]['resultData'].pop()
        with self.assertRaises(ValueError):parse(d,'pick3')
    def test_bad_status_future_and_dates(self):
        for key,value in [('jackpotStatus','PENDING'),('drawDateTimeUTC','2026-10-26T02:00:00Z'),('drawingDateUTC','2026-10-23'),('drawDateTimeUTC','2026-10-24T02:00:00')]:
            d=cms('cash-5');d['jackpotResults']['jackpotResults'][0][key]=value
            with self.subTest(key=key),self.assertRaises(ValueError):parse(d,'cash-5')
    def test_scheduled_empty_excluded(self):
        d=cms('cash-5');r=record('cash-5');r.update(id=3,drawDateTimeUTC='2026-10-25T02:00:00Z',drawingDateUTC='2026-10-25',jackpotStatus='SCHEDULED',resultData=[],prizeTiers=[])
        d['jackpotResults']['jackpotResults'].insert(0,r)
        self.assertEqual(parse(d,'cash-5')['excludedScheduled'],1)
        r['resultData']=[1]
        with self.assertRaises(ValueError):parse(d,'cash-5')
    def test_identity_duplicates_and_multiplayers(self):
        for slug in m.CONTRACTS:
            d=cms(slug);d['jackpotResults']['jackpotResults'][0]['gameId']=99
            with self.assertRaises(ValueError):parse(d,slug)
        for slug,value in [('powerball',None),('lotto-america',10),('megamillions',2)]:
            d=cms(slug);d['jackpotResults']['jackpotResults'][0]['multiplier']=value
            with self.assertRaises(ValueError):parse(d,slug)
        d=cms('cash-5');d['jackpotResults']['jackpotResults']*=2
        with self.assertRaises(ValueError):parse(d,'cash-5')
    def test_double_play_join(self):
        for key,value in [('id',1),('multiplier',2),('drawDateTimeUTC','2026-10-24T01:00:00Z'),('jackpotStatus','SCHEDULED')]:
            d=cms('powerball');d['jackpotResults']['jackpotResults'][0]['doublePlayResult'][key]=value
            with self.subTest(key=key),self.assertRaises(ValueError):parse(d,'powerball')
    def test_codes_preserved(self):
        row=parse(cms('powerball-xs-os'),'powerball-xs-os')['results'][0]
        self.assertEqual(row['valueKind'],'source_codes');self.assertEqual(row['numbers'],list(range(1,9)))
if __name__=='__main__':unittest.main()
