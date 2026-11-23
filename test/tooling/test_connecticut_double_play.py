from datetime import date
import unittest
from tooling.connecticut_draw_results import normalize_double_play


def source():
    latest = dict(isoDate='2026-11-21', white=[5, 29, 33, 36, 45], special=22,
                  specialLabel='Powerball', multiplier='Power Play® 2X')
    return dict(apiSlug='powerball', detailsUrl='/games/draw-games/powerball', latest=latest,
                draws=['$19:props:data:games:0:latest', dict(date='', white=[10, 42, 45, 68, 69],
                    special=22, specialLabel='Powerball', sectionLabel='Double Play®')],
                payouts=[dict(apiGame='powerball', draw=dict(drawDate='2026-11-21',
                    whiteBalls=latest['white'], powerball=22,
                    doublePlay=dict(whiteBalls='$19:props:data:games:0:draws:1:white', powerball=22)))])


class DoublePlayTest(unittest.TestCase):
    def parse(self, game):
        return normalize_double_play(game, date(2026, 11, 22), inventory_index=0)

    def test_explicit_nested_date_not_retrieval_date(self):
        row = self.parse(source())
        self.assertEqual(row['drawDate'], '2026-11-21')
        self.assertEqual(row['numbers'], [10, 42, 45, 68, 69])
        self.assertNotIn('powerPlay', row)

    def test_cross_product_or_arbitrary_reference_rejected(self):
        for value in ['$19:props:data:games:1:draws:1:white', '$undefined', '$19:secret', '$ff:props:data:games:0:draws:1:white']:
            game = source(); game['payouts'][0]['draw']['doublePlay']['whiteBalls'] = value
            with self.assertRaises(ValueError): self.parse(game)

    def test_inline_numbers_must_match(self):
        game = source(); nested = game['payouts'][0]['draw']['doublePlay']
        nested['whiteBalls'] = [10, 42, 45, 68, 69]
        self.parse(game)
        nested['whiteBalls'] = [11, 42, 45, 68, 69]
        with self.assertRaises(ValueError): self.parse(game)

    def test_conflicting_date_or_missing_nested_result_rejected(self):
        game = source(); game['draws'][1]['isoDate'] = '2026-11-20'
        with self.assertRaises(ValueError): self.parse(game)
        game = source(); game['payouts'][0]['draw']['doublePlay'] = None
        with self.assertRaises(ValueError): self.parse(game)


if __name__ == '__main__': unittest.main()
