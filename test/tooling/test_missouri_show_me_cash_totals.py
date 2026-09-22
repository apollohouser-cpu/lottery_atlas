import importlib.util
from datetime import date
import json
from pathlib import Path
import tempfile
import unittest

spec=importlib.util.spec_from_file_location('mo',Path(__file__).resolve().parents[2]/'tooling/import_missouri_show_me_cash_totals.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
HEAD=[{},dict(zip('ABCDEFGHI',['Draw Date','Draw Time','Numbers As Drawn','Numbers In Order','Jackpot',*m.TIERS]))]

def row(day,values=('0','1','2','3')):
    return dict(A=f'{day:02d}-Jan-26',B='evening',**dict(zip('FGHI',values)))

class MissouriPendingTest(unittest.TestCase):
    def test_latest_blank_and_partial_are_excluded_without_zero_fill(self):
        for values in [(None,None,None,None),('0','2',None,'4')]:
            counts,pending=m.parse_counts(HEAD+[row(2,values),row(1)],date(2026,1,2))
            self.assertEqual(counts,{date(2026,1,1):6})
            self.assertEqual(pending,[date(2026,1,2)])

    def test_completed_zero_and_later_completion_count_normally(self):
        counts,pending=m.parse_counts(HEAD+[row(2,('0','0','0','0')),row(1)],date(2026,1,2))
        self.assertEqual(counts[date(2026,1,2)],0)
        self.assertEqual(pending,[])

    def test_historical_missing_duplicate_future_gap_and_bad_values_fail(self):
        examples=[([row(2),row(1,(None,)*4)],date(2026,1,2)),([row(1),row(1)],date(2026,1,2)),([row(1),row(3)],date(2026,1,3)),([row(1),row(2)],date(2026,1,1)),([row(1),row(2,(None,)*4)],date(2026,1,4)),([row(1),row(2,('0','-1','2','3'))],date(2026,1,2)),([row(1),row(2,(None,)*4),row(3,(None,)*4)],date(2026,1,3))]
        for rows,today in examples:
            with self.subTest(rows=rows,today=today),self.assertRaises(ValueError):m.parse_counts(HEAD+rows,today)

    def test_update_preserves_other_states_and_removes_pending_on_completion(self):
        with tempfile.TemporaryDirectory() as tmp:
            p=Path(tmp)/'totals.json';p.write_text(json.dumps({'totals':[{'state':'NY','winningTickets':123}]}))
            counts={date(2026,1,1):6}
            result,changed=m.update_totals(p,counts,[date(2026,1,2)],date(2026,1,2))
            self.assertTrue(changed);self.assertEqual(result['periodEnd'],'2026-01-01')
            self.assertIn('excluded',result['coverage'])
            original=p.read_text()
            _,changed=m.update_totals(p,counts,[date(2026,1,2)],date(2026,1,3))
            self.assertFalse(changed);self.assertEqual(p.read_text(),original)
            result,_=m.update_totals(p,{**counts,date(2026,1,2):8},[],date(2026,1,3))
            self.assertNotIn('pendingDrawDates',result);self.assertEqual(result['winningTickets'],14)
            self.assertIn({'state':'NY','winningTickets':123},json.loads(p.read_text())['totals'])
            with self.assertRaises(ValueError):m.update_totals(p,counts,[date(2026,1,2)],date(2026,1,3))

if __name__=='__main__':unittest.main()
