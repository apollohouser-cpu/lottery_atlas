import copy
import unittest
from tooling.import_wyoming_draws import SPECS, parse_draws


class WyomingDrawTests(unittest.TestCase):
    def row(self, game='powerball'):
        gid, count, _, bonus, _ = SPECS[game]
        at = {'cowboy-draw': '2026-10-22T20:00:00Z',
              'powerball': '2026-10-25T02:59:00Z',
              'mega-millions': '2026-10-24T03:00:00Z',
              'millionaire-for-life': '2026-10-25T03:15:00Z',
              '2by2': '2026-10-25T02:30:00Z'}[game]
        return {'when': {'drawTime': at}, 'results': {
            'status': 'ACTIVE', 'drawResult': {'drawGameId': gid,
            'asOf': at, 'drawingNumber': 1,
            'sequenceNumber': None, 'primary': {'winningNumbers': list(range(1, count+1)),
            'bonusNumbers': list(range(1, bonus+1)) or None,
            'multipliers': [2] if game == 'powerball' else None}}}}

    def parse(self, rows, game='powerball'):
        return parse_draws(rows, game, start='2026-10-12T00:00:00Z',
                           end='2026-10-26T00:00:00Z', retrieved_at='2026-10-27T00:00:00Z')

    def test_all_games_and_mountain_date(self):
        for game in SPECS:
            with self.subTest(game=game):
                result=self.parse([self.row(game)], game)[0]
                self.assertEqual(result['drawDate'], {'cowboy-draw': '2026-10-22',
                    'mega-millions': '2026-10-23'}.get(game, '2026-10-24'))
                self.assertEqual(result['reportStatus'], 'unavailable')
                self.assertNotIn('customerId', result)

    def test_color_groups_are_distinct(self):
        r=self.parse([self.row('2by2')], '2by2')[0]
        self.assertEqual((r['numberLabel'],r['bonusLabel']), ('White','Red'))
        self.assertEqual(r['numbers'],r['bonusNumbers'])  # Across colors is allowed.

    def test_identity_timestamp_status_and_variants(self):
        for key,value in [('drawGameId','wrong'),('asOf','2026-10-24T02:59:00Z'),
                          ('drawingNumber',True),('secondary',{}),('sequenceNumber',1)]:
            r=self.row();r['results']['drawResult'][key]=value
            with self.subTest(key=key), self.assertRaises(ValueError):self.parse([r])
        r=self.row();r['results']['status']='UNKNOWN'
        with self.assertRaises(ValueError):self.parse([r])

    def test_numbers_and_multiplier_rejected(self):
        for key,value in [('winningNumbers',[1,1,2,3,4]),('winningNumbers',[True,2,3,4,5]),
                          ('winningNumbers',[1,2,3,4,70]),('bonusNumbers',[27]),
                          ('multipliers',[True]),('multipliers',[6])]:
            r=self.row();r['results']['drawResult']['primary'][key]=value
            with self.subTest(key=key,value=value),self.assertRaises(ValueError):self.parse([r])
        r=self.row('mega-millions');r['results']['drawResult']['primary']['multipliers']=[2]
        with self.assertRaises(ValueError):self.parse([r],'mega-millions')

    def test_duplicate_and_outside_window(self):
        r=self.row()
        with self.assertRaises(ValueError):self.parse([r,copy.deepcopy(r)])
        r['when']['drawTime']='2026-10-27T02:59:00Z'
        with self.assertRaises(ValueError):self.parse([r])

    def test_pending_is_not_a_result(self):
        r=self.row();p=copy.deepcopy(r);p['when']['drawTime']='2026-10-25T03:00:00Z'
        p['results']={'status':'PENDING'}
        self.assertEqual(len(self.parse([r,p])),1)
        p['results']['drawResult']={}
        with self.assertRaises(ValueError):self.parse([r,p])

    def test_cadence_and_version_rejected(self):
        for at in ['2026-10-25T03:00:00Z', '2026-10-24T02:59:00Z',
                   '2026-10-25T02:59:00.001Z', '2026-10-11T02:59:00Z']:
            r=self.row();r['when']['drawTime']=at;r['results']['drawResult']['asOf']=at
            with self.subTest(at=at),self.assertRaises(ValueError):
                parse_draws([r], 'powerball', start='2026-10-01T00:00:00Z',
                            end='2026-10-26T00:00:00Z', retrieved_at='2026-10-27T00:00:00Z')

    def test_mountain_dst_boundary(self):
        # The local schedule survives the November offset change.
        for at, date in [('2026-11-01T02:59:00Z','2026-10-31'),
                         ('2026-11-03T03:59:00Z','2026-11-02')]:
            r=self.row();r['when']['drawTime']=at;r['results']['drawResult']['asOf']=at
            out=parse_draws([r], 'powerball', start='2026-10-30T00:00:00Z',
                           end='2026-11-04T00:00:00Z', retrieved_at='2026-11-04T00:00:00Z')
            self.assertEqual(out[0]['drawDate'],date)

    def test_draw_id_regression_rejected(self):
        a=self.row();b=self.row()
        b['when']['drawTime']='2026-10-22T02:59:00Z'
        b['results']['drawResult']['asOf']=b['when']['drawTime']
        b['results']['drawResult']['drawingNumber']=2
        with self.assertRaises(ValueError):self.parse([a,b])
