import unittest,sys
from pathlib import Path
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'tooling'))
from missouri_public_locator import parse_results

RAW=b'<html><table><thead><tr><th>Click on store name for map and driving directions</th></tr><tr><th>Retailer</th><th>Address</th><th>City</th><th>Games Offered</th></tr></thead><tbody><tr><td><a href="https://www.google.com/maps/search/?api=1&amp;query=Test &amp; Store #2, 1 Main St, Test City MO 65101">Test &amp; Store #2</a></td><td>1 Main St</td><td>Test City</td><td>Draw Games<br>Scratchers<br>Keno 2 Go</td></tr></tbody></table></html>'
class LocatorTests(unittest.TestCase):
    def test_literal_source_labels_and_no_coordinates(self):
        r=parse_results(RAW)[0];self.assertEqual(r['zip'],'65101');self.assertEqual(r['name'],'Test & Store #2');self.assertIsNone(r['latitude']);self.assertIsNone(r['sourceRetailerId'])
    def test_reject_changed_structure_address_and_products(self):
        for raw in [RAW.replace(b'</html>',b''),RAW.replace(b'query=Test',b'query=Wrong'),RAW.replace(b'Keno 2 Go',b'Unknown'),RAW.replace(b'65101',b'6510'),RAW.replace(b'Games Offered',b'Wins')]:
            with self.assertRaises(ValueError):parse_results(raw)
if __name__=='__main__':unittest.main()
