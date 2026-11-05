import copy
import json
from pathlib import Path
import unittest
from arizona_endings import parse_capture,validate_continuity

class EndingTests(unittest.TestCase):
    def setUp(self):
        self.data=json.loads((Path(__file__).parent/'fixtures/arizona/ending-notices.json').read_text())

    def test_literal_dates_and_distinct_semantics(self):
        for kind,count in [('scratchers',14),('fast-play',5)]:
            result=validate_continuity(self.data[kind],self.data[kind],kind)
            self.assertEqual(len(result['notices']),count)
            self.assertTrue(all(not n['claimDeadlineNormalized'] for n in result['notices']))
            self.assertEqual(bool(result['sourceConflicts']),kind=='fast-play')
        self.assertEqual(parse_capture(self.data['fast-play'],'fast-play')['notices'][-1]['gameNumber'],'203')

    def test_bad_dates_links_duplicates_and_partial_capture_reject(self):
        for defect in ['date','link','duplicate','partial']:
            c=copy.deepcopy(self.data['scratchers']);rows=c['tables'][0]['rows']
            if defect=='date':rows[1][1]['text']='02/30/2027'
            if defect=='link':rows[1][0]['links'][0]['href']='https://example.com/'
            if defect=='duplicate':rows[2]=copy.deepcopy(rows[1])
            if defect=='partial':rows[-1][0]['text']='See All'
            with self.subTest(defect=defect),self.assertRaises(ValueError):parse_capture(c,'scratchers')

    def test_changed_notice_requires_review(self):
        c=copy.deepcopy(self.data['fast-play']);c['tables'][0]['rows'][1][1]['text']='05/19/2026'
        with self.assertRaises(ValueError):validate_continuity(c,self.data['fast-play'],'fast-play')
