import unittest
from pathlib import Path
from lxml import html
from tooling.new_mexico_draw_rules import PAGES, parse_rules

ROOT=Path(__file__).parent/'fixtures/new_mexico'
class NewMexicoRulesTests(unittest.TestCase):
    def raw(self,game):return (ROOT/(game+'_rules.html')).read_text()
    def test_all_schedules(self):
        rules=[parse_rules(self.raw(g),g) for g in PAGES]
        self.assertEqual(10,sum(len(r['tables']) for r in rules))
        self.assertEqual(111,sum(len(t) for r in rules for t in r['tables']))
    def test_prize_mutation_rejected(self):
        for game in PAGES:
            t=html.fromstring(self.raw(game))
            cell=next(c for c in t.xpath('//td|//th') if '$' in c.text_content())
            cell.text='Changed prize'
            with self.subTest(game=game),self.assertRaises(ValueError):parse_rules(html.tostring(t),game)
    def test_missing_or_duplicate_tables_rejected(self):
        for duplicate in [False,True]:
            t=html.fromstring(self.raw('powerball')); table=t.xpath('//table')[0]
            if duplicate:table.getparent().append(html.fromstring(html.tostring(table)))
            else:table.getparent().remove(table)
            with self.subTest(duplicate=duplicate),self.assertRaises(ValueError):parse_rules(html.tostring(t),'powerball')
    def test_caveat_mutation_rejected(self):
        for game,old in [('powerball','$150 million'),('pick3plus','$125,000'),('megamillions','at the time of purchase')]:
            raw=self.raw(game);self.assertIn(old,raw)
            with self.subTest(game=game),self.assertRaises(ValueError):parse_rules(raw.replace(old,'CHANGED'),'{}'.format(game))
    def test_merged_cell_semantics_preserved(self):
        t=html.fromstring(self.raw('pick4plus')); cell=t.xpath('//td|//th')[0];cell.set('rowspan','2')
        with self.assertRaises(ValueError):parse_rules(html.tostring(t),'pick4plus')
    def test_wrong_identity_rejected(self):
        with self.assertRaises(ValueError):parse_rules(self.raw('powerball'),'lottoamerica')
    def test_returned_contract_cannot_mutate_baseline(self):
        a=parse_rules(self.raw('powerball'),'powerball');a['tables'][0][0][0]['text']='changed'
        b=parse_rules(self.raw('powerball'),'powerball');self.assertNotEqual('changed',b['tables'][0][0][0]['text'])
if __name__=='__main__':unittest.main()
