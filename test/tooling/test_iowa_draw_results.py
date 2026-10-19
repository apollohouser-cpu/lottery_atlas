import unittest
from datetime import date
from tooling.iowa_draw_results import parse_results

TODAY = date(2026,10,19)

def pick(rows=None, session='Midday'):
    rows = rows or [('10/18/2026','0 - 8 - 4 - 7'),('10/17/2026','0 - 0 - 5 - 2')]
    return '<h1>'+session+' Winning Numbers</h1><table id="color"><tr><th>Date</th><th>Numbers</th></tr>'+''.join('<tr><td>'+d+'</td><td>'+n+'</td></tr>' for d,n in rows)+'<tr class="footercolor"><td></td></tr></table>'

def pb(marker='PB', numbers='12 - 13 - 24 - 32 - 35 - 11 3', heading='Numbers Power Play'):
    return '<table id="colorPB"><tr><th>Date</th><th>'+heading+'</th></tr>'+''.join('<tr><td><span id="WinningNumbersGrid'+marker+'1_lblDate">'+d+'</span></td><td>'+numbers+'</td></tr>' for d in ['10/17/2026','10/14/2026'])+'</table>'

class IowaResultsTest(unittest.TestCase):
    def test_leading_zero_and_session(self):
        r=parse_results(pick(),'pick4_midday',as_of=TODAY)
        self.assertEqual(r[1]['numbers'],[0,0,5,2])
        self.assertNotIn('winnerCount',r[0])
        with self.assertRaises(ValueError):parse_results(pick(session='Evening'),'pick4_midday',as_of=TODAY)
    def test_duplicate_and_reverse_dates(self):
        for dates in [('10/18/2026','10/18/2026'),('10/17/2026','10/18/2026')]:
            with self.assertRaises(ValueError):parse_results(pick([(d,'0 - 8 - 4 - 7') for d in dates]),'pick4_midday',as_of=TODAY)
    def test_bad_date_future_old(self):
        for d in ['10/32/2026','10/20/2026','02/21/2026','2026-10-18']:
            with self.assertRaises(ValueError):parse_results(pick([(d,'0 - 8 - 4 - 7'),('10/17/2026','0 - 0 - 5 - 2')]),'pick4_midday',as_of=TODAY)
    def test_bad_digits(self):
        for n in ['00 - 8 - 4 - 7','0 - 8 - 4','0 - 8 - 4 - 10','0 - 8 - 4 - 7 2']:
            with self.assertRaises(ValueError):parse_results(pick([('10/18/2026',n),('10/17/2026','0 - 0 - 5 - 2')]),'pick4_midday',as_of=TODAY)
    def test_pb_variant_not_table_position(self):
        raw=pb('DP','13 - 14 - 30 - 52 - 60 - 15','Numbers')+pb()
        self.assertEqual(parse_results(raw,'double_play',as_of=TODAY)[0]['specialBall'],15)
        self.assertEqual(parse_results(raw,'powerball',as_of=TODAY)[0]['multiplier'],3)
        self.assertNotIn('multiplier',parse_results(raw,'double_play',as_of=TODAY)[0])
    def test_pb_ranges_duplicates_multiplier(self):
        for n in ['12 - 12 - 24 - 32 - 35 - 11 3','13 - 12 - 24 - 32 - 35 - 11 3','12 - 13 - 24 - 32 - 70 - 11 3','12 - 13 - 24 - 32 - 35 - 27 3','12 - 13 - 24 - 32 - 35 - 11 6']:
            with self.assertRaises(ValueError):parse_results(pb(numbers=n),'powerball',as_of=TODAY)
    def test_mixed_variant(self):
        raw=pb().replace('WinningNumbersGridPB1_lblDate','WinningNumbersGridDP1_lblDate',1)
        with self.assertRaises(ValueError):parse_results(raw,'powerball',as_of=TODAY)
    def test_ambiguity_and_insufficient(self):
        for raw in [pick()+pick(),pick([('10/18/2026','0 - 8 - 4 - 7')]),pick().replace('<td></td>','<td>unexpected</td>')]:
            with self.assertRaises(ValueError):parse_results(raw,'pick4_midday',as_of=TODAY)
    def test_full_visible_table_validated(self):
        with self.assertRaises(ValueError):parse_results(pick([('10/18/2026','0 - 8 - 4 - 7'),('10/17/2026','0 - 0 - 5 - 2'),('10/16/2026','bad')]),'pick4_midday',as_of=TODAY)
    def test_unsupported_team_contract(self):
        with self.assertRaises(ValueError):parse_results(pick(),'xsos',as_of=TODAY)

if __name__ == '__main__':unittest.main()
