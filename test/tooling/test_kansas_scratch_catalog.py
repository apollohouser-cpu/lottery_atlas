import importlib.util
import json
from datetime import date
from pathlib import Path
import unittest
spec=importlib.util.spec_from_file_location('ks',Path(__file__).resolve().parents[2]/'tooling/import_kansas_scratch_catalog.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
GAME=dict(gameId=490,gameNumber='490',slug='example',title='Example',ticketPrice=5,topPrize=25000,pullTab=False,startDate='2026-08-24T00:00:00-05:00',endDate=None,claimEndDate=None)
def listing(games):
    return '<script>self.__next_f.push('+json.dumps([1,'1:'+json.dumps({'scratchOffs':games})])+')</script>'
def detail(remaining='2'):
    fields={'Game Number':'490','Price':'$5','Top Prize':'$25,000','Expiration Date':'TBD','Launch Date':'Aug 23, 2026'}
    s='<main>'+''.join(f'<div><p>{k}</p><p>{v}</p></div>' for k,v in fields.items())
    s+='<table><thead><tr><th>Prize</th><th>Remaining</th></tr></thead><tbody>'
    for prize,count in [('$25,000',remaining),('$5','1,234'),('FREE TICKET','500')]:
        s+='<tr>'+''.join(f'<td><span>{v}</span><span aria-hidden="true">{v}</span></td>' for v in [prize,count])+'</tr>'
    return s+'</tbody></table>The remaining prize quantity updates once every hour.</main>'
class KansasTest(unittest.TestCase):
    def test_scope_excludes_pulltabs_ended_and_future(self):
        games=[GAME,dict(GAME,gameId=491,gameNumber='491',slug='pull',pullTab=True),dict(GAME,gameId=492,gameNumber='492',slug='ended',endDate='2026-08-31T00:00:00-05:00'),dict(GAME,gameId=493,gameNumber='493',slug='future',startDate='2026-10-01T00:00:00-05:00')]
        self.assertEqual(m.parse_listing(listing(games),date(2026,9,20)),[GAME])
    def test_missing_type_dates_and_duplicates_rejected(self):
        for games in [[GAME,GAME],[dict(GAME,pullTab=None)],[{k:v for k,v in GAME.items() if k!='endDate'}]]:
            with self.subTest(games=games),self.assertRaises(ValueError):m.parse_listing(listing(games),date(2026,9,20))
    def test_inventory_not_doubled_and_free_ticket_not_cash(self):
        g=m.parse_detail(detail('0'),GAME)
        self.assertEqual(g['topPrizesRemaining'],0)
        self.assertEqual(len(g['prizeTiers']),3)
        self.assertNotIn('prizeAmount',g['prizeTiers'][-1])
        self.assertNotIn('startDate',g)
        self.assertEqual(g['sourceLaunchDisplayed'],'2026-08-23')
        self.assertEqual(g['sourceLaunchMetadata'],GAME['startDate'])
    def test_invalid_remaining_rejected(self):
        for value in ['', '-1','unknown','1,00']:
            with self.subTest(value=value),self.assertRaises(ValueError):m.parse_detail(detail(value),GAME)
    def test_identity_amount_or_expiration_disagreement_rejected(self):
        for raw in [detail().replace('<p>490</p>','<p>999</p>'),detail().replace('<p>$25,000</p>','<p>$50,000</p>'),detail().replace('TBD','Oct 01, 2026')]:
            with self.subTest(raw=raw),self.assertRaises(ValueError):m.parse_detail(raw,GAME)
    def test_rendered_duplicates_must_agree(self):
        with self.assertRaises(ValueError):m.parse_detail(detail().replace('<span>2</span>','<span>3</span>'),GAME)
if __name__=='__main__':unittest.main()
