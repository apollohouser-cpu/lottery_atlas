from collections import Counter
from datetime import datetime,timezone
from pathlib import Path
import json
import sys
import tempfile
import unittest
from unittest.mock import patch
sys.path.insert(0,str(Path(__file__).resolve().parents[2]/'tooling'))
import import_north_carolina_draw_reports as importer


def reports():
    return [dict(id=f'{g}-{s}-{d}',game=g,session=s,drawDate=f'2026-10-0{d}',sourceWarnings=['retained source warning'])
            for g,s in sorted(importer.GROUPS) for d in [6,7]]


class NCRefreshTests(unittest.TestCase):
    def test_history_normalization_dedup_dates_and_bounds(self):
        raw=b'<html><main><a href="/powerball?dd=10/ 05 / 2026">view</a><a href="/powerball?dd=10/07/2026">view</a><a href="/powerball?dd=10/07/2026">duplicate</a><a href="/powerball?dd=10/03/2026">old</a><a href="https://other.example/x">unrelated</a></main></html>'
        self.assertEqual(importer.detail_urls(raw,'powerball'),['https://nclottery.com/powerball?dd=10/07/2026','https://nclottery.com/powerball?dd=10/05/2026'])
        for bad in [raw.replace(b'</html>',b''),raw.replace(b'10/07/2026',b'garbage')]:
            with self.assertRaises(ValueError):importer.detail_urls(bad,'powerball')
        pick=('<html><main>'+''.join(f'<a href="/Pick3-Draw?dn={n}">view</a>' for n in range(20,8,-1))+'</main></html>').encode()
        self.assertEqual(len(importer.detail_urls(pick,'Pick3-Draw',pick=True)),8)

    def test_collection_rejects_missing_duplicate_groups_and_regressions(self):
        rows=reports();importer.validate_collection(rows)
        for bad in [rows[:-1],rows[:-1]+[rows[0]]]:
            with self.assertRaises(ValueError):importer.validate_collection(bad)
        old={'reports':[dict(r,drawDate='2026-10-08') for r in rows]}
        with self.assertRaises(ValueError):importer.validate_collection(rows,old)

    def test_atomic_failure_and_unchanged_timestamp(self):
        rows=reports()
        # Parser semantics have their own source-fixture suite; isolate refresh I/O.
        def game(g):return [r for r in rows if r['game']==g]
        histories=[('h'+str(i),'route'+str(i),lambda docs,today,g=g:game(g)) for i,g in enumerate(['Powerball','Mega Millions','Cash 5','Millionaire for Life','Powerball Xs and Os'])]
        with tempfile.TemporaryDirectory() as directory,patch.object(importer,'HISTORIES',histories),patch.object(importer,'detail_urls',return_value=['https://nclottery.com/detail']),patch.object(importer,'parse_cash_pop',side_effect=lambda raw,today:game('Cash Pop')),patch.object(importer,'parse_pick_reports',side_effect=lambda docs,g,today:game(g)):
            output=Path(directory)/'reports.json';now=datetime(2026,10,9,tzinfo=timezone.utc)
            result=importer.refresh(output,fetcher=lambda u:b'fixture',now=now)
            before=output.read_bytes()
            self.assertEqual(len(result['reports']),28)
            self.assertTrue(all(r['sourceWarnings'] for r in result['reports']))
            self.assertEqual(importer.refresh(output,fetcher=lambda u:b'fixture',now=datetime(2026,10,10,tzinfo=timezone.utc)),result)
            self.assertEqual(output.read_bytes(),before)
            def failure(url):
                if url.endswith('pick4-past'):raise OSError('late fetch failure')
                return b'fixture'
            with self.assertRaises(OSError):importer.refresh(output,fetcher=failure,now=now)
            self.assertEqual(output.read_bytes(),before)
            with patch.object(importer,'parse_pick_reports',return_value=[]):
                with self.assertRaises(ValueError):importer.refresh(output,fetcher=lambda u:b'fixture',now=now)
            self.assertEqual(output.read_bytes(),before)
            self.assertFalse(output.with_suffix('.json.tmp').exists())
