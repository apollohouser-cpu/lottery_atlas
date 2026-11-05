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

class FastPlayMatrixTests(unittest.TestCase):
    def test_fixed_scope_identity_and_complete_tiers(self):
        from arizona_fast_play_details import validate_continuity
        root=Path(__file__).parent/'fixtures/arizona'
        rows=json.loads((root/'fast-play-details-batch.json').read_text())
        links=json.loads((root/'fast-play-navigation.json').read_text())['links']
        self.assertEqual(len(rows),len(links))
        self.assertEqual({r['sourceUrl'] for r in rows},{'https://www.arizonalottery.com'+l['href'] for l in links})
        for c in rows:
            with self.subTest(url=c['sourceUrl']):
                r=validate_continuity(c,c)
                self.assertTrue(r['tiers'])
                self.assertEqual(r['progressiveJackpotObserved'] is not None,'PROGRESSIVE JACKPOT:' in c['header'])
    def test_live_169_repeat(self):
        from arizona_fast_play_details import validate_continuity
        root=Path(__file__).parent/'fixtures/arizona'
        rows=json.loads((root/'fast-play-details-batch.json').read_text())
        old=json.loads((root/'169-detail.json').read_text())
        new=next(c for c in rows if c['sourceUrl']==old['sourceUrl'])
        self.assertEqual(len(validate_continuity(new,old)['tiers']),10)
    def test_fixed_prize_change_is_not_progressive_reset(self):
        rows=json.loads((Path(__file__).parent/'fixtures/arizona/fast-play-details-batch.json').read_text())
        old=next(c for c in rows if '#175' in c['header']);new=copy.deepcopy(old)
        new['header']=new['header'].replace('$10,000','$20,000')
        with self.assertRaises(ValueError):parse_capture(new,old)

class PrizePyramidTests(unittest.TestCase):
    def test_new_fixed_prize_product(self):
        c=json.loads((Path(__file__).parent/'fixtures/arizona/207-detail.json').read_text())
        self.assertEqual(c['sourceUrl'],'https://www.arizonalottery.com/fast-play/207-prize-pyramid/')
        self.assertIn('Start Date: 11/3/2026',c['header'])
        r=parse_capture(c,c)
        self.assertEqual(len(r['tiers']),11)
        self.assertIsNone(r['progressiveJackpotObserved'])
        self.assertIn('Each PYRAMID and PYRAMID LEVEL is played separately',r['rules']['text'])
        self.assertNotIn('ticketPositions',r)
