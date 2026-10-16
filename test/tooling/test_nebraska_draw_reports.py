from datetime import date
from pathlib import Path
import unittest
from tooling.nebraska_draw_reports import parse_regular_report

ROOT = Path(__file__).parents[1] / 'fixtures/nebraska'
TODAY = date(2026, 10, 16)


class NebraskaReportTests(unittest.TestCase):
    def test_six_official_reports(self):
        for family, group, count in [('Pick 5','pick-5',4),('Millionaire for Life','millionaire-for-life',9),('Pick 3','pick-3',9),('Pick 4','pick-4',16),('MyDaY','myday',7),('Powerball Xs and Os','xs-and-os',5)]:
            with self.subTest(family=family):
                report=parse_regular_report((ROOT/(group+'.html')).read_bytes(),family,today=TODAY)
                self.assertEqual(len(report['tiers']),count)
                self.assertEqual(report['geographicUnit'],'Nebraska')
                self.assertEqual(report['countUnit'],'Winners (source label)')

    def test_literal_prizes_and_zero_preserved(self):
        report=parse_regular_report((ROOT/'pick-5.html').read_bytes(),'Pick 5',today=TODAY)
        self.assertEqual(report['tiers'][0]['sourceWinners'],0)
        self.assertEqual(report['tiers'][-1]['sourceWinners'],3124)
        self.assertEqual(report['tiers'][-1]['prizeLabel'],'Free $1 Quick Pick Play')
        report=parse_regular_report((ROOT/'millionaire-for-life.html').read_bytes(),'Millionaire for Life',today=TODAY)
        self.assertEqual(report['tiers'][0]['prizeLabel'],'$1 Million a Year for Life')

    def test_malformed_variants_fail_closed(self):
        raw=(ROOT/'pick-5.html').read_text()
        changes=[('in Nebraska','nationwide'),
                 ('drawing results for 10/15/2026','drawing results for 10/14/2026'),
                 ('Pick 5 Regular','Pick 5 Other'),
                 ('<th>Winners</th>','<th>Claims</th>'),
                 ('5 of 5','6 of 6'),('$500','$501'),
                 ('1 in 658,008','1 in 650,000'),
                 ('3124','-1'),('3124','3.5'),('3124','N/A'),('3124','03'),('3124','3,12')]
        for old,new in changes:
            self.assertIn(old,raw)
            with self.subTest(change=new),self.assertRaises(ValueError):
                parse_regular_report(raw.replace(old,new),'Pick 5',today=TODAY)

    def test_missing_and_duplicate_reports(self):
        from lxml import html
        raw=(ROOT/'pick-5.html').read_bytes()
        for operation in ['remove_tier','duplicate_heading','remove_table']:
            d=html.fromstring(raw);table=d.xpath('//table[caption]')[0]
            if operation=='remove_tier':
                row=table.xpath('.//tr')[-1];row.getparent().remove(row)
            elif operation=='duplicate_heading':
                from copy import deepcopy
                h=d.xpath('//h2[contains(.,"drawing results for")]')[0];h.addprevious(deepcopy(h))
            else:table.getparent().remove(table)
            with self.subTest(operation=operation),self.assertRaises(ValueError):
                parse_regular_report(html.tostring(d),'Pick 5',today=TODAY)


if __name__=='__main__': unittest.main()
