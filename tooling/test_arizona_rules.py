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


class LuckyLinksRulesTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/lucky-links-rules.json').read_text())

    def test_grid_and_combined_top_tier_preserved(self):
        rule=parse_capture(self.capture,'lucky-links')
        self.assertEqual(len(rule['tables'][0]['rows']),8)
        self.assertEqual(rule['tables'][0]['rows'][1],['7-8 Lines','$25,000','1 in 319,770.0'])
        self.assertIn('7 lines automatically forms 8 lines',rule['tables'][0]['sectionText'])
        self.assertIn('above $125,000',rule['tables'][0]['sectionText'])
        self.assertIn('3x3 grid with the center space “Free”',rule['howToPlay'])
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_each_cell_and_both_prose_sections_reject_changes(self):
        for i,row in enumerate(self.capture['tables'][0]['rows']):
            for j in range(len(row)):
                bad=copy.deepcopy(self.capture);bad['tables'][0]['rows'][i][j]+=' changed'
                with self.subTest(row=i,column=j),self.assertRaises(ValueError): parse_capture(bad,'lucky-links')
        for part in ('howToPlay','sectionText'):
            bad=copy.deepcopy(self.capture)
            if part=='howToPlay': bad[part]=''
            else: bad['tables'][0][part]=''
            with self.assertRaises(ValueError): parse_capture(bad,'lucky-links')
        with self.assertRaises(ValueError): parse_capture(self.capture,'hi-lo')


class FiveInLineRulesTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/five-in-line-rules.json').read_text())

    def test_ordered_match_labels_and_conditional_sharing(self):
        rule=parse_capture(self.capture,'5-in-a-line')
        self.assertEqual(len(rule['tables'][0]['rows']),7)
        self.assertEqual(rule['tables'][0]['rows'][5],['First Digits','$2','1 in 11.1'])
        self.assertIn('above $25,000',rule['tables'][0]['sectionText'])
        self.assertIn('same order',rule['howToPlay'])
        self.assertIn('Quick Pick only',rule['howToPlay'])
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_each_cell_and_prose_change_rejected(self):
        for i,row in enumerate(self.capture['tables'][0]['rows']):
            for j in range(len(row)):
                bad=copy.deepcopy(self.capture);bad['tables'][0]['rows'][i][j]+=' changed'
                with self.subTest(row=i,column=j),self.assertRaises(ValueError): parse_capture(bad,'5-in-a-line')
        for part in ('howToPlay','sectionText'):
            bad=copy.deepcopy(self.capture)
            if part=='howToPlay': bad[part]=''
            else: bad['tables'][0][part]=''
            with self.assertRaises(ValueError): parse_capture(bad,'5-in-a-line')
        with self.assertRaises(ValueError): parse_capture(self.capture,'lucky-links')


class TwoToWinRulesTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/two-to-win-rules.json').read_text())

    def test_bet_types_and_conditional_sharing(self):
        rule=parse_capture(self.capture,'two-to-win')
        self.assertEqual(len(rule['tables'][0]['rows']),6)
        self.assertEqual(rule['tables'][0]['rows'][2],['Box','$30','1 in 50'])
        self.assertIn('above $60,000',rule['tables'][0]['sectionText'])
        self.assertIn('00-99',rule['howToPlay'])
        self.assertIn('front digit, or back digit',rule['howToPlay'])
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_each_cell_and_prose_change_rejected(self):
        for i,row in enumerate(self.capture['tables'][0]['rows']):
            for j in range(len(row)):
                bad=copy.deepcopy(self.capture);bad['tables'][0]['rows'][i][j]+=' changed'
                with self.subTest(row=i,column=j),self.assertRaises(ValueError): parse_capture(bad,'two-to-win')
        for part in ('howToPlay','sectionText'):
            bad=copy.deepcopy(self.capture)
            if part=='howToPlay': bad[part]=''
            else: bad['tables'][0][part]=''
            with self.assertRaises(ValueError): parse_capture(bad,'two-to-win')
        with self.assertRaises(ValueError): parse_capture(self.capture,'5-in-a-line')


class OneToWinRulesTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/one-to-win-rules.json').read_text())

    def test_base_wager_and_conditional_prize_sharing(self):
        rule=parse_capture(self.capture,'one-to-win')
        self.assertEqual(len(rule['tables'][0]['rows']),9)
        self.assertEqual(rule['tables'][0]['rows'][1],['$250','1 in 4,200'])
        self.assertIn('$1.00 base game wager',rule['tables'][0]['rows'][-1][0])
        self.assertIn('above $200,000',rule['tables'][0]['sectionText'])
        self.assertIn('One number (1 – 15)',rule['howToPlay'])
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_each_cell_and_prose_change_rejected(self):
        for i,row in enumerate(self.capture['tables'][0]['rows']):
            for j in range(len(row)):
                bad=copy.deepcopy(self.capture);bad['tables'][0]['rows'][i][j]+=' changed'
                with self.subTest(row=i,column=j),self.assertRaises(ValueError): parse_capture(bad,'one-to-win')
        for part in ('howToPlay','sectionText'):
            bad=copy.deepcopy(self.capture)
            if part=='howToPlay': bad[part]=''
            else: bad['tables'][0][part]=''
            with self.assertRaises(ValueError): parse_capture(bad,'one-to-win')
        with self.assertRaises(ValueError): parse_capture(self.capture,'two-to-win')


class MoneyRollRulesTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/money-roll-rules.json').read_text())

    def test_position_matching_and_literal_sharing_condition(self):
        rule=parse_capture(self.capture,'money-roll')
        self.assertEqual(len(rule['tables'][0]['rows']),6)
        self.assertEqual(rule['tables'][0]['rows'][1],['5','$1,000','1 in 7,776'])
        self.assertIn('same position',rule['howToPlay'])
        self.assertIn('Quick Pick only',rule['howToPlay'])
        self.assertIn('5 dice with 5X multiplier drawn is $100,000',rule['tables'][0]['sectionText'])
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_each_cell_and_prose_change_rejected(self):
        for i,row in enumerate(self.capture['tables'][0]['rows']):
            for j in range(len(row)):
                bad=copy.deepcopy(self.capture);bad['tables'][0]['rows'][i][j]+=' changed'
                with self.subTest(row=i,column=j),self.assertRaises(ValueError): parse_capture(bad,'money-roll')
        for part in ('howToPlay','sectionText'):
            bad=copy.deepcopy(self.capture)
            if part=='howToPlay': bad[part]=''
            else: bad['tables'][0][part]=''
            with self.assertRaises(ValueError): parse_capture(bad,'money-roll')
        with self.assertRaises(ValueError): parse_capture(self.capture,'one-to-win')
