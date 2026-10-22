import copy
from datetime import date
import json
from pathlib import Path
import unittest

from tooling.idaho_draw_results import parse_results

SAMPLES = json.loads((Path(__file__).parent / 'fixtures/idaho_result_samples.json').read_text())


class IdahoResultsTest(unittest.TestCase):
    def parse(self, slug='powerball', payload=None, requested=None):
        payload = copy.deepcopy(SAMPLES[slug]) if payload is None else payload
        return parse_results(payload, slug, requested or payload['data']['draw_date'], as_of=date(2026, 10, 22))

    def test_all_captured_families_and_groups(self):
        results = [r for slug in SAMPLES for r in self.parse(slug)]
        self.assertEqual(len(results), 10)
        self.assertEqual(len({r['group'] for r in results}), 10)
        self.assertEqual(self.parse('pick-4')[1]['numbers'], ['0', '4', '1', '3'])
        self.assertNotIn('multiplier', self.parse('mega-millions')[0])

    def test_excluded_source_fields(self):
        p = copy.deepcopy(SAMPLES['powerball'])
        p['data'].update(jackpot='conflicting', cash='next draw', winners=[{'count': 0}])
        self.assertEqual(self.parse(payload=p), self.parse())
        self.assertNotIn('multiplier', self.parse()[1])

    def test_wrong_identity_date_and_success(self):
        for key, value in [('game', 'Mega Millions'), ('draw_date', '2026-10-20'), ('title', 'wrong')]:
            p = copy.deepcopy(SAMPLES['powerball']); p['data'][key] = value
            with self.subTest(key=key), self.assertRaises(ValueError):
                self.parse(payload=p, requested='2026-10-21')
        p = copy.deepcopy(SAMPLES['powerball']); p['success'] = 1
        with self.assertRaises(ValueError): self.parse(payload=p)
        for d in ['2026-02-30', '20261021', '2026-10-23']:
            with self.assertRaises(ValueError): self.parse(requested=d)

    def test_incomplete_duplicate_and_ordered_balls(self):
        for mutation in ['missing', 'duplicate', 'weight', 'label', 'range', 'bool', 'decimal', 'multiplier']:
            p = copy.deepcopy(SAMPLES['powerball']); rows = p['data']['winning_numbers']
            if mutation == 'missing': rows.pop()
            elif mutation == 'duplicate': rows[1]['1'] = rows[0]['1']
            elif mutation == 'weight': rows[1]['weight'] = 0
            elif mutation == 'label': rows[0]['0'] = 'megaball 1'
            elif mutation == 'multiplier': rows[-1]['1'] = '06'
            else: rows[0]['1'] = {'range': '70', 'bool': True, 'decimal': '1.0'}[mutation]
            with self.subTest(mutation=mutation), self.assertRaises(ValueError): self.parse(payload=p)

    def test_missing_or_unexpected_variants(self):
        p = copy.deepcopy(SAMPLES['powerball']); p['data']['winning_numbers_dp'] = None
        with self.assertRaises(ValueError): self.parse(payload=p)
        p = copy.deepcopy(SAMPLES['pick-3']); p['data']['winning_numbers_2'] = None
        with self.assertRaises(ValueError): self.parse('pick-3', p)
        p = copy.deepcopy(SAMPLES['mega-millions']); p['data']['winning_numbers_dp'] = []
        with self.assertRaises(ValueError): self.parse('mega-millions', p)

    def test_pick_digit_width_and_positions(self):
        for key, value in [('1', '05'), ('0', 'white-balls 8')]:
            p = copy.deepcopy(SAMPLES['pick-3']); p['data']['winning_numbers'][0][key] = value
            with self.assertRaises(ValueError): self.parse('pick-3', p)

    def test_team_codes_not_names(self):
        r = self.parse('powerball-xs-os')[0]
        self.assertEqual(r['numbers'][0], '03')
        self.assertTrue(r['imageUrls'][0].endswith('/03.png'))
        p = copy.deepcopy(SAMPLES['powerball-xs-os']); p['data']['winning_numbers'][0]['1'] = '33'
        with self.assertRaises(ValueError): self.parse('powerball-xs-os', p)

    def test_canonical_string_weights_only(self):
        p = copy.deepcopy(SAMPLES['powerball-xs-os'])
        for row in p['data']['winning_numbers']: row['weight'] = str(row['weight'])
        self.assertEqual(self.parse('powerball-xs-os', p), self.parse('powerball-xs-os'))
        for invalid in ['00', ' 0', True, 0.0]:
            p['data']['winning_numbers'][0]['weight'] = invalid
            with self.subTest(invalid=invalid), self.assertRaises(ValueError): self.parse('powerball-xs-os', p)


if __name__ == '__main__':
    unittest.main()
