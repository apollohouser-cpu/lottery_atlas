from datetime import date
import unittest
from tooling.connecticut_draw_results import normalize


def play3():
    game = dict(apiSlug='play3', detailsUrl='/games/draw-games/play3', draws=[], payouts=[])
    for session, day in [('Day', '2026-11-22'), ('Night', '2026-11-21')]:
        game['draws'].append(dict(isoDate=day, drawLabel=session, white=[0, 0, 7],
                                  special=0, specialLabel='Wild Ball'))
        game['payouts'].append(dict(apiGame='play3'+session.lower(), draw=dict(
            drawDate=day, whiteBalls=[0, 0, 7], powerPlayMultiplier=0, multiplier=0)))
    return game


class ResultsTest(unittest.TestCase):
    def test_session_dates_zeroes_and_wild_ball_preserved(self):
        rows = normalize(play3(), date(2026, 11, 22))
        self.assertEqual([r['drawDate'] for r in rows], ['2026-11-22', '2026-11-21'])
        self.assertEqual(rows[0]['numbers'], [0, 0, 7])
        self.assertEqual(rows[0]['special'], {'label': 'Wild Ball', 'number': 0})
        self.assertNotIn('powerPlay', rows[0])
        self.assertNotIn('winningTickets', rows[0])

    def test_invalid_date_session_digit_or_label_rejected(self):
        for field, value in [('isoDate', ''), ('isoDate', '2026-11-23'),
                             ('drawLabel', 'Night'), ('white', [True, 0, 7]),
                             ('white', [0, 0, 10]), ('specialLabel', 'Power Play')]:
            with self.subTest(field=field, value=value):
                game = play3(); game['draws'][0][field] = value
                with self.assertRaises(ValueError): normalize(game, date(2026, 11, 22))

    def test_payload_mismatch_rejected(self):
        for field, value in [('drawDate', '2026-11-21'), ('whiteBalls', [1, 2, 3]),
                             ('powerPlayMultiplier', 3)]:
            game = play3(); game['payouts'][0]['draw'][field] = value
            with self.assertRaises(ValueError): normalize(game, date(2026, 11, 22))

    def test_keno_requires_unique_numbers_identity_and_known_bonus(self):
        game = dict(apiSlug='keno', detailsUrl='/games/draw-games/keno',
                    latest=dict(isoDate='2026-11-22', white=list(range(1, 21)),
                                special=None, specialLabel=''),
                    kenoGameNo='123456', kenoBonus='2X')
        row = normalize(game, date(2026, 11, 22))[0]
        self.assertEqual(row['gameNumber'], '123456')
        self.assertNotIn('drawTime', row)
        game['latest']['white'][0] = 2
        with self.assertRaises(ValueError): normalize(game, date(2026, 11, 22))
        game['latest']['white'][0] = 1
        game['kenoGameNo'] = ''
        with self.assertRaises(ValueError): normalize(game, date(2026, 11, 22))
        game['kenoGameNo'] = '123456'; game['kenoBonus'] = '999X'
        with self.assertRaises(ValueError): normalize(game, date(2026, 11, 22))

    def test_unreviewed_product_rejected(self):
        game = play3(); game['apiSlug'] = 'xsandos'
        with self.assertRaises(ValueError): normalize(game, date(2026, 11, 22))


if __name__ == '__main__': unittest.main()
