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
