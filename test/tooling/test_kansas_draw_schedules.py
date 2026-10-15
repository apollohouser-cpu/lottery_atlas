import json
from pathlib import Path
import unittest
from tooling.kansas_draw_schedules import SCHEMAS, cms_from_html, parse_schedule

FIXTURES = Path(__file__).parents[1] / 'fixtures/kansas'


class KansasScheduleTests(unittest.TestCase):
    def source(self, slug):
        return json.loads((FIXTURES / f'{slug}-schedule.json').read_text())

    def test_literal_schedules_all_eight_families(self):
        total = 0
        for slug in SCHEMAS:
            source = self.source(slug)
            result = parse_schedule(source, slug)
            for actual, expected in zip(result['tables'], source['prizeLegend']):
                self.assertEqual(actual['rows'], [[row[c] for c in expected['columnOrder']] for row in expected['matches']])
                total += len(actual['rows'])
            self.assertTrue(result['rules'])
        self.assertEqual(66, total)
        self.assertEqual(2,len(parse_schedule(self.source('pick-3'),'pick-3')['sourceWarnings']))
        self.assertIn('free ticket',str(parse_schedule(self.source('2-by-2'),'2-by-2')))
        self.assertIn('/yr for Life',str(parse_schedule(self.source('millionaire-for-life'),'millionaire-for-life')))

    def test_structure_identity_and_values_reject(self):
        changes = [lambda x:x.update(slug='other'),lambda x:x.update(gameId=True),
                   lambda x:x.update(jackpotGameNumber='2'),lambda x:x['prizeLegend'].clear(),
                   lambda x:x['prizeLegend'][0]['matches'].pop(),
                   lambda x:x['prizeLegend'][0]['columnOrder'].reverse(),
                   lambda x:x['prizeLegend'][0]['matches'][0].update(match='other'),
                   lambda x:x['prizeLegend'][0]['matches'][0].update(odds=None),
                   lambda x:x['prizeLegend'][0]['matches'][0].update(odds=''),
                   lambda x:x['prizeLegend'][0]['matches'][0].update(extra='unmodeled'),
                   lambda x:x.update(prizeLegendDescription=None),lambda x:x.update(howToPlay=None)]
        for change in changes:
            x=self.source('powerball');change(x)
            with self.assertRaises(ValueError):parse_schedule(x,'powerball')

    def test_partial_qualifications_fail_closed(self):
        x=self.source('powerball')
        x['prizeLegendDescription']['json']['content'].pop(2)
        with self.assertRaises(ValueError):parse_schedule(x,'powerball')

    def test_flight_long_text_uses_utf8_byte_length(self):
        text = 'Bull’s-eye prizes; pari-mutuel limits.\nSecond paragraph.'
        source = {'text': {'nodeType': 'text', 'value': '$14'}, 'literal': '$14'}
        record = '14:T' + format(len(text.encode('utf-8')), 'x') + ',' + text
        def wrap(payload):
            return '<script>self.__next_f.push(' + json.dumps([1, payload]) + ')</script>'
        cms_record = '5:["cms":' + json.dumps(source)
        result = cms_from_html(wrap(record + cms_record))
        self.assertEqual(text, result['text']['value'])
        self.assertEqual('$14', result['literal'])
        for payload in [cms_record, record + '\n' + record + cms_record,
                        cms_record + '\n14:Tffff,short',
                        cms_record + '\n14:T1,®']:
            with self.subTest(payload=payload), self.assertRaises(ValueError):
                cms_from_html(wrap(payload))

    def test_next_flight_decoding_and_ambiguity(self):
        source=self.source('pick-3')
        flight='prefix"cms":'+json.dumps(source)
        script='<script>self.__next_f.push('+json.dumps([1,flight])+')</script>'
        self.assertEqual(source,cms_from_html(script))
        with self.assertRaises(ValueError):cms_from_html(script+script)
        with self.assertRaises(ValueError):cms_from_html('<html></html>')

if __name__ == '__main__':
    unittest.main()
