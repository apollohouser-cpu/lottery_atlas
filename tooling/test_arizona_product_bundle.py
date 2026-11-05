import copy
import json
import unittest
from pathlib import Path
from arizona_product_bundle import select_refresh

class ProductBundleTests(unittest.TestCase):
    def setUp(self):
        root=Path(__file__).parent/'fixtures/arizona'
        def read(name):return json.loads((root/name).read_text())
        self.baseline={'scratchers':read('scratchers-details-batch.json')+read('scratchers-november-additions.json'),
                       'fast-play':read('fast-play-details-batch.json')+[read('207-detail.json')]}
    def test_complete_reviewed_matrix_and_ended_status(self):
        r=select_refresh(self.baseline,self.baseline)
        self.assertEqual(len(r['scratchers']),60);self.assertEqual(len(r['fast-play']),26)
        self.assertEqual(next(x for x in r['fast-play'] if x['gameNumber']=='203')['sourceStatus'],'ended')
        self.assertTrue(all(not x['inventoryAvailable'] for rows in r.values() for x in rows))
    def test_missing_duplicate_and_cross_catalog_source_rejected(self):
        for mutation in ['missing','duplicate','cross']:
            c=copy.deepcopy(self.baseline)
            if mutation=='missing':c['scratchers'].pop()
            elif mutation=='duplicate':c['scratchers'].append(c['scratchers'][0])
            else:c['scratchers'][0]=c['fast-play'][0]
            with self.assertRaises(ValueError):select_refresh(c,self.baseline)
    def test_late_failure_does_not_mutate_retained(self):
        before=copy.deepcopy(self.baseline);c=copy.deepcopy(self.baseline)
        c['fast-play'][-1]['rules']['text']='changed'
        with self.assertRaises(ValueError):select_refresh(c,self.baseline)
        self.assertEqual(self.baseline,before)
    def test_header_number_cannot_be_trusted_from_url_alone(self):
        c=copy.deepcopy(self.baseline);c['scratchers'][0]['header']=c['scratchers'][0]['header'].replace('#1401','#9999')
        with self.assertRaises(ValueError):select_refresh(c,self.baseline)
    def test_invalid_date_rejected(self):
        c=copy.deepcopy(self.baseline);c['scratchers'][0]['header']=c['scratchers'][0]['header'].replace('1/31/2023','2/31/2023')
        with self.assertRaises(ValueError):select_refresh(c,c)
