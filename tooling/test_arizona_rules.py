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


class PickYourBetRulesTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/pick-your-bet-rules.json').read_text())

    def test_two_dollar_wager_and_distinct_bet_types(self):
        rule=parse_capture(self.capture,'pick-your-bet')
        self.assertEqual(rule['tables'][0]['rows'],[
            ['Bet Type','Prize','Odds*'],['Lucky Number','$50','1 in 38'],
            ['Odd/Even','$3','1 in 2'],['Low/High','$3','1 in 2']])
        self.assertIn('chart based on a $2 wager',rule['tables'][0]['sectionText'])
        self.assertIn('Low (1 - 19) or High (20 - 38)',rule['howToPlay'])
        self.assertIn('$2, $4, $6, $10, or $20',rule['howToPlay'])
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_each_cell_and_prose_change_rejected(self):
        for i,row in enumerate(self.capture['tables'][0]['rows']):
            for j in range(len(row)):
                bad=copy.deepcopy(self.capture);bad['tables'][0]['rows'][i][j]+=' changed'
                with self.subTest(row=i,column=j),self.assertRaises(ValueError): parse_capture(bad,'pick-your-bet')
        for part in ('howToPlay','sectionText'):
            bad=copy.deepcopy(self.capture)
            if part=='howToPlay': bad[part]=''
            else: bad['tables'][0][part]=''
            with self.assertRaises(ValueError): parse_capture(bad,'pick-your-bet')
        with self.assertRaises(ValueError): parse_capture(self.capture,'money-roll')


class FiveTenFortyFiveRulesTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/51045-rules.json').read_text())

    def test_spot_schedules_keep_base_and_additive_bullseye_separate(self):
        rule=parse_capture(self.capture,'51045')
        nested=rule['tables'][0]['nestedTables']
        self.assertEqual([len(t['rows']) for t in nested],[8,6,5,4,3])
        self.assertEqual(nested[0]['rows'][1][1:],['$500','+$700'])
        self.assertEqual(nested[0]['rows'][6][1:],['$1','No Prize'])
        self.assertEqual(nested[4]['rows'][1][1:],['$3','+$27'])
        self.assertIn('above $200,000',rule['tables'][0]['sectionText'])
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_nested_cells_labels_and_prose_are_continuity_gated(self):
        for t,table in enumerate(self.capture['tables'][0]['nestedTables']):
            for i,row in enumerate(table['rows']):
                for j in range(len(row)):
                    bad=copy.deepcopy(self.capture)
                    bad['tables'][0]['nestedTables'][t]['rows'][i][j]+=' changed'
                    with self.subTest(table=t,row=i,column=j),self.assertRaises(ValueError): parse_capture(bad,'51045')
            bad=copy.deepcopy(self.capture);bad['tables'][0]['nestedTables'][t]['label']=''
            with self.assertRaises(ValueError): parse_capture(bad,'51045')
        for part in ('howToPlay','sectionText'):
            bad=copy.deepcopy(self.capture)
            if part=='howToPlay': bad[part]=''
            else: bad['tables'][0][part]=''
            with self.assertRaises(ValueError): parse_capture(bad,'51045')
        bad=copy.deepcopy(self.capture);bad['tables'][0]['nestedTables'].pop()
        with self.assertRaises(ValueError): parse_capture(bad,'51045')


class FantasyFiveRulesTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/fantasy-5-rules.json').read_text())

    def test_symbolic_match_tiers_and_extra_caveat_preserved(self):
        rule=parse_capture(self.capture,'fantasy-5');table=rule['tables'][0]
        self.assertEqual([r[0] for r in table['matchingSymbols'][1:5]],[5,4,3,2])
        self.assertEqual([r[1] for r in table['rows'][1:5]],['Jackpot*','$500','$5','$1'])
        self.assertIn('share the prize pool in equal amounts',table['sectionText'])
        self.assertIn('EXTRA!',rule['howToPlay'])
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_symbol_changes_and_lost_caveats_rejected(self):
        for i in range(1,5):
            bad=copy.deepcopy(self.capture);bad['tables'][0]['matchingSymbols'][i][0]-=1
            with self.subTest(row=i),self.assertRaises(ValueError): parse_capture(bad,'fantasy-5')
        for i,row in enumerate(self.capture['tables'][0]['rows']):
            for j in range(len(row)):
                bad=copy.deepcopy(self.capture);bad['tables'][0]['rows'][i][j]+=' changed'
                with self.subTest(row=i,column=j),self.assertRaises(ValueError): parse_capture(bad,'fantasy-5')
        for part in ('howToPlay','sectionText'):
            bad=copy.deepcopy(self.capture)
            if part=='howToPlay': bad[part]=''
            else: bad['tables'][0][part]=''
            with self.assertRaises(ValueError): parse_capture(bad,'fantasy-5')


class ThePickRulesTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/the-pick-rules.json').read_text())

    def test_symbolic_match_tiers_and_extra_caveat_preserved(self):
        rule=parse_capture(self.capture,'the-pick');table=rule['tables'][0]
        self.assertEqual([r[0] for r in table['matchingSymbols'][1:5]],[6,5,4,3])
        self.assertEqual([r[1] for r in table['rows'][1:5]],['Jackpot*','$1,000','$25','$2'])
        self.assertIn('cost $2 per game',rule['howToPlay'])
        self.assertIn('Odds vary per Plus game',table['sectionText'])
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_symbol_changes_and_lost_caveats_rejected(self):
        for i in range(1,5):
            bad=copy.deepcopy(self.capture);bad['tables'][0]['matchingSymbols'][i][0]-=1
            with self.subTest(row=i),self.assertRaises(ValueError): parse_capture(bad,'the-pick')
        for i,row in enumerate(self.capture['tables'][0]['rows']):
            for j in range(len(row)):
                bad=copy.deepcopy(self.capture);bad['tables'][0]['rows'][i][j]+=' changed'
                with self.subTest(row=i,column=j),self.assertRaises(ValueError): parse_capture(bad,'the-pick')
        for part in ('howToPlay','sectionText'):
            bad=copy.deepcopy(self.capture)
            if part=='howToPlay': bad[part]=''
            else: bad['tables'][0][part]=''
            with self.assertRaises(ValueError): parse_capture(bad,'the-pick')


class PickThreeRulesTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/pick-3-rules.json').read_text())

    def test_play_columns_and_sales_limits_remain_distinct(self):
        rule=parse_capture(self.capture,'pick-3');table=rule['tables'][0]
        self.assertEqual(len(table['rows']),10)
        self.assertEqual(table['rows'][0],['Play Type','Odds','2 Play Prize','1 Play Prize'])
        self.assertEqual(table['rows'][1][2:],['$250','$500'])
        self.assertIn('maximum sales limit',table['sectionText'])
        self.assertIn('000 – 999',rule['howToPlay'])
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_changed_cells_and_missing_prose_rejected(self):
        for i,row in enumerate(self.capture['tables'][0]['rows']):
            for j in range(len(row)):
                bad=copy.deepcopy(self.capture);bad['tables'][0]['rows'][i][j]+=' changed'
                with self.subTest(row=i,column=j),self.assertRaises(ValueError): parse_capture(bad,'pick-3')
        for part in ('howToPlay','sectionText'):
            bad=copy.deepcopy(self.capture)
            if part=='howToPlay': bad[part]=''
            else: bad['tables'][0][part]=''
            with self.assertRaises(ValueError): parse_capture(bad,'pick-3')


class PickFourRulesTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/pick-4-rules.json').read_text())

    def test_play_columns_and_sales_limits_remain_distinct(self):
        rule=parse_capture(self.capture,'pick-4');table=rule['tables'][0]
        self.assertEqual(len(table['rows']),17)
        self.assertEqual(table['rows'][0],['Play Type','Odds','2 Play Prize','1 Play Prize'])
        self.assertEqual(table['rows'][1][2:],['$2,500','$5,000'])
        self.assertIn('maximum sales limit',table['sectionText'])
        self.assertIn('0000 – 9999',rule['howToPlay'])
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_changed_cells_and_missing_prose_rejected(self):
        for i,row in enumerate(self.capture['tables'][0]['rows']):
            for j in range(len(row)):
                bad=copy.deepcopy(self.capture);bad['tables'][0]['rows'][i][j]+=' changed'
                with self.subTest(row=i,column=j),self.assertRaises(ValueError): parse_capture(bad,'pick-4')
        for part in ('howToPlay','sectionText'):
            bad=copy.deepcopy(self.capture)
            if part=='howToPlay': bad[part]=''
            else: bad['tables'][0][part]=''
            with self.assertRaises(ValueError): parse_capture(bad,'pick-4')


class TripleTwistRulesTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/triple-twist-rules.json').read_text())

    def test_line_and_combined_line_schedules_are_separate(self):
        rule=parse_capture(self.capture,'triple-twist')
        self.assertEqual([len(t['rows']) for t in rule['tables']],[6,7])
        self.assertEqual([r[0] for r in rule['tables'][0]['matchingSymbols'][1:5]],[6,5,4,3])
        self.assertEqual(rule['tables'][1]['rows'][1],['10+ of 18','$2,000','142,824.9**'])
        self.assertIn('two additional rows of six numbers',rule['howToPlay'])
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_both_tables_symbols_and_prose_are_gated(self):
        for t,table in enumerate(self.capture['tables']):
            for i,row in enumerate(table['rows']):
                for j in range(len(row)):
                    bad=copy.deepcopy(self.capture);bad['tables'][t]['rows'][i][j]+=' changed'
                    with self.subTest(table=t,row=i,column=j),self.assertRaises(ValueError): parse_capture(bad,'triple-twist')
            bad=copy.deepcopy(self.capture);bad['tables'][t]['sectionText']=''
            with self.assertRaises(ValueError): parse_capture(bad,'triple-twist')
        bad=copy.deepcopy(self.capture);bad['tables'][0]['matchingSymbols'][1][0]=5
        with self.assertRaises(ValueError): parse_capture(bad,'triple-twist')
        bad=copy.deepcopy(self.capture);bad['tables'].pop()
        with self.assertRaises(ValueError): parse_capture(bad,'triple-twist')
        bad=copy.deepcopy(self.capture);bad['howToPlay']=''
        with self.assertRaises(ValueError): parse_capture(bad,'triple-twist')
