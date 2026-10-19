import json
import unittest
from html import escape
from tooling.iowa_html_schedules import SPEC_PATH, verified_html_schedule

SPECS = json.loads(SPEC_PATH.read_text())


def fixture(game):
    blocks = []
    for section in SPECS[game]['sections']:
        if section['kind'] == 'table':
            rows = ''.join('<tr>' + ''.join('<td>' + escape(cell) + '</td>' for cell in row) + '</tr>' for row in section['rows'])
            blocks.append('<table id="' + section['id'] + '">' + rows + '</table>')
        elif section['kind'] in ('ul', 'ol'):
            tag = section['kind']
            blocks.append('<' + tag + '>' + ''.join('<li>' + escape(item) + '</li>' for item in section['items']) + '</' + tag + '>')
        else:
            tag = section['kind']
            blocks.append('<' + tag + '>' + escape(section['text']) + '</' + tag + '>')
    return '<div class="primary-content">' + ''.join(blocks) + '</div>'


class HtmlSchedulesTest(unittest.TestCase):
    def test_complete_tables_and_literal_qualifications(self):
        expected_rows = {'millionaire_for_life': [4, 3], 'pick3': [6], 'pick4': [8]}
        for game in SPECS:
            result = verified_html_schedule(game, fixture(game))
            self.assertEqual([len(s['rows']) for s in result['sections'] if s['kind'] == 'table'], expected_rows.get(game, []))
        text = str(verified_html_schedule('millionaire_for_life', fixture('millionaire_for_life')))
        for phrase in ['minimum', '20 years', '$50,000', 'Section 6.C.', '60 days', 'divided equally']:
            self.assertIn(phrase, text)

    def test_changed_cash_sharing_or_missing_footnote_rejected(self):
        source = fixture('millionaire_for_life')
        for old, new in [('$18,000,000', '$19,000,000'), ('Divided**', 'Fixed'), ('60 days', ''), ('21 or more', '22 or more')]:
            with self.assertRaises(ValueError):
                verified_html_schedule('millionaire_for_life', source.replace(old, new))

    def test_changed_or_missing_combinations_rejected(self):
        for game in ['pick3', 'pick4']:
            source = fixture(game)
            for old, new in [('Back Pair', 'Front Pair'), ('Exact Order', 'Any Order'), ('<tr>', '<tr><td>extra</td>')]:
                with self.assertRaises(ValueError):
                    verified_html_schedule(game, source.replace(old, new))

    def test_all_family_qualifications_are_guarded(self):
        changes = {
            'powerball': ('does not apply to Double Play winnings', 'applies to Double Play winnings'),
            'mega_millions': ('randomly assigned', 'shared by all tickets'),
            'lotto_america': ('not eligible', 'eligible'),
            'xsos': ('cash only', 'annuity only'),
            'pick3_rules': ('90 days', '180 days'),
            'pick4_rules': ('9:40 p.m.', '10 p.m.'),
        }
        for game, (before, after) in changes.items():
            raw = fixture(game)
            self.assertIn(before, raw)
            with self.assertRaises(ValueError):
                verified_html_schedule(game, raw.replace(before, after))

    def test_nested_source_rule_sections_preserved(self):
        raw = fixture('mega_millions')
        raw = raw.replace('<h3>How To Play</h3>', '<div id="ContentPlaceHolder1_newMatrixApril5"><h3>How To Play</h3>')
        raw = raw.replace('<h3>Cash vs. Annuity Option</h3>', '</div><h3>Cash vs. Annuity Option</h3>')
        self.assertEqual(verified_html_schedule('mega_millions', raw)['sections'], SPECS['mega_millions']['sections'])
        with self.assertRaises(ValueError):
            verified_html_schedule('mega_millions', raw.replace('newMatrixApril5', 'unknownMatrix'))

    def test_pick_play_type_list_cannot_disappear(self):
        raw = fixture('pick4_rules')
        start, end = raw.index('<ul>'), raw.index('</ul>') + 5
        with self.assertRaises(ValueError):
            verified_html_schedule('pick4_rules', raw[:start] + raw[end:])

    def test_wrong_game_duplicate_container_and_unknown_fail(self):
        with self.assertRaises(ValueError):
            verified_html_schedule('pick3', fixture('pick4'))
        with self.assertRaises(ValueError):
            verified_html_schedule('pick3', fixture('pick3') * 2)
        with self.assertRaises(ValueError):
            verified_html_schedule('other', fixture('pick3'))

    def test_whitespace_and_markup_not_value_changes(self):
        source = fixture('pick3').replace('Exact Order', '<b>Exact</b>  Order')
        self.assertEqual(verified_html_schedule('pick3', source)['sections'], SPECS['pick3']['sections'])


if __name__ == '__main__':
    unittest.main()
