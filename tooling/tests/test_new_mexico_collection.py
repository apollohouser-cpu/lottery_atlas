import unittest
from pathlib import Path
from datetime import datetime, timezone
from urllib.parse import urlparse,parse_qs
from tooling.new_mexico_coverage import collect, REPORTS, EXPECTED_GROUPS
from tooling.new_mexico_draw_rules import PAGES
from tooling.import_new_mexico_scratch_catalog import INVENTORY,ENDING
ROOT=Path(__file__).parent/'fixtures/new_mexico'
STAMP=datetime(2026,10,25,23,50,tzinfo=timezone.utc)

def fetch(url):
    if url==INVENTORY:name='scratch_inventory'
    elif url==ENDING:name='scratch_endings'
    elif '/search/?' in url:name=parse_qs(urlparse(url).query)['game'][0]
    elif '/how-to-play-' in url:name=next(g+'_rules' for g,(slug,_) in PAGES.items() if f'/games/{slug}/' in url)
    else:
        game,variant,_,_=next(r for r in REPORTS if r[2]==url)
        name='double_play_report' if variant=='double_play' else game+'_report'
    return (ROOT/(name+'.html')).read_bytes()

class CollectionTests(unittest.TestCase):
    def test_coupled_results_reports_rules_scratch(self):
        data=collect(fetch,lambda:STAMP)
        self.assertEqual(18,len(data['sources']))
        self.assertEqual(14,len(data['results']))
        self.assertEqual(4,sum(r['report'] is not None for r in data['results']))
        self.assertEqual(EXPECTED_GROUPS,{(r['game'],r['variant'],r['session']) for r in data['results']})
        self.assertEqual(57,len(data['scratch']['games']))
        self.assertIsNone(data['scratch']['sourceTimezone'])
        self.assertTrue(all(s['bytes']>0 and len(s['sha256'])==64 for s in data['sources']))
        self.assertEqual('2026-10-11',data['queryWindow']['start'])
    def test_every_request_failure_aborts_collection(self):
        for fail in range(18):
            calls=[]
            def broken(url):
                calls.append(url)
                if len(calls)==fail+1:raise OSError('injected source failure')
                return fetch(url)
            with self.subTest(fail=fail),self.assertRaises(OSError):collect(broken,lambda:STAMP)
            self.assertEqual(fail+1,len(calls))
    def test_report_wrong_date_never_borrowed(self):
        def changed(url):
            raw=fetch(url)
            return raw.replace(b'October 24, 2026',b'October 20, 2026') if url==REPORTS[1][2] else raw
        with self.assertRaises(ValueError):collect(changed,lambda:STAMP)
    def test_capture_timezone_required(self):
        with self.assertRaises(ValueError):collect(fetch,lambda:STAMP.replace(tzinfo=None))
    def test_report_gap_remains_unavailable(self):
        rows=collect(fetch,lambda:STAMP)['results']
        for r in rows:
            if r['game'] in ['pick3plus','pick4plus','roadrunnercash']:
                self.assertEqual('unavailable',r['reportStatus']);self.assertIsNone(r['report'])
if __name__=='__main__':unittest.main()
