import copy
from datetime import datetime, timezone
import json
from pathlib import Path
import unittest
from tooling.south_dakota_draw_results import parse_results, SPECS

FIXTURES = Path(__file__).parent / 'fixtures' / 'south_dakota'
NOW = datetime(2026, 10, 18, 10, tzinfo=timezone.utc)


class SouthDakotaResultsTest(unittest.TestCase):
    def payload(self, slug='powerball-power-play'):
        return json.loads((FIXTURES / f'draws-{slug}.json').read_text())

    def reject(self, mutate, slug='powerball-power-play'):
        data = self.payload(slug)
        mutate(data)
        with self.assertRaises(ValueError):
            parse_results(data, slug, now=NOW)

    def test_all_six_families_fourteen_results(self):
        rows = [r for s in SPECS for r in parse_results(self.payload(s), s, now=NOW)]
        self.assertEqual(14, len(rows))
        self.assertEqual(7, len({(r['game'], r['variant']) for r in rows}))
        self.assertTrue(all('prizeTiers' not in r and 'estimatedJackpot' not in r for r in rows))

    def test_utc_midnight_is_previous_central_date(self):
        rows = parse_results(self.payload(), 'powerball-power-play', now=NOW)
        self.assertEqual('2026-10-17', rows[0]['drawDate'])
        self.assertEqual('2026-10-18', datetime.fromtimestamp(rows[0]['rawDrawTime']/1000, timezone.utc).date().isoformat())

    def test_response_order_not_semantic(self):
        data = self.payload(); expected = parse_results(data, 'powerball-power-play', now=NOW)
        data['draws'].reverse()
        self.assertEqual(expected, parse_results(data, 'powerball-power-play', now=NOW))

    def test_variant_sources_and_multiplier_separation(self):
        rows = parse_results(self.payload(), 'powerball-power-play', now=NOW)
        for r in rows:
            if r['variant'] == 'Double Play':
                self.assertIsNone(r['multiplier'])
                self.assertTrue(r['sourceUrl'].endswith('powerball-double-play/'))
            else:
                self.assertIn(r['multiplier'], {2,3,4,5,10})

    def test_bad_identity_status_and_calendar(self):
        for key, value in [('gameName','Mega Millions'), ('status','NO_MORE_DRAWS'), ('id',True), ('drawTime',True), ('drawTime',-1), ('drawDay',['SUNDAY'])]:
            with self.subTest(key=key):
                self.reject(lambda d: d['draws'][1].update({key:value}))

    def test_missing_extra_duplicate_draws(self):
        self.reject(lambda d: d['draws'].pop())
        self.reject(lambda d: d['draws'].append(copy.deepcopy(d['draws'][1])))
        self.reject(lambda d: d['draws'].__setitem__(2, copy.deepcopy(d['draws'][1])))

    def test_wrong_number_domain_and_duplicates(self):
        for values in [['12','12','24','32','35'], ['0','13','24','32','35'], ['70','13','24','32','35'], [12,'13','24','32','35'], ['12']]:
            with self.subTest(values=values):
                self.reject(lambda d: d['draws'][1]['results'][0].update(primary=values))
        self.reject(lambda d: d['draws'][1]['results'][0].update(secondary=['25']), 'mega-millions')
        self.reject(lambda d: d['draws'][1]['results'][0].update(secondary=['1']), 'dakota-cash')

    def test_missing_duplicate_or_swapped_variant(self):
        self.reject(lambda d: d['draws'][1]['results'].pop())
        self.reject(lambda d: d['draws'][1]['results'][1].update(prizeTierId='Regular'))
        self.reject(lambda d: d['draws'][1]['results'][1].update(prizeTierId='Power Play'))

    def test_multiplier_contract(self):
        self.reject(lambda d: d['draws'][1]['results'][0].update(multiplier=True))
        self.reject(lambda d: d['draws'][1]['results'][0].update(multiplier=6))
        self.reject(lambda d: d['draws'][1]['results'][1].update(multiplier=3))
        self.reject(lambda d: d['draws'][1]['results'][0].update(multiplier=2), 'mega-millions')

    def test_open_and_future_results_rejected(self):
        self.reject(lambda d: d['draws'][0].update(results=copy.deepcopy(d['draws'][1]['results'])))
        self.reject(lambda d: d['draws'][0].update(status='PAYABLE', results=copy.deepcopy(d['draws'][1]['results'])))
        self.reject(lambda d: d['draws'][1].update(status='OPEN'))

    def test_unknown_result_fields_fail_closed(self):
        self.reject(lambda d: d['draws'][1]['results'][0].update(tertiary=['1']))

if __name__ == '__main__':
    unittest.main()
