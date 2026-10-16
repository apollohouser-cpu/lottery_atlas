from datetime import date
from pathlib import Path
import unittest
from lxml import html
from tooling.nebraska_powerball_report import parse_powerball

RAW=(Path(__file__).parents[1]/'fixtures/nebraska/powerball.html').read_text()
TODAY=date(2026,10,16)


class PowerballTests(unittest.TestCase):
    def test_literal_three_reports(self):
        r=parse_powerball(RAW,today=TODAY)
        self.assertEqual([len(x['tiers']) for x in r['reports']],[9,8,9])
        self.assertEqual(r['multiplier'],3)
        self.assertEqual(r['reports'][1]['tiers'][1]['prizeLabel'],'$50,000')
        self.assertEqual(r['reports'][2]['tiers'][0]['prizeLabel'],'$10,000,000')
        self.assertNotIn('advertisedJackpot',r)
        self.assertIn('never sum',r['limitation'])

    def test_no_multiplication_of_source_prizes(self):
        for value in [2,3,4,5,10]:
            d=html.fromstring(RAW);d.xpath('//table')[0].xpath('.//tr')[1].xpath('./td')[-1].text=str(value)
            r=parse_powerball(html.tostring(d),today=TODAY)
            self.assertEqual(r['reports'][1]['tiers'][1]['prizeLabel'],'$50,000')
            self.assertEqual(r['reports'][2]['tiers'][0]['prizeLabel'],'$10,000,000')

    def test_wrong_dates_geography_labels(self):
        for old,new in [('in Nebraska','nationwide'),('Double Play drawing results for 10/14/2026','Double Play drawing results for 10/12/2026'),('Powerball Powerplay drawing results','Powerball drawing results'),('$10,000,000','$600,000,000'),('1 in 292,201,338','1 in 999'),('the Power Play multiplier will not apply to Double Play prizes.','removed')]:
            self.assertIn(old,RAW)
            with self.subTest(new=new),self.assertRaises(ValueError):parse_powerball(RAW.replace(old,new),today=TODAY)

    def test_incomplete_and_invalid_count(self):
        for operation in ['missing','negative','decimal','extra']:
            d=html.fromstring(RAW);t=d.xpath('//table')[3];row=t.xpath('.//tr')[-1]
            if operation=='missing':row.getparent().remove(row)
            elif operation=='extra':
                from copy import deepcopy
                row.addnext(deepcopy(row))
            else:row.xpath('./td')[-1].text='-1' if operation=='negative' else '1.5'
            with self.subTest(operation=operation),self.assertRaises(ValueError):parse_powerball(html.tostring(d),today=TODAY)


if __name__=='__main__':unittest.main()
