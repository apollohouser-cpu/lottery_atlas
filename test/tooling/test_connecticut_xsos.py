from datetime import date
import unittest
from tooling.connecticut_draw_results import normalize


def source():
    balls = [5, 10, 14, 19, 26, 27, 30, 32]
    return dict(apiSlug='xsandos', detailsUrl='/games/draw-games/xo',
                latest=dict(isoDate='2026-11-15', white=balls, special=None, specialLabel=''),
                payouts=[dict(apiGame='xsandos', draw=dict(drawDate='2026-11-15', whiteBalls=balls))])


class TeamsTest(unittest.TestCase):
    def test_reviewed_team_mapping(self):
        row = normalize(source(), date(2026, 11, 22))[0]
        self.assertEqual(row['teams'], ['Carolina Panthers', 'Denver Broncos',
            'Indianapolis Colts', 'Los Angeles Rams', 'Philadelphia Eagles',
            'Pittsburgh Steelers', 'Tampa Bay Buccaneers', 'Washington Commanders'])
        self.assertNotIn('winningTickets', row)

    def test_out_of_range_and_duplicate_teams_rejected(self):
        for n in [0, 33, True, 10]:
            game = source(); game['latest']['white'][0] = n
            with self.assertRaises(ValueError): normalize(game, date(2026, 11, 22))

    def test_payload_disagreement_rejected(self):
        game = source(); game['payouts'][0]['draw']['whiteBalls'] = list(range(1, 9))
        with self.assertRaises(ValueError): normalize(game, date(2026, 11, 22))


if __name__ == '__main__': unittest.main()
