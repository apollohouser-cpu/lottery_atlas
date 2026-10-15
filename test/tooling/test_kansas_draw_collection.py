import json
from pathlib import Path
import unittest

from tooling.kansas_draw_collection import assemble_collection
from tooling.kansas_draw_results import GROUPS
from tooling.kansas_draw_schedules import SCHEMAS

FIXTURES = Path(__file__).parents[1] / 'fixtures/kansas'
RETRIEVED = '2026-10-15T01:00:00Z'


def fixture(name):
    return json.loads((FIXTURES / f'{name}.json').read_text())


class KansasCollectionTests(unittest.TestCase):
    def inputs(self):
        names = {'pick3-midday': 'pick-3-midday', 'pick3-evening': 'pick-3',
                 'powerball-double-play': 'powerball-double-play'}
        return ({group: fixture(names.get(group, data[3])) for group, data in GROUPS.items()},
                {slug: fixture(f'{slug}-schedule') for slug in SCHEMAS},
                fixture('team-mapping'), fixture('advertised-games'))

    def test_complete_collection_and_schedule_associations(self):
        result = assemble_collection(*self.inputs(), RETRIEVED)
        self.assertEqual(24, len(result['reports']))
        self.assertEqual(10, len(result['schedules']))
        for group, data in GROUPS.items():
            reports = [r for r in result['reports'] if r['group'] == group]
            self.assertEqual(2, len(reports))
            self.assertEqual({data[3]}, {r['scheduleKey'] for r in reports})
        serialized = json.dumps(result)
        for prohibited in ['shareCount', 'prizeTiers', 'winnerCount', 'latitude', 'longitude']:
            self.assertNotIn('"' + prohibited + '"', serialized)
        self.assertEqual('2026-10-15T01:00:00+00:00', result['retrievedAt'])

    def test_missing_or_extra_groups_and_schedules_rejected(self):
        for which in [0, 1]:
            for extra in [False, True]:
                inputs = self.inputs()
                if extra:
                    inputs[which]['historical'] = {}
                else:
                    inputs[which].pop(next(iter(inputs[which])))
                with self.subTest(which=which, extra=extra), self.assertRaises(ValueError):
                    assemble_collection(*inputs, RETRIEVED)

    def test_one_bad_group_or_schedule_rejects_entire_collection(self):
        for kind in ['result', 'schedule', 'mapping']:
            pages, schedules, teams, advertised = self.inputs()
            if kind == 'result':
                pages['racetrax']['content'][-1]['jackpotStatus'] = 'PENDING'
            elif kind == 'schedule':
                schedules['keno']['prizeLegend'].pop()
            else:
                teams.pop()
            with self.subTest(kind=kind), self.assertRaises(ValueError):
                assemble_collection(pages, schedules, teams, advertised, RETRIEVED)

    def test_retrieval_requires_timezone_and_cannot_precede_results(self):
        for timestamp in [None, '2026-10-15T01:00:00', '2020-01-01T00:00:00Z']:
            with self.subTest(timestamp=timestamp), self.assertRaises(ValueError):
                assemble_collection(*self.inputs(), timestamp)


if __name__ == '__main__':
    unittest.main()
