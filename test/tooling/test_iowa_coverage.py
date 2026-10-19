import copy
from datetime import datetime, timezone
import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from unittest.mock import patch
from tooling import collect_iowa_coverage as coverage
from test.tooling.test_iowa_instant_inventories import fixture

NOW = datetime(2026,10,19,13,tzinfo=timezone.utc)


class CoverageTest(unittest.TestCase):
    def setUp(self):
        self.tmp = TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.path = Path(self.tmp.name) / 'coverage.json'
        self.inventory = coverage.parse_inventories(fixture(), as_of=NOW.date())
        self.scratch = dict(sourceDate=self.inventory['sourceDate'], games=[
            {k: v for k, v in self.inventory['inventories'][0]['games'][0].items() if k != 'productType'}])

    def collect(self, **kwargs):
        return coverage.collect(self.path, fetch=lambda url: fixture().encode(), now=NOW, **kwargs)

    def test_coupled_failure_never_exposes_partial_draw_update(self):
        with patch.object(coverage, 'collect_draws', return_value={'results': [1]}), patch.object(coverage, 'build_catalog', return_value=self.scratch):
            self.collect()
            before = self.path.read_bytes()
            with patch.object(coverage, 'collect_draws', return_value={'results': [2]}), patch.object(coverage, 'build_catalog', side_effect=ValueError('detail failed')):
                with self.assertRaises(ValueError): self.collect()
            self.assertEqual(before, self.path.read_bytes())
            with patch.object(coverage.os, 'replace', side_effect=OSError('replace failed')):
                with self.assertRaises(OSError): self.collect()
            self.assertEqual(before, self.path.read_bytes())
            self.assertEqual(list(self.path.parent.iterdir()), [self.path])
            self.collect()

    def test_scratch_tier_or_date_mismatch_rejects_whole_snapshot(self):
        for key in ['sourceDate','games']:
            bad = copy.deepcopy(self.scratch)
            bad[key] = '2026-10-16' if key == 'sourceDate' else []
            with patch.object(coverage, 'collect_draws', return_value={'results': []}), patch.object(coverage, 'build_catalog', return_value=bad):
                with self.assertRaises(ValueError): self.collect()
            self.assertFalse(self.path.exists())

    def test_inventory_regressions_and_same_date_change(self):
        for change in ['date','same_date','loss','claimed','unclaimed','identity']:
            new = copy.deepcopy(self.inventory)
            new['sourceDate'] = '2026-10-18'
            game = new['inventories'][1]['games'][0]
            if change == 'date': new['sourceDate'] = '2026-10-16'
            if change == 'same_date':
                new['sourceDate'] = '2026-10-17'
                game['prizeTiers'][0]['claimed'] += 1
            if change == 'loss': new['inventories'][1]['games'] = []
            if change == 'claimed': game['prizeTiers'][0]['claimed'] -= 1
            if change == 'unclaimed': game['prizeTiers'][0]['unclaimed'] += 1
            if change == 'identity': game['name'] = 'Other'
            with self.assertRaises(ValueError): coverage.check_inventory_continuity(self.inventory, new)

    def test_normal_dated_count_progression(self):
        new = copy.deepcopy(self.inventory)
        new['sourceDate'] = '2026-10-18'
        new['inventories'][0]['games'][0]['prizeTiers'][0]['claimed'] += 1
        coverage.check_inventory_continuity(self.inventory, new)
