from datetime import date
from pathlib import Path
import unittest
from lxml import html
from tooling.nebraska_2by2_report import parse_2by2

RAW=(Path(__file__).parents[1]/'fixtures/nebraska/2by2.html').read_text()
TODAY=date(2026,10,16)


class TwoByTwoTests(unittest.TestCase):
    def test_off_tuesday_counts_omitted(self):
        r=parse_2by2(RAW,today=TODAY)
        self.assertEqual([t['sourceWinners'] for t in r['reports'][0]['tiers']],[0,8,168,1536])
        self.assertFalse(r['reports'][1]['applicable'])
        self.assertTrue(all('sourceWinners' not in t for t in r['reports'][1]['tiers']))
        self.assertEqual(len(r['schedule']),8)
        self.assertEqual(r['reports'][1]['tiers'][-1]['prizeLabel'],'2 Free $1 Quick Pick Plays')

    def test_tuesday_fixture_counts_retained(self):
        # Synthetic date change exercises eligibility; not a historical report.
        r=parse_2by2(RAW.replace('10/15/2026','10/20/2026'),today=date(2026,10,21))
        self.assertTrue(r['reports'][1]['applicable'])
        self.assertEqual([t['sourceWinners'] for t in r['reports'][1]['tiers']],[0,0,0,0])

    def test_off_tuesday_nonzero_rejected(self):
        d=html.fromstring(RAW);d.xpath('//table')[-1].xpath('.//tr')[1].xpath('./td')[-1].text='1'
        with self.assertRaises(ValueError):parse_2by2(html.tostring(d),today=TODAY)

    def test_mutated_source_fails_closed(self):
        for old,new in [('in Nebraska','nationwide'),('2by2 Tuesday drawing results for 10/15/2026','2by2 Tuesday drawing results for 10/14/2026'),('1 in 105,625','1 in 999'),('$44,000','$45,000'),('1536','1.5'),('Any Multi-draw selection that is not divisible by 7 is not eligible','removed'),('then prizes will be awarded on a pari-mutuel basis','removed')]:
            self.assertIn(old,RAW)
            with self.subTest(new=new),self.assertRaises(ValueError):parse_2by2(RAW.replace(old,new),today=TODAY)

    def test_missing_table_fails(self):
        d=html.fromstring(RAW);t=d.xpath('//table')[-1];t.getparent().remove(t)
        with self.assertRaises(ValueError):parse_2by2(html.tostring(d),today=TODAY)


if __name__=='__main__':unittest.main()
