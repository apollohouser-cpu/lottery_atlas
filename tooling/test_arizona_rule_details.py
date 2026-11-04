import copy
import json
from pathlib import Path
import unittest
from tooling.arizona_rule_details import parse_capture


class RuleDetailsTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/powerball-rule-details.json').read_text())

    def test_addons_and_claim_caveats_preserved_as_prose(self):
        rule=parse_capture(self.capture,'powerball')
        self.assertEqual(len(rule['sections']),2)
        self.assertIn('Power Play does not apply to Double Play prizes',rule['sections'][0]['text'])
        self.assertIn('The top prize will be divided equally',rule['sections'][1]['text'])
        self.assertFalse(rule['actualPayoutsAvailable'])
        rule['sections'].clear()
        self.assertEqual(len(self.capture['sections']),2)

    def test_missing_caveats_links_or_identity_rejected(self):
        for key in ('sourceUrl','title','captureKind','retrievedAt'):
            bad=copy.deepcopy(self.capture);bad[key]='changed'
            with self.subTest(key=key),self.assertRaises(ValueError):parse_capture(bad,'powerball')
        for i,section in enumerate(self.capture['sections']):
            bad=copy.deepcopy(self.capture);bad['sections'][i]['text']=''
            with self.assertRaises(ValueError):parse_capture(bad,'powerball')
            for j in range(len(section['links'])):
                bad=copy.deepcopy(self.capture);bad['sections'][i]['links'][j]['href']='https://example.com/'
                with self.assertRaises(ValueError):parse_capture(bad,'powerball')
        bad=copy.deepcopy(self.capture);bad['retrievedAt']='2026-11-04T07:00:00'
        with self.assertRaises(ValueError):parse_capture(bad,'powerball')
        bad=copy.deepcopy(self.capture);bad['sections'].pop()
        with self.assertRaises(ValueError):parse_capture(bad,'powerball')
