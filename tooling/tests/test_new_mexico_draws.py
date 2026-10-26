import unittest
from datetime import date
from pathlib import Path
from lxml import html
from tooling.import_new_mexico_draws import GAMES, parse_results, latest_two

FIXTURES = Path(__file__).parent / 'fixtures/new_mexico'

class NewMexicoDrawTests(unittest.TestCase):
    def raw(self, game):
        return (FIXTURES / (game + '.html')).read_text()

    def parse(self, game, raw=None, **kwargs):
        return parse_results(raw or self.raw(game), game, start=date(2026,10,22),
                             end=kwargs.get('end',date(2026,10,25)), today=date(2026,10,25))

    def test_all_current_families_and_nine_groups(self):
        rows = [r for g in GAMES for r in self.parse(g)]
        self.assertEqual(21, len(rows))
        bounded = latest_two(rows)
        self.assertEqual(14, len(bounded))
        self.assertEqual(9, len({(r['game'],r['variant'],r['session']) for r in bounded}))
        self.assertTrue(all(r['reportStatus']=='unavailable' for r in rows))

    def test_leading_zero_and_explicit_sessions(self):
        rows=self.parse('pick4plus')
        self.assertEqual(['0','4','0','6'],rows[0]['numbers'])
        self.assertEqual('DAY',rows[0]['session'])
        eve=next(r for r in latest_two(rows) if r['session']=='EVE')
        self.assertEqual('2026-10-24',eve['date'])

    def test_double_play_separate(self):
        rows=self.parse('powerball')
        dp=next(r for r in rows if r['variant']=='double_play')
        self.assertEqual(['3','30','44','50','56'],dp['numbers'])
        self.assertIsNone(dp['multiplier'])
        self.assertEqual(2,next(r for r in rows if r['variant']=='base')['multiplier'])

    def test_wrong_heading(self):
        with self.assertRaises(ValueError):self.parse('powerball',self.raw('powerball').replace('>Powerball<','>Mega Millions<'))

    def test_duplicate_identity(self):
        t=html.fromstring(self.raw('pick3plus'));row=t.xpath('.//div[@class="result DAY-draw"]')[0]
        row.getparent().append(html.fromstring(html.tostring(row)))
        with self.assertRaises(ValueError):self.parse('pick3plus',html.tostring(t))

    def test_bad_numbers_and_special_identity(self):
        for old,new in [('<li>4</li>','<li>70</li>'),('<li>5</li>','<li>4</li>'),('special-ball','unknown-ball')]:
            with self.subTest(old=old),self.assertRaises(ValueError):self.parse('powerball',self.raw('powerball').replace(old,new,1))

    def test_session_conflict_and_missing(self):
        for old,new in [('10/25/2026 DAY','10/25/2026 EVE'),('10/25/2026 DAY','10/25/2026')]:
            with self.subTest(new=new),self.assertRaises(ValueError):self.parse('pick3plus',self.raw('pick3plus').replace(old,new))

    def test_outside_window_and_future(self):
        with self.assertRaises(ValueError):self.parse('pick3plus',end=date(2026,10,24))
        with self.assertRaises(ValueError):self.parse('powerball',end=date(2026,10,26))

    def test_missing_double_play_and_invalid_multiplier(self):
        for old,new in [('Double Play:','Future Play:'),('multiplier: 2','multiplier: 6')]:
            with self.subTest(old=old),self.assertRaises(ValueError):self.parse('powerball',self.raw('powerball').replace(old,new))

    def test_mm_no_drawing_multiplier(self):
        raw=self.raw('megamillions').replace('<div class="fp draw-info"></div>','<div class="fp draw-info">Multiplier: 3</div>')
        with self.assertRaises(ValueError):self.parse('megamillions',raw)

    def test_historical_and_unknown_game_rejected(self):
        with self.assertRaises(ValueError):parse_results(self.raw('powerball'),'powerball',start=date(2015,1,1),end=date(2015,1,2),today=date(2026,10,25))
        with self.assertRaises(ValueError):self.parse('hotlotto','<html/>')

if __name__=='__main__':unittest.main()
