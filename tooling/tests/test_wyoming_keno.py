import copy
import unittest
from tooling.import_wyoming_draws import KENO_ID, parse_keno


class WyomingKenoTests(unittest.TestCase):
    def row(self):
        return {'result': {'rapidGameId': KENO_ID, 'drawingNumber': 100,
                'drawingDate': '2026-10-27T01:00:00Z', 'sequenceNumber': None,
                'primary': {'winningNumbers': list(range(20,0,-1)),
                            'bonusNumbers': None, 'multipliers': None}}, 'jackpot': None}

    def parse(self, rows):
        return parse_keno(rows, first_id=99, last_id=103,
                          start='2026-10-27T00:00:00Z', end='2026-10-27T02:00:00Z',
                          retrieved_at='2026-10-27T03:00:00Z')

    def test_preserves_order_and_local_date(self):
        r=self.parse([self.row()])[0]
        self.assertEqual(r['numbers'], list(range(20,0,-1)))
        self.assertEqual(r['drawDate'], '2026-10-26')
        self.assertNotIn('jackpot',r)

    def test_rejects_bad_identity_id_and_date(self):
        for key,value in [('rapidGameId','wrong'),('drawingNumber',True),
                          ('drawingNumber',104),('drawingDate','2026-10-27T04:00:00Z'),
                          ('drawingDate','2026-10-27T01:00:00'),('secondary',{}),
                          ('sequenceNumber',1)]:
            r=self.row();r['result'][key]=value
            with self.subTest(key=key,value=value),self.assertRaises(ValueError):self.parse([r])

    def test_rejects_number_corruption(self):
        for key,value in [('winningNumbers',list(range(1,20))),
                          ('winningNumbers',[1]*20),
                          ('winningNumbers',list(range(1,20))+[81]),
                          ('winningNumbers',list(range(1,20))+[True]),
                          ('bonusNumbers',[1]),('multipliers',[2])]:
            r=self.row();r['result']['primary'][key]=value
            with self.subTest(key=key),self.assertRaises(ValueError):self.parse([r])

    def test_duplicate_and_time_id_disagreement(self):
        r=self.row()
        with self.assertRaises(ValueError):self.parse([r,copy.deepcopy(r)])
        b=copy.deepcopy(r);b['result']['drawingNumber']=101
        b['result']['drawingDate']='2026-10-27T00:56:00Z'
        with self.assertRaises(ValueError):self.parse([r,b])

    def test_gap_does_not_invent_draw(self):
        r=self.row();b=copy.deepcopy(r);b['result']['drawingNumber']=103
        b['result']['drawingDate']='2026-10-27T01:12:00Z'
        self.assertEqual([x['drawId'] for x in self.parse([r,b])],[103,100])
