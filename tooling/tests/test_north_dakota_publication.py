import copy
import json
from pathlib import Path
import unittest
from tooling.tests import test_north_dakota_collection as fixtures
from tooling.validate_north_dakota_coverage import validate


class PublicationTests(unittest.TestCase):
    def test_baseline_and_fixture_candidate(self):
        validate(fixtures.CollectionTests().baseline())
        validate(json.loads(Path('data/north_dakota_coverage.generated.json').read_text()))

    def test_corrupt_identity_rules_numbers_and_provenance(self):
        baseline=fixtures.CollectionTests().baseline()
        for mutate in [lambda d: d.update(state='Other'),
                       lambda d: d['sources'].pop(),
                       lambda d: d['sources'][0].update(sha256='bad'),
                       lambda d: d['catalog']['retired'].clear(),
                       lambda d: d['rules'][0].update(document={}),
                       lambda d: d['results'][0].update(drawDate='2026-10-27'),
                       lambda d: d['results'][0].update(numbers=[70]*5),
                       lambda d: d['results'][0].update(multiplier=True),
                       lambda d: d['results'][0].update(reportStatus='available'),
                       lambda d: d['results'][0].update(drawId=1),
                       lambda d: d['results'][0].update(sourceRetrievedAt='2026-10-28T00:00:00Z')]:
            data=copy.deepcopy(baseline); mutate(data)
            with self.assertRaises(ValueError): validate(data)
