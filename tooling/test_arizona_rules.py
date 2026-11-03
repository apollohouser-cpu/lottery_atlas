import copy
import json
from pathlib import Path
import unittest
from tooling.arizona_rules import parse_capture


class RulesTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/hi-lo-rules.json').read_text())

    def test_literal_schedule_caveats_and_wager_options(self):
        rule=parse_capture(self.capture,'hi-lo')
        self.assertEqual(len(rule['tables'][0]['rows']),9)
        self.assertEqual(rule['tables'][0]['rows'][1],['0-4, 16-20','$555','1 in 929.3'])
        self.assertIn('$55,500',rule['tables'][0]['sectionText'])
        self.assertIn('$1, $2, $5, $10 or $20',rule['howToPlay'])
        self.assertFalse(rule['actualPayoutsAvailable'])
        rule['tables'][0]['rows'][1][1]='changed'
        self.assertEqual(self.capture['tables'][0]['rows'][1][1],'$555')

    def test_each_schedule_cell_change_rejected(self):
        for i,row in enumerate(self.capture['tables'][0]['rows']):
            for j in range(len(row)):
                bad=copy.deepcopy(self.capture)
                bad['tables'][0]['rows'][i][j]+=' changed'
                with self.subTest(row=i,column=j),self.assertRaises(ValueError): parse_capture(bad,'hi-lo')

    def test_prose_source_kind_and_timezone_changes_rejected(self):
        for key,value in [('howToPlay',''),('sourceUrl','https://example.com'),('captureKind','http'),('retrievedAt','2026-11-03T00:00:00')]:
            bad=copy.deepcopy(self.capture);bad[key]=value
            with self.subTest(key=key),self.assertRaises(ValueError): parse_capture(bad,'hi-lo')
        bad=copy.deepcopy(self.capture);bad['tables'][0]['sectionText']=''
        with self.assertRaises(ValueError): parse_capture(bad,'hi-lo')
        with self.assertRaises(ValueError): parse_capture(self.capture,'unknown')
