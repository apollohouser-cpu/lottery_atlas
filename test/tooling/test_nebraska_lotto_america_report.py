from datetime import date
from pathlib import Path
import unittest
from lxml import html
from tooling.nebraska_lotto_america_report import parse_lotto_america

RAW=(Path(__file__).parents[1]/'fixtures/nebraska/lotto-america.html').read_text()
TODAY=date(2026,10,16)


class LottoAmericaTests(unittest.TestCase):
    def test_official_report(self):
        r=parse_lotto_america(RAW,today=TODAY)
        self.assertEqual([len(x['tiers']) for x in r['reports']],[9,8])
        self.assertEqual(r['reports'][0]['tiers'][0]['prizeLabel'],'Jackpot')
        self.assertEqual(r['reports'][1]['tiers'][0]['prizeLabel'],'$20,000 X 2')
        self.assertEqual(r['reports'][1]['tiers'][-1]['sourceWinners'],132)
        self.assertEqual(r['multiplier'],2)

    def test_all_valid_multipliers(self):
        for multiplier in [2,3,4,5]:
            d=html.fromstring(RAW)
            d.xpath('//table')[0].xpath('.//tr')[1].xpath('./td')[-1].text=str(multiplier)
            raw=html.tostring(d).decode().replace(' X 2',f' X {multiplier}')
            self.assertEqual(parse_lotto_america(raw,today=TODAY)['multiplier'],multiplier)

    def test_malformed_variants(self):
        for old,new in [('in Nebraska','nationwide'),('All Star Factor drawing results for 10/14/2026','All Star Factor drawing results for 10/12/2026'),('$20,000 X 2','$20,000 X 3'),('$20,000 X 2','$40,000'),('1 in 25,989,600','1 in 99'),('<th>Winners</th>','<th>Claims</th>'),('The All Star Bonus multiplier does not apply to the jackpot prize.','removed')]:
            self.assertIn(old,RAW)
            with self.subTest(new=new),self.assertRaises(ValueError):parse_lotto_america(RAW.replace(old,new),today=TODAY)

    def test_missing_extra_and_invalid_count(self):
        for op in ['missing','extra','negative','fraction']:
            d=html.fromstring(RAW);table=d.xpath('//table')[-1];row=table.xpath('.//tr')[-1]
            if op=='missing':row.getparent().remove(row)
            elif op=='extra':
                from copy import deepcopy
                row.addnext(deepcopy(row))
            else:row.xpath('./td')[-1].text='-1' if op=='negative' else '1.5'
            with self.subTest(op=op),self.assertRaises(ValueError):parse_lotto_america(html.tostring(d),today=TODAY)


if __name__=='__main__':unittest.main()
