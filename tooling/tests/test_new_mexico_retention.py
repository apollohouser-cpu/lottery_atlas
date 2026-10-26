import copy
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from tooling.tests.test_new_mexico_collection import fetch, STAMP
from tooling.new_mexico_coverage import collect, continuity, refresh

class RetentionTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls): cls.base=collect(fetch,lambda:STAMP)
    def test_all_request_failures_preserve_disk(self):
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'coverage.json'
            original=(json.dumps(self.base)+'\n').encode();path.write_bytes(original)
            for position in range(18):
                calls=[]
                def broken(url):
                    calls.append(url)
                    if len(calls)==position+1: raise OSError('source failure')
                    return fetch(url)
                with self.subTest(position=position),self.assertRaises(OSError):
                    refresh(path,broken,lambda:STAMP)
                self.assertEqual(original,path.read_bytes())
                self.assertEqual([path],list(Path(folder).iterdir()))
    def test_replace_failure_preserves_disk_and_removes_temp(self):
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'coverage.json';original=json.dumps(self.base).encode();path.write_bytes(original)
            with patch('os.replace',side_effect=OSError('disk failure')),self.assertRaises(OSError):
                refresh(path,fetch,lambda:STAMP)
            self.assertEqual(original,path.read_bytes())
            self.assertEqual([path],list(Path(folder).iterdir()))
    def test_success_and_inventory_decrease(self):
        candidate=copy.deepcopy(self.base)
        candidate['scratch']['games'][0]['topPrizesRemaining']-=1
        continuity(self.base,candidate)
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'coverage.json'
            result=refresh(path,fetch,lambda:STAMP)
            self.assertEqual(result,json.loads(path.read_text()))
    def test_corrections_regressions_and_identity_loss(self):
        def number(c): c['results'][0]['numbers'][0]='99'
        def report(c): next(r['report'] for r in c['results'] if r['report'])['totalPrizesWon']+=1
        def count(c): c['scratch']['games'][0]['topPrizesRemaining']+=1
        def lost(c): c['scratch']['games'].pop()
        def window(c): c['queryWindow']['end']='2026-10-24'
        def draw(c): c['results'].pop()
        def rule(c): c['rules'].pop()
        for mutate in (number,report,count,lost,window,draw,rule):
            candidate=copy.deepcopy(self.base);mutate(candidate)
            with self.subTest(mutation=mutate.__name__),self.assertRaises(ValueError):continuity(self.base,candidate)
    def test_old_report_retains_original_capture_provenance(self):
        candidate=copy.deepcopy(self.base)
        row=next(r for r in candidate['results'] if r['report'])
        original=copy.deepcopy(row['report'])
        row.update(report=None,reportStatus='unavailable')
        continuity(self.base,candidate)
        self.assertEqual(original,row['report'])
        self.assertEqual(original['retrievedAt'],candidate['retainedReportSources'][0]['retrievedAt'])
        again=copy.deepcopy(candidate)
        next(r for r in again['results'] if r['report']==original).update(report=None,reportStatus='unavailable')
        continuity(candidate,again)
        self.assertEqual(original['retrievedAt'],again['retainedReportSources'][0]['retrievedAt'])
    def test_legitimate_result_window_advances(self):
        candidate=copy.deepcopy(self.base)
        rows=[r for r in candidate['results'] if r['game']=='pick3plus' and r['session']=='DAY']
        oldest=min(rows,key=lambda r:r['date'])
        oldest['date']='2026-10-26'
        candidate['queryWindow']['end']='2026-10-26'
        continuity(self.base,candidate)
    def test_expired_scratch_requires_explicit_exclusion(self):
        prior=copy.deepcopy(self.base)
        game=prior['scratch']['games'][0];game['lastDayToRedeem']='2026-10-24'
        candidate=copy.deepcopy(prior);candidate['scratch']['games'].pop(0)
        with self.assertRaises(ValueError):continuity(prior,candidate)
        candidate['scratch']['excludedExpiredGameIds'].append(game['id'])
        continuity(prior,candidate)
    def test_same_day_source_time_regression(self):
        candidate=copy.deepcopy(self.base)
        candidate['scratch']['sourceTimestamp']='October 25, 2026 01:00 AM'
        with self.assertRaises(ValueError):continuity(self.base,candidate)
    def test_missing_report_provenance_rejected(self):
        prior=copy.deepcopy(self.base);prior['sources']=[]
        candidate=copy.deepcopy(self.base)
        next(r for r in candidate['results'] if r['report']).update(report=None,reportStatus='unavailable')
        with self.assertRaises(ValueError):continuity(prior,candidate)

if __name__=='__main__':unittest.main()
