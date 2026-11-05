import copy
import json
from pathlib import Path
import unittest
from tooling.arizona_quick_draw import parse_captures, select_refresh


class QuickDrawTests(unittest.TestCase):
    def setUp(self):
        names = {'5-in-a-line':'five-in-line'}
        from tooling.arizona_quick_draw import PARSERS
        self.captures = {g:[json.loads((Path(__file__).parent / 'fixtures/arizona' /
                         (names.get(g,g)+'-tables.json')).read_text())] for g in PARSERS}

    def test_eight_groups_sixteen_selections_and_actual_provenance(self):
        result = select_refresh(self.captures, self.captures)
        self.assertEqual(len(result['groups']), 8)
        self.assertEqual(sum(map(len,result['groups'].values())), 16)
        self.assertEqual(result['provenance']['hi-lo'][0]['retrievedAt'], self.captures['hi-lo'][0]['retrievedAt'])

    def test_correction_and_retrieval_regression_rejected(self):
        for kind in ('correction','retrieval','missing'):
            bad = copy.deepcopy(self.captures)
            c = bad['hi-lo'][0]
            if kind == 'correction': c['tables'][0]['rows'][1][3]['text'] = '2x'
            if kind == 'retrieval': c['retrievedAt'] = '2026-11-02T21:30:00Z'
            if kind == 'missing': del c['tables'][0]['rows'][1:3]
            with self.subTest(kind=kind), self.assertRaises(ValueError): select_refresh(bad,self.captures)

    def boundary(self, game, start):
        # Synthetic two-day captures, never source observations.
        c = copy.deepcopy(self.captures)
        older = copy.deepcopy(c[game][0])
        older['selectedDate'] = '2026-11-01'
        template = older['tables'][0]['rows']
        template[1:-1] = copy.deepcopy(template[1:5])
        for index, hour, ident in [(1,23,100),(3,22,99)]:
            template[index][0]['text'] = str(ident)
            template[index][1]['text'] = f'{hour-12}:00 PM' if start == 5 else f'{hour-12}:10 PM'
        newer = copy.deepcopy(older)
        newer['selectedDate'] = '2026-11-02'
        for index, hour, ident in [(1,start+1,102),(3,start,101)]:
            newer['tables'][0]['rows'][index][0]['text'] = str(ident)
            newer['tables'][0]['rows'][index][1]['text'] = f'{hour}:00 AM' if start == 5 else f'{hour}:10 AM'
        c[game] = [newer,older]
        return c

    def test_overnight_schedule_for_nineteen_and_twenty_draw_families(self):
        for game,start in [('lucky-links',5),('hi-lo',4)]:
            candidate = self.boundary(game,start)
            self.assertEqual(len(parse_captures(candidate)[0][game]),4)
            bad = copy.deepcopy(candidate)
            for row_index in (1,3):
                row = bad[game][0]['tables'][0]['rows'][row_index]
                row[0]['text'] = str(int(row[0]['text'])+1)
            with self.assertRaises(ValueError): parse_captures(bad)

    def test_missing_group_or_duplicate_day_reject(self):
        bad = copy.deepcopy(self.captures)
        del bad['hi-lo']
        with self.assertRaises(ValueError): parse_captures(bad)
        bad = copy.deepcopy(self.captures)
        bad['hi-lo'].append(copy.deepcopy(bad['hi-lo'][0]))
        with self.assertRaises(ValueError): parse_captures(bad)

    def test_first_draw_of_day_uses_previous_day_for_second_selection(self):
        for game,start in [('lucky-links',5),('hi-lo',4)]:
            candidate = self.boundary(game,start)
            # Keep only the first scheduled draw of the newer day.
            del candidate[game][0]['tables'][0]['rows'][1:3]
            result = select_refresh(candidate,candidate)
            self.assertEqual([r['drawId'] for r in result['groups'][game]], ['101','100'])
            single = copy.deepcopy(candidate)
            single[game] = single[game][:1]
            with self.assertRaises(ValueError): parse_captures(single)
            empty = copy.deepcopy(candidate)
            del empty[game][0]['tables'][0]['rows'][1:-1]
            with self.assertRaises(ValueError): parse_captures(empty)

    def test_reviewed_pagination_footer_only(self):
        for game in self.captures:
            candidate = copy.deepcopy(self.captures)
            candidate[game][0]['tables'][0]['rows'][-1][0]['text'] = 'SEE MORE'
            select_refresh(candidate,candidate)
            candidate[game][0]['tables'][0]['rows'][-1][0]['text'] = 'unrecognized footer'
            with self.assertRaises(ValueError): parse_captures(candidate)
