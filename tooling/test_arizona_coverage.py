import copy
import unittest
from arizona_coverage import compile_coverage
from test_arizona_snapshot import fixture_snapshot

class CoverageTests(unittest.TestCase):
    def setUp(self):self.c=fixture_snapshot()

    def test_complete_candidate_keeps_dates_and_explicit_gaps(self):
        r=compile_coverage(self.c,self.c)
        self.assertFalse(r['productionReady'])
        self.assertNotIn('captures',r)
        self.assertEqual(len(r['drawGroups']),19)
        self.assertEqual(sum(map(len,r['drawGroups'].values())),38)
        self.assertEqual([len(r['products'][k]) for k in ('scratchers','fast-play')],[60,26])
        self.assertEqual([len(r['endingNotices'][k]['notices']) for k in ('scratchers','fast-play')],[14,5])
        self.assertEqual(r['drawProvenance']['powerball'][0]['retrievedAt'],self.c['draws']['regular']['powerball']['retrievedAt'])

    def test_image_dependent_instructions_are_not_silently_incomplete(self):
        r=compile_coverage(self.c,self.c)
        product=next(p for p in r['products']['scratchers'] if p['gameNumber']=='1401')
        self.assertIsNone(product['rulePresentation']['text'])
        self.assertEqual(product['rulePresentation']['status'],'official-source-required')
        self.assertEqual(product['rulePresentation']['sourceUrl'],product['sourceUrl'])
        self.assertFalse(product['inventoryAvailable'])
        self.assertFalse(product['symbolInterpretationAvailable'])

    def test_late_ending_failure_prevents_any_candidate(self):
        c=copy.deepcopy(self.c)
        c['endings']['fast-play']['tables'][0]['rows'][-2][1]['text']='11/3/2026'
        with self.assertRaises(ValueError):compile_coverage(c,self.c)
        self.assertEqual(self.c,fixture_snapshot())
