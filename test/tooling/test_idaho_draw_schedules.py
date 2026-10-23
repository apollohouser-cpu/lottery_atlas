import copy
from pathlib import Path
import unittest
from lxml import html
from tooling.idaho_draw_schedules import SPECS, parse_schedule

FIXTURES = Path(__file__).parent / 'fixtures'


class IdahoDrawSchedulesTest(unittest.TestCase):
    def raw(self, slug):
        return (FIXTURES / f'idaho_schedule_{slug}.html').read_bytes()

    def test_all_reviewed_rows_and_qualifications(self):
        schedules = {s: parse_schedule(self.raw(s), s) for s in SPECS}
        self.assertEqual(sum(len(s['rows']) for s in schedules.values()), 70)
        self.assertEqual(schedules['powerball']['headers'][2:],
                         ['Prize with PowerPlay', 'Double Play Prize'])
        self.assertIn('under $150 Million', schedules['powerball']['containerText'])
        self.assertIn('quick pick only', schedules['idaho-cash']['containerText'])
        for s in ['pick-3', 'pick-4']:
            self.assertIn('based on a $1 wager', schedules[s]['containerText'])

    def test_table_mutations_fail_closed(self):
        for slug in SPECS:
            original = html.fromstring(self.raw(slug))
            for mutation in ['missing', 'duplicate', 'prize', 'match', 'header', 'symbol', 'footnote', 'title']:
                with self.subTest(slug=slug, mutation=mutation):
                    doc = copy.deepcopy(original)
                    row = doc.xpath('//tbody/tr')[0]
                    if mutation == 'missing': row.getparent().remove(row)
                    elif mutation == 'duplicate': row.getparent().append(copy.deepcopy(row))
                    elif mutation == 'prize': row.xpath('./td')[1].text = '$0'
                    elif mutation == 'match': row.set('data-number', 'wrong')
                    elif mutation == 'header': doc.xpath('//th')[0].text = 'wrong'
                    elif mutation == 'symbol':
                        symbols = row.xpath('.//li')
                        if symbols: symbols[0].set('class', 'ball_red')
                        else: row.xpath('./td')[0].append(html.Element('li', {'class': 'ball_gray'}))
                    elif mutation == 'footnote': doc.xpath('//span')[-1].text = 'changed'
                    elif mutation == 'title': doc.xpath('//title')[0].text = 'Other Game'
                    with self.assertRaises(ValueError):
                        parse_schedule(html.tostring(doc), slug)

    def test_duplicate_table_and_unknown_game(self):
        doc = html.fromstring(self.raw('powerball'))
        doc.xpath('//body')[0].append(copy.deepcopy(doc.xpath('//table')[0]))
        with self.assertRaises(ValueError): parse_schedule(html.tostring(doc), 'powerball')
        with self.assertRaises(ValueError): parse_schedule(self.raw('powerball'), 'unknown')

    def test_return_is_not_mutable_contract(self):
        result = parse_schedule(self.raw('powerball'), 'powerball')
        result['rows'].clear()
        self.assertEqual(len(parse_schedule(self.raw('powerball'), 'powerball')['rows']), 9)
