import copy
import json
import unittest
from pathlib import Path
from arizona_fast_play_details import parse_capture

class FastPlayDetailTests(unittest.TestCase):
    def setUp(self):
        self.c=json.loads((Path(__file__).parent/'fixtures/arizona/169-detail.json').read_text())
    def test_progressive_is_not_fixed_prize_or_inventory(self):
        r=parse_capture(self.c,self.c)
        self.assertEqual(len(r['tiers']),10)
        self.assertEqual(r['tiers'][0]['prizeLabel'],'Progressive')
        self.assertFalse(r['progressiveJackpotGuaranteed'])
        self.assertFalse(r['inventoryAvailable'])
        self.assertIn('does not apply to progressive jackpot',r['rules']['text'])
        self.assertIn('date of purchase',r['faq'][0]['text'])
    def test_unloaded_jackpot_rejected(self):
        c=copy.deepcopy(self.c);c['header']=c['header'].replace('$266,958','')
        with self.assertRaises(ValueError):parse_capture(c,self.c)
    def test_changed_faq_or_game_identity_rejected(self):
        for key,value in [('faq',[]),('header',self.c['header'].replace('#169','#170'))]:
            c=copy.deepcopy(self.c);c[key]=value
            with self.assertRaises(ValueError):parse_capture(c,self.c)
    def test_moving_jackpot_does_not_rewrite_tier(self):
        c=copy.deepcopy(self.c);c['header']=c['header'].replace('$266,958','$267,000')
        r=parse_capture(c,self.c)
        self.assertEqual(r['progressiveJackpotObserved'],'$267,000')
        self.assertEqual(r['tiers'][0]['prizeLabel'],'Progressive')


class FastPlayContinuityTests(unittest.TestCase):
    setUp=FastPlayDetailTests.setUp
    def validate(self,c):
        from arizona_fast_play_details import validate_continuity
        return validate_continuity(c,self.c)
    def test_jackpot_reset_and_prize_decrease_allowed(self):
        c=copy.deepcopy(self.c);c['header']=c['header'].replace('$266,958','$100,000')
        for k in ('table','prizeDetails'):c[k]=c[k].replace('7 of 12','6 of 12')
        self.assertEqual(self.validate(c)['progressiveJackpotObserved'],'$100,000')
    def test_partial_tiers_and_changed_originals_rejected(self):
        for old,new in [('$20\t7.14\t143,451 of 235,200\n',''),('7 of 12','7 of 13'),('140,000','140,001'),('7 of 12','8 of 12')]:
            c=copy.deepcopy(self.c)
            for k in ('table','prizeDetails'):c[k]=c[k].replace(old,new)
            with self.assertRaises(ValueError):self.validate(c)
    def test_time_regression_and_inconsistent_sections_rejected(self):
        for k,v in [('retrievedAt','2020-01-01T00:00:00Z'),('prizeDetails',self.c['prizeDetails'].replace('7 of 12','6 of 12'))]:
            c=copy.deepcopy(self.c);c[k]=v
            with self.assertRaises(ValueError):self.validate(c)

    def test_unseparated_jackpot_not_truncated(self):
        c=copy.deepcopy(self.c);c['header']=c['header'].replace('$266,958','$267000')
        self.assertEqual(self.validate(c)['progressiveJackpotObserved'],'$267000')
