import copy,unittest
from tooling import test_montana_catalog as catalog_tests
from tooling.montana_catalog import combine_pages
from tooling.montana_catalog_contract import validate_catalog,continuity
class ContractTest(unittest.TestCase):
 @classmethod
 def setUpClass(cls):
  cls.raw=combine_pages(catalog_tests.CatalogTest().pages('treasure-play'),'treasure-play')
 def test_baseline_and_literal_unknowns(self):
  d=validate_catalog(self.raw);self.assertEqual(d['entries'][0]['advertisedJackpot']['amountText'],'$35,317');self.assertEqual(d['entries'][0]['remainingStatus'],'unavailable')
 def test_scratch_contract_preserves_missing_title_and_unknown_inventory(self):
  raw=combine_pages(catalog_tests.CatalogTest().pages('scratch'),'scratch')
  actual=validate_catalog(raw)
  self.assertEqual(len(actual['entries']),57)
  self.assertTrue(any(g['title'] is None for g in actual['entries']))
  self.assertTrue(all(g['advertisedJackpot']['status']=='unavailable' and g['remainingStatus']=='unavailable' for g in actual['entries']))
 def test_estimates_can_rise_or_fall_without_inference(self):
  old=validate_catalog(self.raw)
  for amount in ['$25,000','$40,000','$0']:
   c=copy.deepcopy(self.raw);c['entries'][0]['literalText']=c['entries'][0]['literalText'].replace('$35,317',amount)
   new=validate_catalog(c);self.assertEqual(continuity(old,new),new)
 def test_contract_mutations_rejected(self):
  for field,value in [('title','Fake'),('salesStatus','active'),('remainingStatus','known'),('price',1),('cmsEntryId','999')]:
   c=copy.deepcopy(self.raw);c['entries'][0][field]=value
   with self.assertRaises(ValueError):validate_catalog(c)
  c=copy.deepcopy(self.raw);c['entries'][0]['scheduleRows'][0]['prizeText']='$10'
  with self.assertRaises(ValueError):validate_catalog(c)
 def test_missing_identity_rejected(self):
  c=copy.deepcopy(self.raw);c['entries'].pop()
  with self.assertRaises(ValueError):validate_catalog(c)
 def test_malformed_estimate_rejected(self):
  c=copy.deepcopy(self.raw);c['entries'][0]['literalText']=c['entries'][0]['literalText'].replace('$35,317','$35,317.50')
  with self.assertRaises(ValueError):validate_catalog(c)
if __name__=='__main__':unittest.main()
