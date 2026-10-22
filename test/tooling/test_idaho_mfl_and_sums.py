from datetime import date
from pathlib import Path
import unittest
from lxml import html

from tooling.idaho_mfl_results import parse_results
from tooling.idaho_sum_schedules import parse_schedule

FIXTURES = Path(__file__).parent / 'fixtures'


class IdahoHtmlTests(unittest.TestCase):
    def tree(self):
        return html.fromstring((FIXTURES / 'idaho_mfl_history.html').read_bytes())

    def parse(self, tree):
        return parse_results(html.tostring(tree), as_of=date(2026, 10, 22))

    def test_two_results_from_complete_history(self):
        r = self.parse(self.tree())
        self.assertEqual([v['drawDate'] for v in r], ['2026-10-21', '2026-10-20'])
        self.assertEqual(r[0]['specialNumber'], '05')
        self.assertNotIn('jackpot', r[0])

    def test_generic_check_form_cannot_replace_history(self):
        t = self.tree(); table = t.xpath('//table')[0]
        t.xpath('//body')[0].append(html.fromstring('<form><table><tr><td>Powerball</td></tr></table></form>'))
        self.assertEqual(len(self.parse(t)), 2)
        table.getparent().remove(table)
        with self.assertRaises(ValueError): self.parse(t)

    def test_bad_older_row_rejects_entire_table(self):
        for value in ['59', '00', 'x', '1.0']:
            t = self.tree(); t.xpath('//tbody/tr[last()]//li')[0].text = value
            with self.subTest(value=value), self.assertRaises(ValueError): self.parse(t)

    def test_duplicate_date_or_ball_and_wrong_page(self):
        for kind in ['date', 'ball', 'page', 'future', 'short']:
            t = self.tree()
            if kind == 'date': t.xpath('//tbody/tr[2]/td')[0].text = '10/21/26'
            if kind == 'ball': t.xpath('//tbody/tr[1]//li')[1].text = '17'
            if kind == 'page': t.xpath('//title')[0].text = 'Powerball | Idaho Lottery'
            if kind == 'future': t.xpath('//tbody/tr[1]/td')[0].text = '10/23/26'
            if kind == 'short':
                for row in t.xpath('//tbody/tr')[1:]: row.getparent().remove(row)
            with self.subTest(kind=kind), self.assertRaises(ValueError): self.parse(t)

    def test_image_contracts_and_changed_bytes(self):
        for game, file, count in [('pick-3', 'idaho_sumitup3.png', 14), ('pick-4', 'idaho_pick4sum.png', 37)]:
            raw = (FIXTURES / file).read_bytes()
            self.assertEqual(len(parse_schedule(game, raw)['rows']), count)
            with self.assertRaises(ValueError): parse_schedule(game, raw + b'changed')
            result = parse_schedule(game, raw); result['rows'].clear()
            self.assertEqual(len(parse_schedule(game, raw)['rows']), count)


if __name__ == '__main__':
    unittest.main()
