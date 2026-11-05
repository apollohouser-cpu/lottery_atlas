import copy
import json
import unittest
from pathlib import Path
from arizona_scratch_details import parse_capture

class ScratchDetailTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/1401-detail.json').read_text())
    def parse(self,c):
        return parse_capture(c,self.capture['sourceUrl'],self.capture['header'])
    def test_literal_tiers_are_not_inventory(self):
        result=self.parse(self.capture)
        self.assertEqual(len(result['tiers']),7)
        self.assertEqual(result['tiers'][0]['remainingPrizes'],2)
        self.assertEqual(result['tiers'][0]['originalPrizes'],6)
        self.assertFalse(result['inventoryAvailable'])
        self.assertFalse(result['symbolInterpretationAvailable'])
        self.assertEqual(len(result['rules']['images']),3)
    def test_missing_dynamic_rows_rejected(self):
        bad=copy.deepcopy(self.capture);bad['table']='Prize\tOdds 1 In\tPrizes Remaining\nOverall Odds: 1 in 2.18'
        with self.assertRaises(ValueError):self.parse(bad)
    def test_invalid_remaining_and_odds_rejected(self):
        for old,new in [('2 of 6','7 of 6'),('886,248','0'),('2 of 6','2 of 0')]:
            bad=copy.deepcopy(self.capture);bad['table']=bad['table'].replace(old,new)
            with self.assertRaises(ValueError):self.parse(bad)
    def test_identity_change_rejected(self):
        bad=copy.deepcopy(self.capture);bad['header']=bad['header'].replace('1401','1402')
        with self.assertRaises(ValueError):self.parse(bad)

class ScratchContinuityTests(unittest.TestCase):
    setUp = ScratchDetailTests.setUp
    def validate(self,c):
        from arizona_scratch_details import validate_continuity
        return validate_continuity(c,self.capture)
    def test_unchanged_or_decreasing_remaining_allowed(self):
        self.validate(self.capture)
        c=copy.deepcopy(self.capture)
        for key in ('table','prizeDetails'): c[key]=c[key].replace('2 of 6','1 of 6')
        self.assertEqual(self.validate(c)['tiers'][0]['remainingPrizes'],1)
    def test_partial_table_and_count_increase_rejected(self):
        for old,new in [('2 of 6','3 of 6'),('$5 Million\t886,248\t2 of 6\n','')]:
            c=copy.deepcopy(self.capture)
            for key in ('table','prizeDetails'): c[key]=c[key].replace(old,new)
            with self.assertRaises(ValueError):self.validate(c)
    def test_rule_symbol_terms_and_time_changes_rejected(self):
        for key,value in [('rules',{'text':'changed','images':[]}),('retrievedAt','2020-01-01T00:00:00Z'),('prizeDetails',self.capture['prizeDetails'].replace('20 annual','10 annual'))]:
            c=copy.deepcopy(self.capture);c[key]=value
            with self.assertRaises(ValueError):self.validate(c)
    def test_mismatched_rendered_sections_rejected(self):
        c=copy.deepcopy(self.capture);c['table']=c['table'].replace('2 of 6','1 of 6')
        with self.assertRaises(ValueError):self.validate(c)

class AdditionalScratchEvidenceTests(unittest.TestCase):
    def test_live_repeat_matches_retained_baseline(self):
        from arizona_scratch_details import validate_continuity
        root=Path(__file__).parent/'fixtures/arizona'
        old=json.loads((root/'1401-detail.json').read_text())
        new=json.loads((root/'1401-detail-repeat.json').read_text())
        result=validate_continuity(new,old)
        self.assertEqual(len(result['tiers']),7)
        self.assertGreater(new['retrievedAt'],old['retrievedAt'])
    def test_treasure_hunt_literal_prizes_and_coordinate_rules(self):
        c=json.loads((Path(__file__).parent/'fixtures/arizona/1470-detail.json').read_text())
        result=parse_capture(c,'https://www.arizonalottery.com/scratchers/1470-arizona-treasure-hunt/',
            'ARIZONA TREASURE HUNT #1470\nTOP PRIZE: $20,000\nTicket Price: $3 Start Date: 12/3/2024')
        self.assertEqual(len(result['tiers']),10)
        self.assertEqual(result['tiers'][0]['remainingPrizes'],1)
        self.assertIn('24 TREASURE MAP locations',result['rules']['text'])
        self.assertNotIn('ticketPositions',result)
        self.assertFalse(result['inventoryAvailable'])

class ScratchCatalogCaptureTests(unittest.TestCase):
    def test_all_fixed_scope_products_have_loaded_tiers(self):
        root=Path(__file__).parent/'fixtures/arizona'
        captures=json.loads((root/'scratchers-details-batch.json').read_text())
        navigation=json.loads((root/'scratchers-navigation.json').read_text())
        expected={'https://www.arizonalottery.com'+r['href'] for r in navigation['links']}
        self.assertEqual({c['sourceUrl'] for c in captures},expected)
        self.assertEqual(len(captures),len(expected))
        for c in captures:
            with self.subTest(source=c['sourceUrl']):
                result=parse_capture(c,c['sourceUrl'],c['header'])
                self.assertTrue(result['tiers'])
                self.assertFalse(result['inventoryAvailable'])
    def test_trailing_nonbreaking_space_in_odds_is_not_missing_data(self):
        root=Path(__file__).parent/'fixtures/arizona'
        captures=json.loads((root/'scratchers-details-batch.json').read_text())
        c=next(c for c in captures if '#1539' in c['header'])
        self.assertEqual(parse_capture(c,c['sourceUrl'],c['header'])['overallOddsOneIn'],'3.50')

class NovemberScratchAdditionsTests(unittest.TestCase):
    def test_new_product_identity_and_start_dates(self):
        rows=json.loads((Path(__file__).parent/'fixtures/arizona/scratchers-november-additions.json').read_text())
        expected={'https://www.arizonalottery.com/scratchers/1554-clue/':'1554',
                  'https://www.arizonalottery.com/scratchers/1555-diamond-deluxe/':'1555'}
        self.assertEqual({r['sourceUrl'] for r in rows},set(expected))
        for c in rows:
            self.assertIn('#'+expected[c['sourceUrl']],c['header'])
            self.assertIn('Start Date: 11/3/2026',c['header'])
            self.assertEqual(len(parse_capture(c,c['sourceUrl'],c['header'])['tiers']),10)
