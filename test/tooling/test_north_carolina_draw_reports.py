from datetime import date
from pathlib import Path
import sys
import unittest
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'tooling'))
from north_carolina_draw_reports import parse_cash_pop, CASH_POP_SESSIONS


def fixture():
    rows=[]
    for day in [6,7,8]:
        for name,clock in CASH_POP_SESSIONS.items():
            values=dict(lblDrawDate=f'2026, Oct {day}',lblSlotTime=clock,lblSlotName=name,lblPop='3',lblTotalWinners='633',lblTotalPayout='$21,908')
            span=lambda k:f'<span id="fixture_{k}">{values[k]}</span>'
            rows.append('<tr><td>'+span('lblDrawDate')+'</td><td>'+span('lblSlotTime')+' - '+span('lblSlotName')+'</td><td>'+span('lblPop')+'</td><td>'+span('lblTotalWinners')+'</td><td>'+span('lblTotalPayout')+'</td><td>Watch</td></tr>')
    return ('<html><main><table class="datatable past_draws"><thead><tr>'+''.join(f'<th>{v}</th>' for v in ['Date','Drawing','Pop','Winners','Payout','Watch*'])+'</tr></thead><tbody>'+''.join(rows)+'</tbody></table><table><tr><td>Promotional unrelated counts</td></tr></table></main></html>').encode()


class NCReportTests(unittest.TestCase):
    def test_two_latest_per_session_and_no_invented_tiers(self):
        rows=parse_cash_pop(fixture(),today=date(2026,10,8))
        self.assertEqual(len(rows),10)
        for name in CASH_POP_SESSIONS:
            self.assertEqual([r['drawDate'] for r in rows if r['session']==name],['2026-10-08','2026-10-07'])
        self.assertEqual(rows[0]['reportedWinners'],633)
        self.assertEqual(rows[0]['reportedPayoutCents'],2190800)
        self.assertNotIn('tiers',rows[0]);self.assertNotIn('latitude',rows[0])

    def test_malformed_source_rejected_even_in_old_unselected_rows(self):
        raw=fixture()
        for before,after in [(b'2026, Oct 6',b'2026, Feb 30'),(b'2026, Oct 6',b'2027, Oct 6'),
            (b'9:00 AM',b'10:00 AM'),(b'Morning Buzz',b'Unknown'),(b'>3</span>',b'>16</span>'),
            (b'>633</span>',b'>-1</span>'),(b'$21,908',b'$21,90'),(b'<th>Winners</th>',b'<th>Sales</th>'),
            (b'</html>',b''),(b'lblTotalWinners',b'missing')]:
            with self.subTest(before=before):
                with self.assertRaises(ValueError):parse_cash_pop(raw.replace(before,after,1),today=date(2026,10,8))

    def test_duplicate_or_missing_session_rejected(self):
        raw=fixture()
        with self.assertRaises(ValueError):parse_cash_pop(raw.replace(b'2026, Oct 6',b'2026, Oct 7'),today=date(2026,10,8))
        from lxml import html,etree
        doc=html.fromstring(raw)
        for row in doc.xpath('//tbody/tr')[1::5]:row.getparent().remove(row)
        with self.assertRaises(ValueError):parse_cash_pop(etree.tostring(doc),today=date(2026,10,8))

    def test_zero_and_fractional_payout_preserve_source_units(self):
        raw=fixture().replace(b'>633</span>',b'>0</span>').replace(b'$21,908',b'$0')
        self.assertEqual(parse_cash_pop(raw,today=date(2026,10,8))[0]['reportedWinners'],0)
        with self.assertRaises(ValueError):parse_cash_pop(raw.replace(b'$0',b'$1'),today=date(2026,10,8))
        rows=parse_cash_pop(fixture().replace(b'$21,908',b'$21,908.50'),today=date(2026,10,8))
        self.assertEqual(rows[0]['reportedPayoutCents'],2190850)


from north_carolina_draw_reports import parse_pick_summary, parse_pick_reports


def pick_fixture(size=3, day=7, session='Evening'):
    prefix=f'ctl00_MainContent_PayoutPick{size}_PayoutRepeater_ctl00_'
    values={
        'lblDrawDate':f'<svg aria-label="{session} Draw"></svg>'+date(2026,10,day).strftime('%A %b %d, %Y'),
        'lblFireball':'0', 'lblWinningsLabel':'Total Combined Winnings',
        'lblWinnings':'1,527 winners won a total of $227,915',
        **{f'lblBall{i}':str(i-1) for i in range(1,size+1)},
    }
    return ('<html><main>'+''.join(f'<span id="{prefix}{k}">{v}</span>' for k,v in values.items())+
        '<table><tr><td>Payout schedule $500 — no winner count</td></tr></table></main></html>').encode()


