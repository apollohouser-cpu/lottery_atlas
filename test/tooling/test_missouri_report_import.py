import sys, unittest, tempfile, json
from pathlib import Path
from datetime import date
from urllib.parse import urlparse
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'tooling'))
from import_missouri_draw_reports import FAMILIES, sessions, refresh, links, validate_continuity


def fake_fetch(url, form=None):
    family=urlparse(url).path.split('/')[1]
    if 'winning-numbers' not in url:return b'report'
    refs=[]
    for s in sessions(family):
        for day in ['2026-10-05','2026-10-04']:
            query='date='+day
            if s!='draw':query+=('&time=' if family.startswith('pick') else '&type=')+s
            refs.append('<a href="./prizes-paid.do?'+query+'">View</a>')
    return ('<html>'+''.join(refs)+'</html>').encode()


def fake_parse(family, raw, day, session):return {'drawDate':day,'game':family}


class ImportTests(unittest.TestCase):
    def test_all_groups_and_unchanged_refresh_preserve_bytes(self):
        with tempfile.TemporaryDirectory() as t:
            p=Path(t)/'out.json'
            r=refresh(p,fake_fetch,date(2026,10,6),fake_parse)
            self.assertEqual(len(r['reports']),28)
            before=p.read_bytes()
            refresh(p,fake_fetch,date(2026,10,6),fake_parse)
            self.assertEqual(before,p.read_bytes())
            def reject(family, raw, day, session):
                raise ValueError("Report session mismatch")
            with self.assertRaises(ValueError):refresh(p,fake_fetch,date(2026,10,6),reject)
            self.assertEqual(before,p.read_bytes())
            for family in FAMILIES:
                def fail(url,form=None):
                    if '/'+family+'/' in url:raise ValueError('source unavailable')
                    return fake_fetch(url,form)
                with self.assertRaises(ValueError):refresh(p,fail,date(2026,10,6),fake_parse)
                self.assertEqual(before,p.read_bytes())

    def test_reject_regressions_duplicates_unknown_sessions_and_future_dates(self):
        with tempfile.TemporaryDirectory() as t:
            r=refresh(Path(t)/'out.json',fake_fetch,date(2026,10,6),fake_parse)
            for change in ['date','duplicate','group']:
                new=json.loads(json.dumps(r))
                if change=='date':new['reports'][0]['drawDate']='2026-10-03'
                elif change=='duplicate':new['reports'][0]['drawDate']=new['reports'][1]['drawDate']
                else:new['reports'][0]['sessionKey']='unknown'
                with self.assertRaises(ValueError):validate_continuity(new,r)
        for raw in [b'<html>',b'<html><a href="./prizes-paid.do?date=2026-10-07">x</a></html>',b'<html><a href="https://example.com/prizes-paid.do?date=2026-10-05">x</a></html>']:
            with self.assertRaises(ValueError):links(raw,'powerball',date(2026,10,6))

if __name__=='__main__':unittest.main()
