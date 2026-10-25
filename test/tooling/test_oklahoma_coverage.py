import copy
import json
from pathlib import Path
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'tooling'))
import oklahoma_coverage as m

def baseline():
    return dict(schemaVersion=1,state='Oklahoma',updatedAt='2026-10-25T04:00:00+00:00',rules=[{'literal':'rule'}],
        results=[dict(game='pick3',variant='base',date='2026-10-24',numbers=[1,2,3],retrievedAt='original')],
        products={'fastPlay':{'games':[dict(id='1',name='Game',progressiveEstimate=100,
            prizeTiers=[dict(prizeLabel='JACKPOT',prizeAmount=None,totalPrizes=3,remainingPrizes=2)])]}})

class CoverageTest(unittest.TestCase):
    def test_decrease_estimate_change_and_unknown(self):
        old=baseline();new=copy.deepcopy(old)
        new['products']['fastPlay']['games'][0]['progressiveEstimate']=120
        new['products']['fastPlay']['games'][0]['prizeTiers'][0]['remainingPrizes']=1
        m.continuity(old,new)
        new['products']['fastPlay']['games'][0]['prizeTiers']=[];m.continuity(old,new)
    def test_inventory_increase_original_change_and_loss(self):
        for key,value in [('remainingPrizes',3),('totalPrizes',4)]:
            old=baseline();new=copy.deepcopy(old);new['products']['fastPlay']['games'][0]['prizeTiers'][0][key]=value
            with self.assertRaises(ValueError):m.continuity(old,new)
        old=baseline();new=copy.deepcopy(old);new['products']['fastPlay']['games']=[]
        with self.assertRaises(ValueError):m.continuity(old,new)
    def test_correction_and_regression(self):
        old=baseline()
        for key,value in [('numbers',[3,2,1]),('date','2026-10-23')]:
            new=copy.deepcopy(old);new['results'][0][key]=value
            with self.assertRaises(ValueError):m.continuity(old,new)
    def test_rollover_preserves_overlap(self):
        old=baseline();new=copy.deepcopy(old);new['results'][0]['date']='2026-10-25'
        m.continuity(old,new)
        new['results'].append(dict(old['results'][0],date='2026-10-23'))
        with self.assertRaises(ValueError):m.continuity(old,new)
    def test_collect_failure_keeps_exact_bytes(self):
        with tempfile.TemporaryDirectory() as folder:
            p=Path(folder)/'feed.json';p.write_text(json.dumps(baseline()));before=p.read_bytes()
            with patch.object(m,'collect',side_effect=ValueError('failure')),self.assertRaises(ValueError):m.refresh(p,None)
            self.assertEqual(p.read_bytes(),before)
    def test_replace_failure_keeps_bytes_cleans_temporary(self):
        with tempfile.TemporaryDirectory() as folder:
            p=Path(folder)/'feed.json';p.write_text(json.dumps(baseline()));before=p.read_bytes()
            with patch.object(m,'collect',return_value=baseline()),patch.object(m.os,'replace',side_effect=OSError('disk')),self.assertRaises(OSError):m.refresh(p,None)
            self.assertEqual(p.read_bytes(),before);self.assertEqual(list(Path(folder).iterdir()),[p])
    def test_success_and_correction_retention(self):
        with tempfile.TemporaryDirectory() as folder:
            p=Path(folder)/'feed.json'
            with patch.object(m,'collect',return_value=baseline()):m.refresh(p,None)
            before=p.read_bytes();bad=baseline();bad['results'][0]['numbers']=[9,9,9]
            with patch.object(m,'collect',return_value=bad),self.assertRaises(ValueError):m.refresh(p,None)
            self.assertEqual(p.read_bytes(),before)
if __name__=='__main__':unittest.main()
