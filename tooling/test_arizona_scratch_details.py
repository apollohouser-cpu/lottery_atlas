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