class NCPickReportTests(unittest.TestCase):
    def test_summary_preserves_leading_zero_and_source_units(self):
        for size in [3,4]:
            r=parse_pick_summary(pick_fixture(size),f'Pick {size}',f'https://nclottery.com/Pick{size}-Draw?dn=123',today=date(2026,10,8))
            self.assertEqual(r['winningDigits'],list('0123')[:size])
            self.assertEqual(r['fireball'],'0')
            self.assertEqual(r['reportedWinners'],1527)
            self.assertEqual(r['reportedPayoutCents'],22791500)
            self.assertEqual(r['reportType'],'combined-summary')
            self.assertNotIn('tiers',r)
            self.assertNotIn('latitude',r)

    def test_invalid_identity_date_session_counts_and_structure_rejected(self):
        for before,after in [(b'Wednesday',b'Tuesday'),(b'2026',b'2027'),
            (b'Evening Draw',b'Morning Draw'),(b'1,527',b'1,52'),
            (b'$227,915',b'$-1'),(b'$227,915',b'$0'),
            (b'lblBall1',b'lblBall4'),(b'>0</span>',b'>10</span>'),
            (b'Total Combined Winnings',b'Total Sales'),(b'</html>',b''),
            (b'lblWinnings"',b'unknown"'),(b'won a total of',b'claimed')]:
            with self.subTest(before=before),self.assertRaises(ValueError):
                parse_pick_summary(pick_fixture().replace(before,after,1),'Pick 3','https://nclottery.com/Pick3-Draw?dn=123',today=date(2026,10,8))
        for url in ['https://nclottery.com/Pick4-Draw?dn=123','https://other.example/Pick3-Draw?dn=123','https://nclottery.com/Pick3-Draw?dn=123&extra=1']:
            with self.assertRaises(ValueError):parse_pick_summary(pick_fixture(),'Pick 3',url)
        with self.assertRaises(ValueError):parse_pick_summary(pick_fixture(4),'Pick 3','https://nclottery.com/Pick3-Draw?dn=123')

    def test_complete_groups_validate_old_rows_and_reject_duplicates(self):
        documents=[(f'https://nclottery.com/Pick3-Draw?dn={day*2+index}',pick_fixture(day=day,session=session))
                   for day in [6,8,7] for index,session in enumerate(['Daytime','Evening'])]
        rows=parse_pick_reports(documents,'Pick 3',today=date(2026,10,8))
        self.assertEqual([(r['session'],r['drawDate']) for r in rows],[(s,d) for s in ['Daytime','Evening'] for d in ['2026-10-08','2026-10-07']])
        with self.assertRaises(ValueError):parse_pick_reports(documents+documents[:1],'Pick 3',today=date(2026,10,8))
        with self.assertRaises(ValueError):parse_pick_reports(documents[::2],'Pick 3',today=date(2026,10,8))
        documents[0]=(documents[0][0],documents[0][1].replace(b'1,527',b'-1'))
        with self.assertRaises(ValueError):parse_pick_reports(documents,'Pick 3',today=date(2026,10,8))

    def test_zero_fractional_and_duplicate_fields(self):
        raw=pick_fixture().replace(b'1,527',b'0').replace(b'$227,915',b'$0')
        self.assertEqual(parse_pick_summary(raw,'Pick 3','https://nclottery.com/Pick3-Draw?dn=123')['reportedWinners'],0)
        raw=pick_fixture().replace(b'$227,915',b'$227,915.50')
        self.assertEqual(parse_pick_summary(raw,'Pick 3','https://nclottery.com/Pick3-Draw?dn=123')['reportedPayoutCents'],22791550)
        extra=b'<span id="ctl00_MainContent_PayoutPick3_PayoutRepeater_ctl00_lblWinnings">1 winners won a total of $1</span>'
        with self.assertRaises(ValueError):parse_pick_summary(raw.replace(b'</main>',extra+b'</main>'),'Pick 3','https://nclottery.com/Pick3-Draw?dn=123')
