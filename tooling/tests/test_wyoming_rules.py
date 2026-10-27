import copy
import json
from pathlib import Path
import unittest
from tooling.wyoming_draw_rules import SPEC_PATH, parse_rules


class WyomingRuleTests(unittest.TestCase):
    def setUp(self):
        self.specs=json.loads(SPEC_PATH.read_text())

    def payload(self,game):
        return {'status':'success','data':{'rules':copy.deepcopy(self.specs[game]['rules'])}}

    def test_keno_tables_and_prize_categories(self):
        result=parse_rules(self.payload('keno'),'keno')
        tables=[c['data'] for r in result['rules'] for c in r['content'] if c['contentType']=='csvTable']
        self.assertEqual(len(tables),10)
        self.assertEqual(sum(len(t['rows']) for t in tables),38)
        self.assertEqual(tables[0]['rows'][0],['10','$200,000'])

    def test_changed_prize_or_missing_table_rejected(self):
        p=self.payload('keno')
        table=next(c for r in p['data']['rules'] for c in r['content'] if c['contentType']=='csvTable')
        table['data']['rows'][0][1]='$0'
        with self.assertRaises(ValueError):parse_rules(p,'keno')
        p=self.payload('keno');p['data']['rules'][0]['content'].pop()
        with self.assertRaises(ValueError):parse_rules(p,'keno')

    def test_image_bytes_required(self):
        for g in self.specs:
            if g=='keno':continue
            with self.subTest(game=g),self.assertRaises(ValueError):parse_rules(self.payload(g),g)
            with self.subTest(game=g),self.assertRaises(ValueError):parse_rules(self.payload(g),g,image_bytes=b'changed')

    def test_wrong_game_status_and_prose(self):
        with self.assertRaises(ValueError):parse_rules(self.payload('keno'),'retired')
        p=self.payload('keno');p['status']='error'
        with self.assertRaises(ValueError):parse_rules(p,'keno')
        p=self.payload('keno');p['data']['rules'][0]['title']='Changed'
        with self.assertRaises(ValueError):parse_rules(p,'keno')

    def test_return_is_independent(self):
        result=parse_rules(self.payload('keno'),'keno');result['rules'].clear()
        self.assertTrue(parse_rules(self.payload('keno'),'keno')['rules'])
