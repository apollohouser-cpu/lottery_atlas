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


class XsOsDetailTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/powerball-xs-os-rule-details.json').read_text())

    def test_conflicting_cutoff_is_disclosed_not_normalized(self):
        rule=parse_capture(self.capture,'powerball-xs-os')
        self.assertIn('8:59 p.m.',rule['sections'][0]['text'])
        self.assertIn('5:59/6:59',rule['sourceConflicts'][0])
        self.assertNotIn('salesCutoff',rule)
        self.assertFalse(rule['actualPayoutsAvailable'])
        rule['sourceConflicts'].clear()
        self.assertEqual(len(parse_capture(self.capture,'powerball-xs-os')['sourceConflicts']),1)

    def test_removed_conflicting_prose_or_source_links_rejected(self):
        for i,section in enumerate(self.capture['sections']):
            bad=copy.deepcopy(self.capture);bad['sections'][i]['text']=''
            with self.assertRaises(ValueError):parse_capture(bad,'powerball-xs-os')
            for j in range(len(section['links'])):
                bad=copy.deepcopy(self.capture);bad['sections'][i]['links'][j]['href']='https://example.com/'
                with self.assertRaises(ValueError):parse_capture(bad,'powerball-xs-os')


class MegaMillionsDetailTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/mega-millions-rule-details.json').read_text())

    def test_current_matrix_and_jackpot_exception_remain_literal(self):
        rule=parse_capture(self.capture,'mega-millions')
        self.assertIn('Five white balls (1 – 70)',rule['sections'][0]['text'])
        self.assertIn('One Mega Ball number (1 – 24)',rule['sections'][0]['text'])
        self.assertIn('tickets cost $5 per game',rule['sections'][0]['text'])
        self.assertIn('Multipliers do not apply to the jackpot',rule['sections'][1]['text'])
        self.assertFalse(rule['actualPayoutsAvailable'])
        self.assertNotIn('drawMultiplier',rule)

    def test_changed_matrix_cutoff_and_links_fail_closed(self):
        for i,section in enumerate(self.capture['sections']):
            bad=copy.deepcopy(self.capture);bad['sections'][i]['text']=''
            with self.assertRaises(ValueError):parse_capture(bad,'mega-millions')
            for j in range(len(section['links'])):
                bad=copy.deepcopy(self.capture);bad['sections'][i]['links'][j]['href']='https://example.com/'
                with self.assertRaises(ValueError):parse_capture(bad,'mega-millions')
        for old,new in [('1 – 24','1 – 25'),('$5','$2')]:
            bad=copy.deepcopy(self.capture);bad['sections'][0]['text']=bad['sections'][0]['text'].replace(old,new)
            with self.assertRaises(ValueError):parse_capture(bad,'mega-millions')


class ThePickDetailTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/the-pick-rule-details.json').read_text())

    def test_all_five_plus_schedules_and_cash_default_preserved(self):
        rule=parse_capture(self.capture,'the-pick')
        self.assertEqual(len(rule['sections']),7)
        self.assertEqual([s['text'].splitlines()[0] for s in rule['sections'][2:]],
                         [f'${i} The Pick Plus game' for i in range(1,6)])
        self.assertIn('$2, $5, $10, $20',rule['sections'][2]['text'])
        self.assertIn('$47, $50.',rule['sections'][6]['text'])
        self.assertIn('prints and plays separately',rule['sections'][0]['text'])
        self.assertIn('paid as a lump sum of cash',rule['sections'][1]['text'])
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_lost_accordion_or_changed_prose_rejected(self):
        for i in range(len(self.capture['sections'])):
            bad=copy.deepcopy(self.capture);bad['sections'].pop(i)
            with self.assertRaises(ValueError):parse_capture(bad,'the-pick')
            bad=copy.deepcopy(self.capture);bad['sections'][i]['text']+=' changed'
            with self.assertRaises(ValueError):parse_capture(bad,'the-pick')


class FantasyFiveDetailTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/fantasy-5-rule-details.json').read_text())

    def test_extra_is_separate_and_doubler_exclusions_preserved(self):
        rule=parse_capture(self.capture,'fantasy-5');text=rule['sections'][0]['text']
        self.assertIn('EXTRA! numbers are not associated with draw numbers',text)
        self.assertIn('The Doubler feature does not apply to EXTRA!',text)
        self.assertIn('Approximately one in every 10 tickets',text)
        self.assertIn('doubles all non-jackpot prizes',text)
        self.assertIn('up to 12 consecutive drawing dates',rule['sections'][1]['text'])
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_lost_exclusions_or_changed_links_rejected(self):
        for i,section in enumerate(self.capture['sections']):
            bad=copy.deepcopy(self.capture);bad['sections'][i]['text']=''
            with self.assertRaises(ValueError):parse_capture(bad,'fantasy-5')
            for j in range(len(section['links'])):
                bad=copy.deepcopy(self.capture);bad['sections'][i]['links'][j]['href']='https://example.com/'
                with self.assertRaises(ValueError):parse_capture(bad,'fantasy-5')
        bad=copy.deepcopy(self.capture);bad['sections'][0]['text']=bad['sections'][0]['text'].replace('does not apply','applies')
        with self.assertRaises(ValueError):parse_capture(bad,'fantasy-5')


class PickThreeDetailTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/pick-3-rule-details.json').read_text())

    def test_box_semantics_and_two_sessions_preserved(self):
        rule=parse_capture(self.capture,'pick-3');text=rule['sections'][0]['text']
        self.assertIn('Two of the three numbers you select must be the same',text)
        self.assertIn('All three of the numbers you select must be different',text)
        self.assertIn('000 – 999',text)
        self.assertIn('maximum sales limit',rule['sections'][1]['text'])
        self.assertIn('11:59 AM',rule['sections'][1]['text'])
        self.assertIn('6:59 PM',rule['sections'][1]['text'])
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_changed_box_definition_and_missing_limits_rejected(self):
        for i,section in enumerate(self.capture['sections']):
            bad=copy.deepcopy(self.capture);bad['sections'][i]['text']=''
            with self.assertRaises(ValueError):parse_capture(bad,'pick-3')
            for j in range(len(section['links'])):
                bad=copy.deepcopy(self.capture);bad['sections'][i]['links'][j]['href']='https://example.com/'
                with self.assertRaises(ValueError):parse_capture(bad,'pick-3')
        bad=copy.deepcopy(self.capture);bad['sections'][0]['text']=bad['sections'][0]['text'].replace('must be the same','must be different')
        with self.assertRaises(ValueError):parse_capture(bad,'pick-3')


class PickFourDetailTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/pick-4-rule-details.json').read_text())

    def test_conflicting_box_wording_and_wrong_odds_link_disclosed(self):
        rule=parse_capture(self.capture,'pick-4')
        self.assertEqual(len(rule['sourceConflicts']),2)
        self.assertIn('All four numbers selected are different',rule['sections'][0]['text'])
        self.assertIn('two of the four numbers selected are different',rule['sections'][0]['text'])
        self.assertTrue(any(link['href'].endswith('/pick-3/') for link in rule['sections'][1]['links']))
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_silent_source_corrections_rejected(self):
        bad=copy.deepcopy(self.capture)
        bad['sections'][0]['text']=bad['sections'][0]['text'].replace('two of the four numbers selected are different','all four numbers selected are different')
        with self.assertRaises(ValueError):parse_capture(bad,'pick-4')
        bad=copy.deepcopy(self.capture)
        for link in bad['sections'][1]['links']:link['href']=link['href'].replace('/pick-3/','/pick-4/')
        with self.assertRaises(ValueError):parse_capture(bad,'pick-4')


class TripleTwistDetailTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/triple-twist-rule-details.json').read_text())

    def test_three_rows_are_ticket_rules_and_cutoff_conflict_disclosed(self):
        rule=parse_capture(self.capture,'triple-twist')
        self.assertIn('remaining two rows of six numbers',rule['sections'][0]['text'])
        self.assertIn('up to four times on a single game',rule['sections'][0]['text'])
        self.assertIn('7:59 pm',rule['sections'][1]['text'])
        self.assertIn('Sales cutoff unresolved',rule['sourceConflicts'][0])
        self.assertNotIn('ticketPositions',rule)
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_changed_rows_or_silently_corrected_cutoff_rejected(self):
        for i,old,new in [(0,'remaining two rows','remaining three rows'),(1,'7:59 pm','6:59 pm')]:
            bad=copy.deepcopy(self.capture);bad['sections'][i]['text']=bad['sections'][i]['text'].replace(old,new)
            with self.assertRaises(ValueError):parse_capture(bad,'triple-twist')
        bad=copy.deepcopy(self.capture);bad['sections'].pop()
        with self.assertRaises(ValueError):parse_capture(bad,'triple-twist')


class HiLoDetailTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/hi-lo-rule-details.json').read_text())

    def test_wager_matched_bonus_and_literal_labels_preserved(self):
        rule=parse_capture(self.capture,'hi-lo');text=rule['sections'][0]['text']
        self.assertIn('same cost as your base wager',text)
        self.assertIn('1X, 2X, 3X, 4X, or 5X',text)
        self.assertIn('4:10 AM',text)
        self.assertIn('11:10 PM',text)
        self.assertIn('TWO TO WIN PRIZE',text)
        self.assertTrue(rule['sourceConflicts'])
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_changed_bonus_cost_or_missing_caveats_rejected(self):
        for old,new in [('same cost as your base wager','$1'),('$55,500','$555'),('TWO TO WIN PRIZE','HI-LO PRIZE')]:
            bad=copy.deepcopy(self.capture);bad['sections'][0]['text']=bad['sections'][0]['text'].replace(old,new)
            with self.assertRaises(ValueError):parse_capture(bad,'hi-lo')
        bad=copy.deepcopy(self.capture);bad['sections']=[]
        with self.assertRaises(ValueError):parse_capture(bad,'hi-lo')


class LuckyLinksDetailTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/lucky-links-rule-details.json').read_text())

    def test_grid_rule_does_not_invent_ticket_positions(self):
        rule=parse_capture(self.capture,'lucky-links');text=rule['sections'][0]['text']
        self.assertIn('3x3 grid',text)
        self.assertIn('7 lines automatically forms 8 lines',text)
        self.assertIn('5:00 AM',text)
        self.assertIn('$125,000',text)
        self.assertIn('Super Bonus for $1',text)
        self.assertNotIn('ticketPositions',rule)
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_grid_bonus_and_sharing_changes_fail_closed(self):
        for old,new in [('3x3','4x4'),('Super Bonus for $1','Super Bonus for $2'),('$125,000','$25,000')]:
            bad=copy.deepcopy(self.capture);bad['sections'][0]['text']=bad['sections'][0]['text'].replace(old,new)
            with self.assertRaises(ValueError):parse_capture(bad,'lucky-links')
        bad=copy.deepcopy(self.capture);bad['sections']=[]
        with self.assertRaises(ValueError):parse_capture(bad,'lucky-links')


class OneToWinDetailTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/one-to-win-rule-details.json').read_text())

    def test_wager_is_not_an_extra_draw_multiplier(self):
        rule=parse_capture(self.capture,'one-to-win');text=rule['sections'][0]['text']
        self.assertIn('Your wager acts as a multiplier',text)
        self.assertIn('Bet All',text)
        self.assertIn('$250 prize draw is above $200,000',text)
        self.assertIn('rounded down to the nearest dollar',text)
        self.assertIn('4:45 AM',text)
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_changed_liability_wager_and_missing_sections_rejected(self):
        for old,new in [('$200,000','$250,000'),('rounded down','rounded up'),('fifteen times','twenty times')]:
            bad=copy.deepcopy(self.capture);bad['sections'][0]['text']=bad['sections'][0]['text'].replace(old,new)
            with self.assertRaises(ValueError):parse_capture(bad,'one-to-win')
        bad=copy.deepcopy(self.capture);bad['sections']=[]
        with self.assertRaises(ValueError):parse_capture(bad,'one-to-win')


class TwoToWinDetailTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/two-to-win-rule-details.json').read_text())

    def test_wager_prizes_bonus_and_sharing_preserved(self):
        rule=parse_capture(self.capture,'two-to-win');text=rule['sections'][0]['text']
        self.assertIn('00 - 99',text)
        self.assertIn('Straight, Box, Front or Back',text)
        self.assertIn('Super Bonus for $1',text)
        self.assertIn('above $60,000',text)
        self.assertIn('4:20 AM',text)
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_changed_bonus_and_sharing_rejected(self):
        for old,new in [('Super Bonus for $1','Super Bonus for $2'),('above $60,000','above $6,000'),('00 - 99','01 - 99')]:
            bad=copy.deepcopy(self.capture);bad['sections'][0]['text']=bad['sections'][0]['text'].replace(old,new)
            with self.assertRaises(ValueError):parse_capture(bad,'two-to-win')
        bad=copy.deepcopy(self.capture);bad['sections']=[]
        with self.assertRaises(ValueError):parse_capture(bad,'two-to-win')


class MoneyRollDetailTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/money-roll-rule-details.json').read_text())

    def test_ordered_dice_and_literal_liability_condition_preserved(self):
        rule=parse_capture(self.capture,'money-roll');text=rule['sections'][0]['text']
        self.assertIn('Quick Pick only',text)
        self.assertIn('same position as the drawn dice',text)
        self.assertIn('Super Bonus for $1',text)
        self.assertIn('5X multiplier drawn is $100,000',text)
        self.assertIn('4:50 AM',text)
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_changed_position_or_liability_condition_rejected(self):
        for old,new in [('same position','any position'),('drawn is $100,000','drawn is above $100,000'),('Super Bonus for $1','Super Bonus for $2')]:
            bad=copy.deepcopy(self.capture);bad['sections'][0]['text']=bad['sections'][0]['text'].replace(old,new)
            with self.assertRaises(ValueError):parse_capture(bad,'money-roll')
        bad=copy.deepcopy(self.capture);bad['sections']=[]
        with self.assertRaises(ValueError):parse_capture(bad,'money-roll')


class FiveInALineDetailTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/5-in-a-line-rule-details.json').read_text())

    def test_ordered_digits_bonus_and_sharing_preserved(self):
        rule=parse_capture(self.capture,'5-in-a-line');text=rule['sections'][0]['text']
        self.assertIn('Quick Pick only',text)
        self.assertIn('each from zero to nine',text)
        self.assertIn('exact drawn order sequence',text)
        self.assertIn('Super Bonus for $1 per play',text)
        self.assertIn('above $25,000',text)
        self.assertIn('4:30 AM',text)
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_changed_order_and_liability_rejected(self):
        for old,new in [('exact drawn order sequence','any order'),('above $25,000','above $5,000'),('zero to nine','one to nine')]:
            bad=copy.deepcopy(self.capture);bad['sections'][0]['text']=bad['sections'][0]['text'].replace(old,new)
            with self.assertRaises(ValueError):parse_capture(bad,'5-in-a-line')
        bad=copy.deepcopy(self.capture);bad['sections']=[]
        with self.assertRaises(ValueError):parse_capture(bad,'5-in-a-line')


class RemainingQuickDrawDetailTests(unittest.TestCase):
    def capture(self,game):
        return json.loads((Path(__file__).parent/f'fixtures/arizona/{game}-rule-details.json').read_text())

    def test_51045_alternative_addons_and_costs(self):
        rule=parse_capture(self.capture('51045'),'51045');text=rule['sections'][0]['text']
        for phrase in ['one of two add-ons', 'double the cost', 'triple the cost',
                       '2X, 3X, 4X, 5X, 6X, 10X, 12X and 20X', 'above $200,000', '4:15 AM']:
            self.assertIn(phrase,text)
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_pick_your_bet_wager_cost_and_source_label(self):
        rule=parse_capture(self.capture('pick-your-bet'),'pick-your-bet');text=rule['sections'][0]['text']
        for phrase in ['$2, $4, $6, $10, or $20', 'same cost as your base wager', '1 - 38', '4:40 AM']:
            self.assertIn(phrase,text)
        self.assertEqual(len(rule['sourceConflicts']),1)
        self.assertFalse(rule['actualPayoutsAvailable'])

    def test_addon_cost_changes_fail_closed(self):
        for game,old,new in [('51045','triple the cost','double the cost'),
                             ('pick-your-bet','same cost as your base wager','$1')]:
            bad=self.capture(game);bad['sections'][0]['text']=bad['sections'][0]['text'].replace(old,new)
            with self.assertRaises(ValueError):parse_capture(bad,game)

    def test_missing_caveats_fail_closed(self):
        for game in ['51045','pick-your-bet']:
            bad=self.capture(game);bad['sections'][0]['text']=bad['sections'][0]['text'].split('DISCLAIMERS')[0]
            with self.assertRaises(ValueError):parse_capture(bad,game)


class FastPlayProhibitionTests(unittest.TestCase):
    def setUp(self):
        self.capture=json.loads((Path(__file__).parent/'fixtures/arizona/fast-play-prohibition-rule-details.json').read_text())
    def test_aggregate_restriction_retained(self):
        rule=parse_capture(self.capture,'fast-play-prohibition')
        text=rule['sections'][0]['text']
        for phrase in ['exceeding $50,000','twenty-four (24) hour period','multiple retail locations','acting in concert','Denial of Prize Payment']:
            self.assertIn(phrase,text)
        self.assertFalse(rule['actualPayoutsAvailable'])
    def test_changed_threshold_or_aggregation_rejected(self):
        for old,new in [('exceeding $50,000','exceeding $500,000'),('twenty-four (24)','forty-eight (48)'),('multiple retail locations','one retail location')]:
            c=copy.deepcopy(self.capture);c['sections'][0]['text']=c['sections'][0]['text'].replace(old,new)
            with self.assertRaises(ValueError):parse_capture(c,'fast-play-prohibition')
