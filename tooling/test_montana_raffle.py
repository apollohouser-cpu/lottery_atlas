import unittest
from pathlib import Path
from tooling.montana_raffle import parse_raffle
class RaffleTest(unittest.TestCase):
 def source(self):return Path('tooling/fixtures/montana/raffle-offer.html').read_text()
 def test_offer_not_actual_winners(self):
  d=parse_raffle(self.source());self.assertEqual(d['resultStatus'],'unavailable');self.assertEqual(d['historicalResultsStatus'],'excluded');self.assertEqual(d['salesStartTimezone'],'unpublished');self.assertNotEqual(d['finalDrawingDate'],d['promotionalDrawingDate'])
 def test_changes_fail_closed(self):
  for old,new in [('November 1, 2026','November 2, 2026'),('720000','730000'),('2,700','2,701'),('December 28, 2026','December 29, 2026')]:
   with self.subTest(old=old),self.assertRaises(ValueError):parse_raffle(self.source().replace(old,new))
 def test_historical_table_not_imported(self):
  a=self.source();b=a+'<table><tr><td>December 26, 2025</td><td>000001</td></tr></table>'
  self.assertEqual(parse_raffle(a),parse_raffle(b))
 def test_missing_identity_and_sections(self):
  for old,new in [('Montana millionaire - Montana Lottery','Wrong Lottery'),('ed510c5','missing')]:
   with self.assertRaises(ValueError):parse_raffle(self.source().replace(old,new))
 def test_private_copy(self):
  a=parse_raffle(self.source());a['sections'].clear();self.assertEqual(len(parse_raffle(self.source())['sections']),6)
if __name__=='__main__':unittest.main()
