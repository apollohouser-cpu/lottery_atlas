import unittest
from pathlib import Path
from lxml import html
from tooling.import_new_mexico_reports import parse_paired_report
ROOT=Path(__file__).parent/'fixtures/new_mexico'
class PairedReportTests(unittest.TestCase):
    def raw(self,g):return (ROOT/(g+'_report.html')).read_text()
    def draw(self,g,**changes):
        return dict(dict(game=g,variant='base',session=None,date='2026-10-24',multiplier=2 if g=='powerball' else 4),**changes)
    def test_both_reports_and_columns(self):
        for g,count,value in [('powerball',3641,21897),('lottoamerica',2310,11939)]:
            r=parse_paired_report(self.raw(g),self.draw(g))
            self.assertEqual((17,count,value),(len(r['tiers']),r['totalPrizesWon'],r['totalPrizeValue']))
            self.assertEqual(2,len({t['column'] for t in r['tiers']}))
    def test_literal_weekday_heading_uses_explicit_date(self):
        raw=self.raw('lottoamerica').replace("Yesterday's", "Saturday's")
        self.assertEqual('2026-10-24',parse_paired_report(raw,self.draw('lottoamerica'))['date'])
        with self.assertRaises(ValueError):parse_paired_report(raw.replace("Saturday's","Friday's"),self.draw('lottoamerica'))
    def test_exact_joins(self):
        for g in ['powerball','lottoamerica']:
            for key,val in [('date','2026-10-21'),('session','DAY'),('variant','double_play'),('multiplier',3)]:
                with self.subTest(g=g,key=key),self.assertRaises(ValueError):parse_paired_report(self.raw(g),self.draw(g,**{key:val}))
    def test_geography_and_date(self):
        for g in ['powerball','lottoamerica']:
            for old,new in [('New Mexico','National'),('October 24','October 23')]:
                with self.subTest(g=g,old=old),self.assertRaises(ValueError):parse_paired_report(self.raw(g).replace(old,new),self.draw(g))
    def test_group_header_and_column_swap(self):
        for g in ['powerball','lottoamerica']:
            t=html.fromstring(self.raw(g));row=t.xpath('//table')[0].xpath('.//tr')[2];cells=row.xpath('./td|./th');cells[1].text='0';cells[2].text='$1'
            with self.assertRaises(ValueError):parse_paired_report(html.tostring(t),self.draw(g))
            with self.assertRaises(ValueError):parse_paired_report(self.raw(g).replace('rowspan="2"','rowspan="3"',1),self.draw(g))
    def test_count_and_totals(self):
        for g,old,new in [('powerball','>1587<','>1586<'),('powerball','$21,897','$21,898'),('lottoamerica','>809<','>808<'),('lottoamerica','$11,939','$11,940')]:
            self.assertIn(old,self.raw(g))
            with self.subTest(g=g,old=old),self.assertRaises(ValueError):parse_paired_report(self.raw(g).replace(old,new),self.draw(g))
    def test_jackpot_unknown_and_dash_not_zero(self):
        for g in ['powerball','lottoamerica']:
            for idx,val in [(2,'1'),(3,'0')]:
                t=html.fromstring(self.raw(g));t.xpath('//table')[0].xpath('.//tr')[2].xpath('./td|./th')[idx].text=val
                with self.subTest(g=g,idx=idx),self.assertRaises(ValueError):parse_paired_report(html.tostring(t),self.draw(g))
    def test_missing_duplicate_tiers(self):
        for g in ['powerball','lottoamerica']:
            t=html.fromstring(self.raw(g));row=t.xpath('//table')[0].xpath('.//tr')[-1];row.getparent().remove(row)
            with self.assertRaises(ValueError):parse_paired_report(html.tostring(t),self.draw(g))
            with self.assertRaises(ValueError):parse_paired_report(self.raw(g)*2,self.draw(g))
if __name__=='__main__':unittest.main()
