import copy
import html
import json
from pathlib import Path
import unittest
from tooling.import_north_dakota_draws import parse_draws

FIXTURE = json.loads((Path(__file__).parent / 'fixtures/north_dakota/results.json').read_text())


def markup(f):
    return '<h1>' + html.escape(f['title']) + '</h1><table>' + ''.join(
        '<tr>' + ''.join('<td>' + html.escape(c) + '</td>' for c in row) + '</tr>'
        for row in f['rows']) + '</table>'


class NorthDakotaDrawTests(unittest.TestCase):
    def parse(self, game='powerball', mutate=None, transform=None, captured=None):
        f = copy.deepcopy(FIXTURE[game])
        if mutate:
            mutate(f)
        text = markup(f)
        if transform:
            text = transform(text)
        return parse_draws(text, game, retrieved_at=captured or f['retrievedAt'])

    def test_retained_all_five_sources_date_only(self):
        for game in FIXTURE:
            rows = self.parse(game)
            self.assertEqual(len(rows), 30 if game == '2by2' else 10)
            self.assertTrue(all(r['datePrecision'] == 'day' and r['reportStatus'] == 'unavailable' for r in rows))
            self.assertTrue(all('drawTimeUtc' not in r and 'jackpot' not in r for r in rows))

    def test_color_and_multiplier_semantics(self):
        r = self.parse('2by2')[0]
        self.assertEqual((r['numbers'], r['bonusNumbers'], r['numberLabels']), ([4, 15], [9, 23], ['Red', 'White']))
        self.assertIsNone(self.parse('mega-millions')[0]['multiplier'])
        self.assertEqual(self.parse('powerball')[0]['multiplier'], 3)
        self.assertEqual(self.parse('lotto-america')[0]['multiplier'], 4)

    def test_wrong_identity_headers_and_table_count(self):
        for mutation in [lambda f: f.update(title='Lucky for Life'),
                         lambda f: f['rows'][0].__setitem__(2, 'Wrong Ball')]:
            with self.assertRaises(ValueError): self.parse(mutate=mutation)
        with self.assertRaises(ValueError): self.parse(transform=lambda t: t + '<table></table>')

    def test_number_range_cardinality_duplicates(self):
        for value in ['1-2-3-4-70', '1-2-3-4', '1-2-3-4-4', '0-2-3-4-5', '1-2-3-4-5x']:
            with self.subTest(value=value), self.assertRaises(ValueError):
                self.parse(mutate=lambda f: f['rows'][1].__setitem__(1, value))
        with self.assertRaises(ValueError):
            self.parse(mutate=lambda f: f['rows'][1].__setitem__(2, '27'))

    def test_dates_cadence_and_capture(self):
        for value in ['10/27/2026', '2/30/2026', '8/31/2026', '2026-10-26']:
            with self.subTest(value=value), self.assertRaises(ValueError):
                self.parse(mutate=lambda f: f['rows'][1].__setitem__(0, value))
        for stamp in ['2026-10-26T00:00:00Z', '2026-10-27T00:00:00', '2026-10-27T00:00:00-04:00']:
            with self.assertRaises(ValueError): self.parse(captured=stamp)

    def test_duplicate_reverse_missing_cells_and_short_window(self):
        for mutation in [lambda f: f['rows'].insert(2, f['rows'][1]),
                         lambda f: f['rows'].__setitem__(slice(1, 3), f['rows'][1:3][::-1]),
                         lambda f: f['rows'][1].pop(),
                         lambda f: f.update(rows=f['rows'][:2])]:
            with self.assertRaises(ValueError): self.parse(mutate=mutation)

    def test_legacy_and_invalid_multiplier(self):
        for game, value in [('mega-millions', '3'), ('powerball', '6'), ('lotto-america', '10')]:
            with self.assertRaises(ValueError):
                self.parse(game, mutate=lambda f: f['rows'][1].__setitem__(3, value))

    def test_jackpot_not_silently_reinterpreted(self):
        for value in ['Pending', '$0', '$12,34', '$100M']:
            with self.assertRaises(ValueError):
                self.parse(mutate=lambda f: f['rows'][1].__setitem__(4, value))

    def test_malformed_or_merged_markup(self):
        for transform in [lambda t: t.replace('<td>', '<td rowspan="2">', 1),
                          lambda t: t.replace('</td>', '', 1),
                          lambda t: t.removesuffix('</table>')]:
            with self.assertRaises(ValueError): self.parse(transform=transform)

    def test_retired_game_rejected(self):
        with self.assertRaises(ValueError):
            parse_draws(markup(FIXTURE['powerball']), 'lucky-for-life', retrieved_at='2026-10-27T00:00:00Z')
