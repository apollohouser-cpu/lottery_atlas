import copy
from datetime import date
import json
from pathlib import Path
import unittest
from tooling.idaho_draw_reports import parse_reports

SAMPLES = json.loads((Path(__file__).parent / 'fixtures/idaho_report_samples.json').read_text())


class IdahoReportTests(unittest.TestCase):
    def parse(self, slug, payload=None):
        p = copy.deepcopy(SAMPLES[slug]) if payload is None else payload
        return parse_reports(p, slug, p['data']['draw_date'], as_of=date(2026, 10, 22))

    def test_captured_reports_and_variants(self):
        for slug, sizes in [('powerball', [8, 9]), ('mega-millions', [41]), ('lotto-america', [17]), ('idaho-cash', [4]), ('powerball-xs-os', [5])]:
            self.assertEqual([len(r['report']['tiers']) for r in self.parse(slug)], sizes)
        tiers = self.parse('powerball')[0]['report']['tiers']
        self.assertTrue(all(x['sourceTier'].endswith('-pp') for x in tiers))
        self.assertEqual(self.parse('idaho-cash')[0]['report']['tiers'][-1]['sourceTier'], 'Free Ticket')

    def test_missing_is_not_zero(self):
        for empty in [None, []]:
            p = copy.deepcopy(SAMPLES['powerball-xs-os']); p['data']['winners'] = empty
            self.assertIsNone(self.parse('powerball-xs-os', p)[0]['report'])
        p = copy.deepcopy(SAMPLES['powerball-xs-os'])
        for row in p['data']['winners']: row['1'] = 0
        self.assertIsNotNone(self.parse('powerball-xs-os', p)[0]['report'])

    def test_national_fields_never_used(self):
        p = copy.deepcopy(SAMPLES['idaho-cash']); p['data']['winners_national'] = [{'0':'Jackpot','1':999}]
        self.assertEqual(self.parse('idaho-cash', p), self.parse('idaho-cash'))

    def test_tier_and_count_mutations(self):
        for mutation in ['missing', 'duplicate', 'national', 'negative', 'float', 'bool', 'text', 'unsafe']:
            p = copy.deepcopy(SAMPLES['mega-millions']); rows = p['data']['winners']
            if mutation == 'missing': rows.pop()
            elif mutation == 'duplicate': rows[1]['0'] = rows[0]['0']
            elif mutation == 'national': rows[1]['0'] = 'national-m5'
            else: rows[1]['1'] = {'negative':-1,'float':1.5,'bool':True,'text':'N/A','unsafe':9007199254740992}[mutation]
            with self.subTest(mutation=mutation), self.assertRaises(ValueError): self.parse('mega-millions', p)

    def test_exact_date_required(self):
        p = SAMPLES['idaho-cash']
        with self.assertRaises(ValueError): parse_reports(p, 'idaho-cash', '2026-10-20', as_of=date(2026,10,22))


if __name__ == '__main__': unittest.main()
