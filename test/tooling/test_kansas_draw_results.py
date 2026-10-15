import copy
import json
from pathlib import Path
import unittest
from tooling.kansas_draw_results import parse_results

FIXTURES = Path(__file__).parents[1] / 'fixtures/kansas'
RETRIEVED = '2026-10-15T01:00:00Z'


class KansasResultsTests(unittest.TestCase):
    def payload(self, slug='pick-3'):
        return json.loads((FIXTURES / f'{slug}.json').read_text())

    def test_three_groups_and_local_dates(self):
        for slug, group in [('pick-3', 'pick3-evening'), ('pick-3-midday', 'pick3-midday'), ('super-kansas-cash', 'super-kansas-cash')]:
            reports = parse_results(self.payload(slug), group, RETRIEVED)
            self.assertEqual(2, len(reports))
            self.assertEqual(group, reports[0]['group'])
        evening = parse_results(self.payload(), 'pick3-evening', RETRIEVED)[0]
        self.assertEqual('2026-10-13', evening['drawDate'])
        self.assertEqual('2026-10-14', evening['sourceDrawingDate'])
        self.assertTrue(evening['sourceWarnings'])

    def test_digit_order_zero_and_repeats(self):
        p = self.payload()
        for cell, value in zip(p['content'][0]['resultData'], [0, 0, 7]):
            cell['data'] = value
        self.assertEqual(['0', '0', '7'], parse_results(p, 'pick3-evening', RETRIEVED)[0]['numbers'])
        midday = parse_results(self.payload('pick-3-midday'), 'pick3-midday', RETRIEVED)[0]
        self.assertEqual(['2', '7', '7'], midday['numbers'])
        self.assertEqual([], midday['sourceWarnings'])

    def test_unverified_counts_and_prizes_never_promoted(self):
        p = self.payload('super-kansas-cash')
        baseline = parse_results(p, 'super-kansas-cash', RETRIEVED)
        p['content'][0]['prizeTiers'] = [{'shareCount': 999999, 'shareAmount': 8}]
        p['content'][0]['cashAmount'] = 99999999
        self.assertEqual(baseline, parse_results(p, 'super-kansas-cash', RETRIEVED))

    def test_rejects_bad_associations_dates_types_variants(self):
        mutations = [lambda r:r.update(gameId=9), lambda r:r.update(isDoublePlayResult=True),
                     lambda r:r.update(jackpotStatus='PAYABLE'),lambda r:r.update(drawDate='2026-10-14T14:10:00Z'),
                     lambda r:r.update(drawingDate='2026-10-13'),lambda r:r.update(id=True),
                     lambda r:r.update(externalId=''),lambda r:r.update(multiplier=2),
                     lambda r:r['resultData'][0].update(order=1),lambda r:r['resultData'][0].update(resultId=1),
                     lambda r:r['resultData'][0].update(data=True),lambda r:r['resultData'][0].update(data=10),
                     lambda r:r['resultData'][0].update(type='SPECIAL')]
        for mutation in mutations:
            p=self.payload();mutation(p['content'][0])
            with self.subTest(mutation=mutation), self.assertRaises(ValueError):
                parse_results(p,'pick3-evening',RETRIEVED)

    def test_page_duplicates_future_and_unordered_fail(self):
        p=self.payload()
        cases=[]
        for key,value in [('first',False),('number',1),('numberOfElements',3),('totalElements',1)]:
            q=copy.deepcopy(p);q[key]=value;cases.append(q)
        q=copy.deepcopy(p);q['content'].reverse();cases.append(q)
        q=copy.deepcopy(p);q['content'][1]=copy.deepcopy(q['content'][0]);cases.append(q)
        for q in cases:
            with self.assertRaises(ValueError):parse_results(q,'pick3-evening',RETRIEVED)
        with self.assertRaises(ValueError):parse_results(p,'pick3-evening','2026-10-13T00:00:00Z')

    def test_invalid_older_row_is_not_hidden_by_bounding(self):
        p = self.payload()
        older = copy.deepcopy(p['content'][1])
        older.update(id=199000, externalId='16190', drawDate='2026-10-12T02:10:00Z', drawingDate='2026-10-12')
        for cell in older['resultData']:
            cell['resultId'] = 199000
        p['content'].append(older)
        p.update(size=3, numberOfElements=3)
        self.assertEqual(2, len(parse_results(p, 'pick3-evening', RETRIEVED)))
        older['resultData'][0]['data'] = -1
        with self.assertRaises(ValueError):
            parse_results(p, 'pick3-evening', RETRIEVED)

    def test_multistate_groups_and_variants(self):
        for slug, group in [('powerball','powerball'),('powerball-double-play','powerball-double-play'),
                            ('megamillions','mega-millions'),('lotto-america','lotto-america'),
                            ('millionaire-for-life','millionaire-for-life')]:
            reports = parse_results(self.payload(slug), group, RETRIEVED)
            self.assertEqual(2, len(reports))
            self.assertIsNone(reports[0]['drawNumber'])
            self.assertTrue(reports[0]['sourceExternalId'])
            self.assertEqual(5, len(reports[0]['numbers']))
            self.assertEqual(1, len(reports[0]['specialNumbers']))
            self.assertTrue(reports[0]['sourceWarnings'])
        with self.assertRaises(ValueError):
            parse_results(self.payload('powerball-double-play'), 'powerball', RETRIEVED)
        with self.assertRaises(ValueError):
            parse_results(self.payload('powerball'), 'powerball-double-play', RETRIEVED)

    def test_multistate_ranges_and_multipliers(self):
        for slug, group, maximum in [('powerball','powerball',26),('megamillions','mega-millions',24),
                                     ('lotto-america','lotto-america',10),('millionaire-for-life','millionaire-for-life',5)]:
            p = self.payload(slug)
            p['content'][0]['resultData'][5]['data'] = maximum + 1
            with self.assertRaises(ValueError): parse_results(p, group, RETRIEVED)
        for slug, group, value in [('powerball','powerball',None),('powerball','powerball',True),
                                   ('lotto-america','lotto-america',10),('megamillions','mega-millions',2),
                                   ('powerball-double-play','powerball-double-play',2)]:
            p = self.payload(slug);p['content'][0]['multiplier'] = value
            with self.assertRaises(ValueError): parse_results(p, group, RETRIEVED)

    def test_old_mega_millions_and_wrong_id_rejected(self):
        p = self.payload('megamillions')
        p['content'][0]['gameId'] = 2
        with self.assertRaises(ValueError): parse_results(p, 'mega-millions', RETRIEVED)
        p = self.payload('megamillions')
        for row, day in zip(p['content'], ['05','04']):
            row['drawDate'] = f'2025-04-{day}T03:00:00Z'
            row['drawingDate'] = f'2025-04-{day}'
        with self.assertRaises(ValueError): parse_results(p, 'mega-millions', RETRIEVED)

    def test_cash_ball_range_and_duplicates(self):
        for index,value in [(0,33),(5,26),(1,7)]:
            p=self.payload('super-kansas-cash');p['content'][0]['resultData'][index]['data']=value
            with self.assertRaises(ValueError):parse_results(p,'super-kansas-cash',RETRIEVED)

if __name__ == '__main__':
    unittest.main()
