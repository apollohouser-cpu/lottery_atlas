from copy import deepcopy
from datetime import date
import hashlib
import json
import unittest
from tooling.connecticut_scratch_package import package


class ScratchPackageTest(unittest.TestCase):
    def setUp(self):
        self.catalog = {'state': 'Connecticut', 'coverage': 'Fixture only',
            'excludedGames': [{'id': '1725', 'reason': 'Conflicting cash value'}],
            'games': [{'id': '100', 'stateName': 'Connecticut', 'name': 'Fixture',
                'status': 'ended', 'sourceDate': '2026-11-21', 'startDate': '2025-01-01',
                'endDate': '2026-10-01', 'cost': 1, 'topPrize': 10,
                'sourceUrl': 'https://ctlottery.com/games/scratch-games/100',
                'inventoryNote': 'Original note',
                'prizeTiers': [{'prizeLabel': '$10', 'total': 3, 'remaining': 1}]}]}

    def run_package(self, catalog):
        raw = json.dumps({'catalogs': [catalog]}).encode()
        return package(raw, hashlib.sha256(raw).hexdigest(), date(2026, 11, 22))

    def test_original_dates_unknown_deadline_and_fields_retained(self):
        self.assertEqual(self.run_package(self.catalog), self.catalog)

    def test_excluded_duplicate_future_and_impossible_inventory_rejected(self):
        mutations = [lambda c: c['games'][0].update(id='1725'),
            lambda c: c['games'].append(deepcopy(c['games'][0])),
            lambda c: c['games'][0].update(sourceDate='2026-11-23'),
            lambda c: c['games'][0]['prizeTiers'][0].update(remaining=4),
            lambda c: c.update(excludedGames=[])]
        for mutate in mutations:
            c = deepcopy(self.catalog); mutate(c)
            with self.assertRaises(ValueError): self.run_package(c)

    def test_unreviewed_bytes_rejected(self):
        with self.assertRaises(ValueError): package(b'{}', '0'*64, date(2026,11,22))
