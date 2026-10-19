import unittest
from datetime import date
from tooling.iowa_draw_reports import SPECS,parse_reports,attach_report

TODAY=date(2026,10,19)
def fixture(group='powerball',day='10/17/2026',count='0',jackpot='$0',multiplier='3'):
    game,table,tiers,extra=SPECS[group]
    values=[day]+[count]*len(tiers)+[jackpot if x=='Jackpot' else '' if x=='MP***' else multiplier for x in extra]
    return '<p>number of winners at each prize level for '+game+' tickets purchased in Iowa.</p><table id="'+table+'">'+''.join('<th>'+h+'</th>' for h in ['Draw Date']+tiers+extra)+'<tr>'+''.join('<td>'+v+'</td>' for v in values)+'</tr></table>'

class IowaReportsTest(unittest.TestCase):
    def test_all_supported_reports(self):
        for g in SPECS:
            r=parse_reports(fixture(g),g,as_of=TODAY)['2026-10-17']
            self.assertEqual(r['group'],g)
            self.assertEqual(r['tiers'][0]['sourceWinners'],0)
    def test_placeholder_not_zero_prize(self):
        r=parse_reports(fixture(),'powerball',as_of=TODAY)['2026-10-17']
        self.assertIsNone(r['advertisedJackpotDollars'])
        self.assertEqual(r['sourceJackpotText'],'$0')
        self.assertEqual(parse_reports(fixture(jackpot='$123,000,000'),'powerball',as_of=TODAY)['2026-10-17']['advertisedJackpotDollars'],123000000)
    def test_geography_and_schema_fail_closed(self):
        for raw in [fixture().replace('purchased in Iowa','purchased nationally'),fixture().replace('PP</th>','OTHER</th>'),fixture()+fixture()]:
            with self.assertRaises(ValueError):parse_reports(raw,'powerball',as_of=TODAY)
    def test_bad_counts_and_money(self):
        for c in ['-1','1.5','01','unknown','1,000']:
            with self.assertRaises(ValueError):parse_reports(fixture(count=c),'powerball',as_of=TODAY)
        for j in ['$1,23','$-3','none']:
            with self.assertRaises(ValueError):parse_reports(fixture(jackpot=j),'powerball',as_of=TODAY)
    def test_future_and_duplicate_dates(self):
        with self.assertRaises(ValueError):parse_reports(fixture(day='10/20/2026'),'powerball',as_of=TODAY)
        raw=fixture();row=raw[raw.index('<tr>'):raw.index('</tr>')+5]
        with self.assertRaises(ValueError):parse_reports(raw.replace('</table>',row+'</table>'),'powerball',as_of=TODAY)
    def test_mm_no_invented_multiplier(self):
        r=parse_reports(fixture('mega_millions'),'mega_millions',as_of=TODAY)['2026-10-17']
        self.assertNotIn('multiplier',r)
        with self.assertRaises(ValueError):parse_reports(fixture('mega_millions').replace('<td></td>','<td>3</td>'),'mega_millions',as_of=TODAY)
    def test_exact_identity_join(self):
        reports=parse_reports(fixture(),'powerball',as_of=TODAY)
        self.assertIsNone(attach_report({'drawDate':'2026-10-18','group':'powerball'},reports)['report'])
        with self.assertRaises(ValueError):attach_report({'drawDate':'2026-10-17','group':'double_play'},reports)
        with self.assertRaises(ValueError):attach_report({'drawDate':'2026-10-17','group':'powerball','multiplier':2},reports)
        self.assertIsNotNone(attach_report({'drawDate':'2026-10-17','group':'powerball','multiplier':3},reports)['report'])
    def test_pick_counts_remain_unsupported(self):
        with self.assertRaises(ValueError):parse_reports(fixture(),'pick3_midday',as_of=TODAY)

if __name__=='__main__':unittest.main()
