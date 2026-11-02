import copy
import json
from pathlib import Path
import unittest
from tooling.arizona_draw_bundle import select_refresh
from tooling.arizona_regular_draws import SOURCES
from tooling.arizona_quick_draw import PARSERS


class DrawBundleTests(unittest.TestCase):
    def setUp(self):
        root = Path(__file__).parent / 'fixtures/arizona'
        names = {'powerball-xs-os':'xsos','fantasy-5':'fantasy5','pick-3':'pick3',
                 'pick-4':'pick4','5-in-a-line':'five-in-line'}
        def capture(game):
            return json.loads((root / (names.get(game,game)+'-tables.json')).read_text())
        self.bundle = {'regular':{g:capture(g) for g in SOURCES},
                       'quickDraw':{g:[capture(g)] for g in PARSERS}}

    def test_all_thirty_eight_results_preserve_different_semantics(self):
        before = copy.deepcopy(self.bundle)
        result = select_refresh(self.bundle,self.bundle)
        self.assertEqual(sum(map(len,result['groups'].values())),38)
        self.assertEqual(len(result['groups']),19)
        self.assertNotIn('drawTime',result['groups']['fantasy-5'][0])
        self.assertEqual(result['groups']['hi-lo'][0]['highNumberTotal'],9)
        self.assertNotIn('numbers',result['groups']['hi-lo'][0])
        self.assertNotIn('collectedAt', result)
        self.assertEqual(self.bundle,before)
        for game,rows in result['groups'].items():
            self.assertTrue(all(r['reportStatus']=='unavailable' for r in rows))
            self.assertTrue(result['provenance'][game])

    def test_every_missing_source_rejects_entire_bundle(self):
        for family in self.bundle:
            for game in self.bundle[family]:
                bad=copy.deepcopy(self.bundle)
                del bad[family][game]
                with self.subTest(game=game),self.assertRaises(ValueError): select_refresh(bad,self.bundle)

    def test_every_source_header_change_rejects_and_preserves_inputs(self):
        for family in self.bundle:
            for game in self.bundle[family]:
                bad=copy.deepcopy(self.bundle)
                capture=bad[family][game]
                if family=='quickDraw': capture=capture[0]
                capture['tables'][0]['rows'][0][0]['text']='Changed'
                before=copy.deepcopy(bad)
                with self.subTest(game=game),self.assertRaises(ValueError): select_refresh(bad,self.bundle)
                self.assertEqual(bad,before)

    def test_family_omission_or_extra_family_rejects(self):
        for key in ('regular','quickDraw'):
            bad=copy.deepcopy(self.bundle)
            del bad[key]
            with self.assertRaises(ValueError): select_refresh(bad,self.bundle)
        bad=copy.deepcopy(self.bundle)
        bad['invented']={}
        with self.assertRaises(ValueError): select_refresh(bad,self.bundle)
