from pathlib import Path
import unittest
from lxml import html
from tooling.idaho_draw_rules import SPECS, parse_rules

FIXTURES = Path(__file__).parent / 'fixtures'


class IdahoDrawRulesTest(unittest.TestCase):
    def raw(self, slug):
        return (FIXTURES / f'idaho_rules_{slug}.html').read_bytes()

    def test_all_rules_and_material_qualifications(self):
        parsed = {s: parse_rules(self.raw(s), s) for s in SPECS}
        self.assertIn('unique multiplier', parsed['mega-millions']['sourceText'])
        self.assertIn('$18,000,000', parsed['millionaire-for-life']['sourceText'])
        self.assertIn('$2,200,000', parsed['millionaire-for-life']['sourceText'])
        self.assertIn('liability limits', parsed['powerball-xs-os']['sourceText'])
        self.assertTrue(parsed['pick-3']['limitations'])
        self.assertTrue(parsed['powerball']['limitations'])

    def test_changed_added_or_removed_prose_rejected(self):
        for slug in SPECS:
            for mode in ['added', 'removed', 'changed']:
                with self.subTest(slug=slug, mode=mode):
                    doc = html.fromstring(self.raw(slug))
                    section = doc.xpath('//*[@id="tab2"]')[0]
                    if mode == 'added':
                        extra = html.Element('p'); extra.text = 'New payout condition'; section.append(extra)
                    else:
                        node = next(n for n in section.iter() if n.tag not in ['style', 'script'] and n.text and len(n.text.strip()) > 80)
                        if mode == 'removed': node.text = ''
                        else: node.text = 'Changed rule: ' + node.text
                    with self.assertRaises(ValueError): parse_rules(html.tostring(doc), slug)

    def test_wrong_game_and_missing_section(self):
        with self.assertRaises(ValueError): parse_rules(self.raw('pick-3'), 'pick-4')
        with self.assertRaises(ValueError): parse_rules(b'<html/>', 'pick-3')

    def test_presentation_styles_ignored(self):
        doc = html.fromstring(self.raw('millionaire-for-life'))
        doc.xpath('//style')[0].text = '.different { color: red; }'
        self.assertEqual(parse_rules(html.tostring(doc), 'millionaire-for-life'),
                         SPECS['millionaire-for-life'])
