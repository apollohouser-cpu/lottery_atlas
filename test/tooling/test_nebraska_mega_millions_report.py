from datetime import date
from pathlib import Path
import unittest
from lxml import html
from tooling.nebraska_mega_millions_report import parse_mega_millions

RAW=(Path(__file__).parents[1]/'fixtures/nebraska/mega-millions.html').read_text()
TODAY=date(2026,10,16)


class MegaMillionsTests(unittest.TestCase):
    def test_official_report_and_literal_schedules(self):
        r=parse_mega_millions(RAW,today=TODAY)
        self.assertEqual(len(r['tiers']),9)
        self.assertEqual(sum(len(t['counts']) for t in r['tiers']),41)
        self.assertEqual(r['tiers'][0]['counts'],[{'multiplier':1,'sourceWinners':0}])
        self.assertEqual(r['tiers'][-1]['counts'][-1],{'multiplier':10,'sourceWinners':26})
        self.assertEqual(r['prizeSchedule'][2][1],'$2M - $10M')
        self.assertIn('before the per-play multiplier',r['limitation'])

    def test_changed_source_rejected(self):
        for old,new in [('in Nebraska','nationwide'),('drawing results for 10/13/2026','drawing results for 10/09/2026'),('$2M - $10M','$1M - $5M'),('Each play costs $5','Each play costs $2'),('a multiplier is randomly assigned','removed'),('The multiplier does not apply to the jackpot prize.','removed'),('5 of 5 ($1 Million)','5 of 5 ($2 Million)')]:
            self.assertIn(old,RAW)
            with self.subTest(new=new),self.assertRaises(ValueError):parse_mega_millions(RAW.replace(old,new),today=TODAY)

    def test_multiplier_rows_missing_extra_invalid(self):
        for op in ['missing','extra','wrong_multiplier','negative','fraction']:
            d=html.fromstring(RAW);table=d.xpath('//table')[-1];row=table.xpath('.//tr')[1]
            if op=='missing':row.getparent().remove(row)
            elif op=='extra':
                from copy import deepcopy
                row.addnext(deepcopy(row))
            elif op=='wrong_multiplier':row.xpath('./td')[0].text='2X'
            else:row.xpath('./td')[-1].text='-1' if op=='negative' else '1.5'
            with self.subTest(op=op),self.assertRaises(ValueError):parse_mega_millions(html.tostring(d),today=TODAY)

    def test_old_rules_fail_closed(self):
        from unittest.mock import patch
        with patch('tooling.nebraska_mega_millions_report.parse_results',return_value=[{'drawDate':'2025-04-04'}]):
            with self.assertRaisesRegex(ValueError,'Old rules'):parse_mega_millions(RAW,today=TODAY)


if __name__=='__main__':unittest.main()
