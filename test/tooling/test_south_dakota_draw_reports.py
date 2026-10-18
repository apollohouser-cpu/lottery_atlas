from datetime import datetime, timezone
import json
from pathlib import Path
import unittest
from tooling.south_dakota_draw_reports import parse_reports
from tooling.south_dakota_draw_results import SPECS
ROOT=Path(__file__).parent/'fixtures'/'south_dakota'
NOW=datetime(2026,10,18,12,tzinfo=timezone.utc)

class ReportTest(unittest.TestCase):
    def payload(self,s='powerball-power-play'):
        return json.loads((ROOT/f'draws-{s}.json').read_text())
    def test_all_reports_two_explicit_mm_gaps(self):
        rows=[r for s in SPECS for r in parse_reports(self.payload(s),s,now=NOW)]
        self.assertEqual(14,len(rows));self.assertEqual(2,sum(not r['tiers'] for r in rows))
    def test_dp_not_base_or_multiplier(self):
        rows=parse_reports(self.payload(),'powerball-power-play',now=NOW)
        dp=next(r for r in rows if r['variant']=='Double Play')
        self.assertEqual(9,len(dp['tiers']));self.assertIsNone(dp['optionLabel'])
        self.assertTrue(all(t['sdOptionWinners'] is None for t in dp['tiers']))
        self.assertEqual(500000,dp['tiers'][1]['prizeAmountDollars'])
        self.assertIsNone(dp['tiers'][0]['prizeAmountDollars'])
    def test_option_counts_not_bounded_by_base_counts(self):
        r=parse_reports(self.payload(),'powerball-power-play',now=NOW)
        base=next(x for x in r if x['variant']=='Regular')
        self.assertEqual(0,base['tiers'][4]['sdWinners']);self.assertEqual(2,base['tiers'][4]['sdOptionWinners'])
    def test_annuity_and_team_amounts_not_numeric_claims(self):
        for s in ('millionaire-for-life','xs-and-os'):
            r=parse_reports(self.payload(s),s,now=NOW)[0]
            self.assertIsNone(r['tiers'][0]['prizeAmountDollars'])
            self.assertTrue(r['tiers'][0]['prizeLabel'])
    def test_missing_changed_or_duplicate_tiers(self):
        for mode in ('missing','duplicate','changed'):
            d=self.payload();t=d['draws'][1]['prizeTiers']
            if mode=='missing':t.pop()
            elif mode=='duplicate':t[1]=t[0].copy()
            else:t[0]['name']='invented'
            with self.subTest(mode=mode),self.assertRaises(ValueError):parse_reports(d,'powerball-power-play',now=NOW)
    def test_negative_boolean_missing_counts_fail(self):
        for value in (-1,True,None,1.5):
            d=self.payload();d['draws'][1]['prizeTiers'][0]['shareCount']=value
            with self.subTest(value=value),self.assertRaises(ValueError):parse_reports(d,'powerball-power-play',now=NOW)
    def test_dp_multiplier_is_not_supported(self):
        d=self.payload();d['draws'][1]['prizeTiers'][9]['multiplierShareCount']=1
        with self.assertRaises(ValueError):parse_reports(d,'powerball-power-play',now=NOW)
    def test_mm_counts_never_leak(self):
        d=self.payload('mega-millions');r=parse_reports(d,'mega-millions',now=NOW)
        self.assertNotIn('shareCount',json.dumps(r));self.assertTrue(all(x['countUnit'] is None for x in r))
