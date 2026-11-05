import copy
import json
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch
from arizona_snapshot import stage
from tooling.arizona_regular_draws import SOURCES
from tooling.arizona_quick_draw import PARSERS
from arizona_rules import CONTRACTS as RULES
from arizona_rule_details import CONTRACTS as DETAILS


def fixture_snapshot():
    root=Path(__file__).parent/'fixtures/arizona'
    def read(name):return json.loads((root/name).read_text())
    names={'powerball-xs-os':'xsos','fantasy-5':'fantasy5','pick-3':'pick3','pick-4':'pick4','5-in-a-line':'five-in-line'}
    def draw(g):return read(names.get(g,g)+'-tables.json')
    rules={}
    details={}
    for path in root.glob('*-rules.json'):
        c=json.loads(path.read_text())
        for g,contract in RULES.items():
            if c['sourceUrl']==contract['sourceUrl']:rules[g]=c
    for path in root.glob('*-rule-details.json'):
        c=json.loads(path.read_text())
        for g,contract in DETAILS.items():
            if c['sourceUrl']==contract['sourceUrl']:details[g]=c
    return {'draws':{'regular':{g:draw(g) for g in SOURCES},'quickDraw':{g:[draw(g)] for g in PARSERS}},
            'products':{'scratchers':read('scratchers-details-batch.json')+read('scratchers-november-additions.json'),
                        'fast-play':read('fast-play-details-batch.json')+[read('207-detail.json')]},
            'rules':rules,'details':details,'endings':read('ending-notices.json')}

class SnapshotTests(unittest.TestCase):
    def setUp(self):self.c=fixture_snapshot()
    def test_single_snapshot_preserves_provenance_and_nonproduction_status(self):
        with tempfile.TemporaryDirectory() as folder:
            p=Path(folder)/'snapshot.json';stage(self.c,self.c,p);r=json.loads(p.read_text())
            self.assertEqual(r['captures'],self.c)
            self.assertFalse(r['productionReady'])
            self.assertEqual(len(r['validated']['draws']['groups']),19)
            self.assertEqual(len(r['validated']['products']['scratchers']),60)
    def test_each_component_failure_preserves_existing_bytes(self):
        for family in self.c:
            with self.subTest(family=family),tempfile.TemporaryDirectory() as folder:
                p=Path(folder)/'snapshot.json';p.write_bytes(b'retained bytes')
                bad=copy.deepcopy(self.c);bad[family]={}
                with self.assertRaises(ValueError):stage(bad,self.c,p)
                self.assertEqual(p.read_bytes(),b'retained bytes')
                self.assertEqual(list(Path(folder).iterdir()),[p])
    def test_replace_failure_preserves_existing_file_and_cleans_temp(self):
        with tempfile.TemporaryDirectory() as folder:
            p=Path(folder)/'snapshot.json';p.write_bytes(b'retained')
            with patch('arizona_snapshot.os.replace',side_effect=OSError('controlled failure')):
                with self.assertRaises(OSError):stage(self.c,self.c,p)
            self.assertEqual(p.read_bytes(),b'retained')
            self.assertEqual(list(Path(folder).iterdir()),[p])
