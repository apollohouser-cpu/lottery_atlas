import copy
import json
from pathlib import Path
import unittest
from tooling.validate_montana_coverage import validate

class PublicationTest(unittest.TestCase):
    def baseline(self):
        return json.loads(Path('data/montana_coverage.generated.json').read_text())

    def test_reviewed_baseline_and_public_bytes(self):
        validate(self.baseline())
        self.assertEqual(Path('data/montana_coverage.generated.json').read_bytes(), Path('docs/montana_coverage.json').read_bytes())

    def test_mutated_schema_identity_provenance_and_contracts_rejected(self):
        changes = [lambda d:d.update(state='Other'),lambda d:d.update(privateId='forbidden'),
                   lambda d:d['sources'].pop(),lambda d:d['sources'][0].update(sha256='bad'),
                   lambda d:d['results'][0].update(numbers=[True]*5),
                   lambda d:d['results'][0].update(reportStatus='available'),
                   lambda d:d['results'][0].update(sourceRetrievedAt='2026-10-29T00:00:00Z'),
                   lambda d:d['results'][0].update(drawDate='2099-01-01'),
                   lambda d:d['results'][0].update(multiplier=True),
                   lambda d:d['rules'][0].update(sections=[]),
                   lambda d:d['catalogs']['scratch']['entries'].pop(),
                   lambda d:d['catalogs']['treasure-play']['entries'][0]['advertisedJackpot'].update(amountText='$1.50'),
                   lambda d:d['status']['retiredGames'].clear(),
                   lambda d:d['endings']['rows'].clear(),
                   lambda d:d['raffle'].update(resultStatus='available'),
                   lambda d:d.update(unavailable=[])]
        for mutate in changes:
            d=copy.deepcopy(self.baseline());mutate(d)
            with self.assertRaises(ValueError):validate(d)

if __name__ == '__main__':unittest.main()
