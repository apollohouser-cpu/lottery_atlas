import importlib.util
from pathlib import Path
import unittest

spec=importlib.util.spec_from_file_location('audit',Path(__file__).resolve().parents[2]/'tooling/audit_census_retailer_geocodes.py')
m=importlib.util.module_from_spec(spec);spec.loader.exec_module(m)
SOURCE=dict(id='1',address='10 MAIN STREET',city='PROVIDENCE',stateCode='RI',zip='02903')
ROW=['1','10 MAIN STREET, PROVIDENCE, RI, 02903','Match','Exact','10 MAIN ST, PROVIDENCE, RI, 02903','-71.5,41.5','123','L']
FEATURE=dict(properties=dict(STATEFP='44',GEOID='44007'),geometry=dict(type='Polygon',coordinates=[[[-72,41],[-71,41],[-71,42],[-72,42],[-72,41]]]))

def audit(rows=None,source=None,features=None):
    return m.audit([SOURCE] if source is None else source,[ROW] if rows is None else rows,[FEATURE] if features is None else features,'RI','44')


class CensusAuditTest(unittest.TestCase):
    def test_exact_candidate_never_publishable(self):
        row=audit()[0]
        self.assertTrue(row['addressCandidate'])
        self.assertFalse(row['publishable'])
        self.assertEqual(row['countyCandidates'],['44007'])
        self.assertIn('interpolation',row['coordinateMethod'])

    def test_nonmatch_and_tie_have_no_coordinates(self):
        for status in ['No_Match','Tie']:
            row=audit(rows=[ROW[:2]+[status]])[0]
            self.assertFalse(row['addressCandidate'])
            self.assertNotIn('latitude',row)

    def test_incomplete_duplicate_unexpected_and_altered_input_fail(self):
        for rows in [[],[ROW,ROW],[['2']+ROW[1:]],[['1','changed']+ROW[2:]], [ROW[:2]+['Unknown']]]:
            with self.subTest(rows=rows),self.assertRaises(ValueError):audit(rows=rows)
        with self.assertRaises(ValueError):audit(source=[SOURCE,SOURCE])
        with self.assertRaises(ValueError):audit(source=[{**SOURCE,'stateCode':'MA'}])

    def test_nonexact_zip_house_and_county_require_review(self):
        cases=[(3,'Non_Exact','non_exact_match'),(4,'12 MAIN ST, PROVIDENCE, RI, 02903','house_number_differs_or_unverified'),(4,'10 MAIN ST, PROVIDENCE, RI, 02904','matched_zip_differs'),(4,'10 MAIN ST, PROVIDENCE, MA, 02903','matched_state_differs'),(5,'-75,41.5','county_not_unique')]
        for index,value,reason in cases:
            row=ROW.copy();row[index]=value
            result=audit(rows=[row])[0]
            self.assertFalse(result['addressCandidate'])
            self.assertIn(reason,result['reviewReasons'])
        result=audit(features=[FEATURE,{**FEATURE,'properties':dict(STATEFP='44',GEOID='44009')}])[0]
        self.assertIn('county_not_unique',result['reviewReasons'])

    def test_invalid_coordinates_and_county_holes(self):
        for coords in ['nan,41','-71,inf','-181,41','0,41','-71']:
            row=ROW.copy();row[5]=coords
            with self.subTest(coords=coords),self.assertRaises(ValueError):audit(rows=[row])
        feature={**FEATURE,'geometry':dict(type='Polygon',coordinates=FEATURE['geometry']['coordinates']+[[[-71.6,41.4],[-71.4,41.4],[-71.4,41.6],[-71.6,41.6],[-71.6,41.4]]])}
        self.assertEqual(audit(features=[feature])[0]['countyCandidates'],[])

if __name__=='__main__':unittest.main()
