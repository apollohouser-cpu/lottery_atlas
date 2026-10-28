import unittest
from pathlib import Path
from tooling.montana_rules import parse_rules

GAMES=['powerball','mega-millions','millionaire-for-life','lotto-america','montana-cash','big-sky-bonus']
class MontanaRulesTest(unittest.TestCase):
 def source(self,g):return Path('tooling/fixtures/montana/'+g+'-rules.html').read_text()
 def test_six_contracts_seventy_physical_rows(self):
  rows=0
  for g in GAMES:
   d=parse_rules(self.source(g),g)
   rows+=sum(e[:2]==['start','tr'] for s in d['sections'] for e in s['events'])
  self.assertEqual(rows,70)
 def test_changed_prize(self):
  with self.assertRaises(ValueError):parse_rules(self.source('powerball').replace('$50,000','$50,001'),'powerball')
 def test_changed_qualifications(self):
  for g,old,new in [('powerball','does not apply','does apply'),('montana-cash','Max Cash','Free Cash'),('big-sky-bonus','1 and 31','1 and 32')]:
   with self.subTest(g=g),self.assertRaises(ValueError):parse_rules(self.source(g).replace(old,new),g)
 def test_missing_duplicate_or_wrong_identity(self):
  s=self.source('mega-millions')
  for bad in [s+s,s.replace('e-n-tab-content-1006112493','other'),s.replace('Mega Millions - Montana Lottery','Powerball - Montana Lottery')]:
   with self.assertRaises(ValueError):parse_rules(bad,'mega-millions')
 def test_unbalanced_and_changed_cells(self):
  s=self.source('lotto-america')
  for bad in [s.replace('</td>','',1),s.replace('<td','<td rowspan="2"',1)]:
   with self.assertRaises(ValueError):parse_rules(bad,'lotto-america')
 def test_whitespace_and_headlines(self):
  s=self.source('millionaire-for-life');expected=parse_rules(s,'millionaire-for-life')
  self.assertEqual(parse_rules('<h1>New jackpot headline</h1>'+s.replace('><','>\n<'),'millionaire-for-life'),expected)
 def test_source_discrepancies_preserved(self):
  d=parse_rules(self.source('montana-cash'),'montana-cash')
  text=' '.join(e[1] for s in d['sections'] for e in s['events'] if e[0]=='text')
  self.assertIn('Double Play',text)
  pb=parse_rules(self.source('powerball'),'powerball');self.assertEqual(len(pb['sections']),4)
 def test_retired_rejected(self):
  with self.assertRaises(ValueError):parse_rules(self.source('powerball'),'lucky-for-life')
if __name__=='__main__':unittest.main()
