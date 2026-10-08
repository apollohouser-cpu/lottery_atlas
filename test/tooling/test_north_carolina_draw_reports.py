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
