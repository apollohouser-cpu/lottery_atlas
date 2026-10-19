import json
from pathlib import Path
from tempfile import TemporaryDirectory
import unittest
from tooling.export_iowa_scratch import export


class ExportTest(unittest.TestCase):
    def test_projection_preserves_unchanged_timestamp_and_rejects_mismatch(self):
        with TemporaryDirectory() as directory:
            source, output = Path(directory)/'source.json', Path(directory)/'out.json'
            game = dict(id='1', name='Test', cost=1, prizeTiers=[])
            snapshot = dict(schemaVersion=1, state='Iowa', retrievedAt='2026-10-19T12:00:00+00:00',
                            scratchCatalog=dict(sourceDate='2026-10-17', games=[game]),
                            instantInventories=dict(sourceDate='2026-10-17', inventories=[dict(productType='Scratch', games=[game])]))
            source.write_text(json.dumps(snapshot)); export(source, output)
            original=output.read_bytes()
            snapshot['retrievedAt']='2026-10-19T13:00:00+00:00'
            source.write_text(json.dumps(snapshot)); export(source, output)
            self.assertEqual(original, output.read_bytes())
            snapshot['scratchCatalog']['sourceDate']='2026-10-18'
            source.write_text(json.dumps(snapshot))
            with self.assertRaises(ValueError): export(source, output)
            self.assertEqual(original, output.read_bytes())

    def test_job_couples_both_outputs(self):
        jobs=json.loads(Path('tooling/state_refresh_jobs.json').read_text())
        job=next(j for j in jobs if j['state']=='Iowa')
        self.assertEqual(job['outputs'], ['data/iowa_coverage.generated.json','data/iowa_scratch_catalog.generated.json'])
        self.assertEqual(job['commands'][1][-2:], job['outputs'])
