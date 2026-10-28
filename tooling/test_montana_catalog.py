import gzip,unittest
from pathlib import Path
from tooling.montana_catalog import combine_pages,parse_page
class CatalogTest(unittest.TestCase):
 def pages(self,kind='scratch'):
  slug='scratch-games' if kind=='scratch' else 'treasure-play';count=12 if kind=='scratch' else 3
  return {n:gzip.decompress(Path('tooling/fixtures/montana/catalog/'+slug+('' if n==1 else '-'+str(n))+'.html.gz').read_bytes()).decode() for n in range(1,count+1)}
 def test_complete_catalogs_literal_only(self):
  for kind,count,rows in [('scratch',57,1100),('treasure-play',12,52)]:
   d=combine_pages(self.pages(kind),kind);self.assertEqual(len(d['entries']),count);self.assertEqual(sum(len(g['scheduleRows']) for g in d['entries']),rows)
   self.assertTrue(all(g['remainingStatus']=='unavailable' and g['identityKind']=='website-cms-entry' for g in d['entries']))
 def test_missing_title_explicit(self):
  d=combine_pages(self.pages(),'scratch');g=next(g for g in d['entries'] if g['cmsEntryId']=='2863');self.assertIsNone(g['title']);self.assertEqual(g['titleStatus'],'unavailable')
 def test_missing_page(self):
  p=self.pages();p.pop(12)
  with self.assertRaises(ValueError):combine_pages(p,'scratch')
 def test_duplicate_identity(self):
  p=self.pages();p[2]=p[1]
  with self.assertRaises(ValueError):combine_pages(p,'scratch')
 def test_identity_price_type(self):
  s=self.pages()[1]
  for bad in [s.replace('e-loop-item-2857','e-loop-item-bad'),s.replace('scratch_amounts-1-games','scratch_amounts-x-games'),s.replace(' scratch_game ',' other ')]:
   with self.assertRaises(ValueError):parse_page(bad,'scratch')
 def test_table_header_missing_row_structure(self):
  s=self.pages()[1]
  with self.assertRaises(ValueError):parse_page(s.replace('>WIN<','>COUNT<'),'scratch')
  with self.assertRaises(ValueError):parse_page(s.replace('</td>','',1),'scratch')
 def test_literal_jackpot_not_numeric(self):
  d=combine_pages(self.pages('treasure-play'),'treasure-play');self.assertTrue(any(r['prizeText']=='Jackpot' for g in d['entries'] for r in g['scheduleRows']))
if __name__=='__main__':unittest.main()
