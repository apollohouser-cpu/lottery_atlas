import json
from pathlib import Path
import unittest
from tooling.south_dakota_schedules import SLUGS, parse_schedules, fragment_blocks

ROOT = Path(__file__).parent / 'fixtures' / 'south_dakota'


def encode(data):
    return '<html><script id="__NEXT_DATA__" type="application/json">'+json.dumps(data)+'</script></html>'


class ScheduleTest(unittest.TestCase):
    def data(self, slug='dakota-cash'):
        return json.loads((ROOT/f'rules-{slug}.json').read_text())

    def test_all_seven_pages_physical_rows(self):
        counts = {}
        for s in SLUGS:
            sections = parse_schedules(encode(self.data(s)), s)
            counts[s] = sum(len(b['rows']) for t in sections for b in t['blocks'] if b['kind']=='table')
            self.assertTrue(any(t['title']=='Claim Your Prize' for t in sections))
        self.assertEqual([18,9,12,9,9,5,9], list(counts.values()))

    def test_ez_match_and_parimutuel_footer_preserved(self):
        sections = parse_schedules(encode(self.data()), 'dakota-cash')
        ez = next(t for t in sections if t['title']=='Winning EZ Match')
        table = next(b for b in ez['blocks'] if b['kind']=='table')
        self.assertEqual(['$100','1:12,000'], table['rows'][0])
        self.assertEqual(['$2','1:9'], table['rows'][-1])
        flat = json.dumps(sections)
        self.assertIn('pari-mutuel',flat)
        self.assertIn('1:4.97',flat)
        self.assertIn('divided equally',flat)

    def test_source_mfl_typo_not_silently_corrected(self):
        sections = parse_schedules(encode(self.data('millionaire-for-life')), 'millionaire-for-life')
        flat = json.dumps(sections)
        self.assertIn('Lucky for Life',flat)
        self.assertIn('$1 Million a Year for Life*',flat)

    def test_changed_prize_rejected(self):
        raw = encode(self.data()).replace('$100', '$101')
        with self.assertRaises(ValueError): parse_schedules(raw,'dakota-cash')

    def test_removed_qualification_rejected(self):
        data=self.data();tabs=data['props']['pageProps']['post']['blocks'][0]['attributes']['data']['howtoplay']['howToPlayTabs']
        tabs.pop()
        with self.assertRaises(ValueError):parse_schedules(encode(data),'dakota-cash')

    def test_wrong_page_and_duplicate_tabs_rejected(self):
        data=self.data();post=data['props']['pageProps']['post'];post['slug']='mega-millions'
        with self.assertRaises(ValueError):parse_schedules(encode(data),'dakota-cash')
        data=self.data();post=data['props']['pageProps']['post'];post['blocks']*=2
        with self.assertRaises(ValueError):parse_schedules(encode(data),'dakota-cash')

    def test_tables_keep_order_and_surrounding_notes(self):
        blocks=fragment_blocks('Before<table><tr><th>A</th><th>B</th></tr><tr><td>1<br>2</td><td>$3</td></tr></table>After')
        self.assertEqual(['text','table','text'],[b['kind'] for b in blocks])
        self.assertEqual('Before',blocks[0]['text']);self.assertEqual('After',blocks[2]['text'])
        self.assertEqual('1\n2',blocks[1]['rows'][0][0])

    def test_ragged_spanning_empty_or_script_content_rejected(self):
        for raw in ['<table><tr><th>A</th><th>B</th></tr><tr><td>1</td></tr></table>',
                    '<table><tr><th>A</th></tr><tr><td colspan="2">1</td></tr></table>',
                    '<table><tr><th>A</th></tr><tr><td></td></tr></table>',
                    '<script>bad()</script>text']:
            with self.subTest(raw=raw), self.assertRaises(ValueError):fragment_blocks(raw)

if __name__=='__main__':unittest.main()
