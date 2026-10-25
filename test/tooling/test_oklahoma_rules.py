import copy
import json
from pathlib import Path
import sys
import unittest
sys.path.insert(0, str(Path(__file__).resolve().parents[2]/'tooling'))
import oklahoma_draw_rules as m

SPECS=json.loads(m.SPEC_PATH.read_text())
def rich(node):
    if node is None:return None
    def build(n):
        d=dict(nodeType=n['type'],data={})
        if n['type']=='text':d.update(value=n['text'],marks=[])
        else:d['content']=[build(c) for c in n['children']]
        return d
    return {'json':build(node)}
def cms(slug):
    d=copy.deepcopy(SPECS[slug]);d.update(gameId=m.CONTRACTS[slug][0],gameNumber=str(m.CONTRACTS[slug][0]),slug=slug,endDate=None)
    for key in m.PROSE_FIELDS:d[key]=rich(d[key])
    return d
def parse(d,slug):
    return m.parse_rules('<script>self.__next_f.push('+json.dumps([1,'1:'+json.dumps({'cms':d})])+')</script>',slug)

class RulesTest(unittest.TestCase):
    def test_all_structures_and_categorical_prizes(self):
        rows=[parse(cms(s),s) for s in SPECS]
        self.assertEqual(sum(len(g['matches']) for r in rows for g in r['prizeLegend']),167)
        cash=parse(cms('cash-5'),'cash-5')
        self.assertIn('Free Ticket',json.dumps(cash))
    def test_every_family_rejects_schedule_drift(self):
        for slug in SPECS:
            d=cms(slug);d['prizeLegend'][0]['matches'][0]['odds']='1 in 2'
            with self.subTest(slug=slug),self.assertRaises(ValueError):parse(d,slug)
    def test_prose_and_disclaimer_changes_fail(self):
        for key in m.PROSE_FIELDS:
            d=cms('millionaire-for-life');d[key]=None
            if SPECS['millionaire-for-life'][key] is not None:
                with self.subTest(key=key),self.assertRaises(ValueError):parse(d,'millionaire-for-life')
        d=cms('pick3');d['drawTimes']=['21:10:00']
        with self.assertRaises(ValueError):parse(d,'pick3')
    def test_missing_identity_and_new_assets_fail(self):
        for key in ['prizeLegend','disclaimer','endDate']:
            d=cms('powerball');del d[key]
            with self.subTest(key=key),self.assertRaises(ValueError):parse(d,'powerball')
        d=cms('powerball');d['howToPlay']['links']={'assets':{'hyperlink':[{}]}}
        with self.assertRaises(ValueError):parse(d,'powerball')
    def test_display_marks_ignored_but_text_not(self):
        d=cms('pick3');n=d['howToPlay']['json']['content'][0]['content'][0]
        n['marks']=[{'type':'bold'}];parse(d,'pick3')
        n['value']+=' changed'
        with self.assertRaises(ValueError):parse(d,'pick3')
if __name__=='__main__':unittest.main()
