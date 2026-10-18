from datetime import datetime, timezone, timedelta
import json
from pathlib import Path
import tempfile
import unittest
from urllib.parse import unquote
from unittest.mock import patch
from tooling.collect_south_dakota_draws import collect, API
from tooling.south_dakota_draw_results import SPECS

FIXTURES=Path(__file__).parent/'fixtures'/'south_dakota'
NOW=datetime(2026,10,18,12,tzinfo=timezone.utc)


def source(url):
    if url.startswith(API):
        identifier=unquote(url[len(API):])
        slug=next(s for s,v in SPECS.items() if v[0]==identifier)
        return (FIXTURES/f'draws-{slug}.json').read_bytes()
    slug=url.rstrip('/').split('/')[-1]
    return ('<script id="__NEXT_DATA__">'+(FIXTURES/f'rules-{slug}.json').read_text()+'</script>').encode()


class CollectionTest(unittest.TestCase):
    def setUp(self):
        self.tmp=tempfile.TemporaryDirectory();self.addCleanup(self.tmp.cleanup)
        self.output=Path(self.tmp.name)/'stage.json'

    def test_complete_stage(self):
        data=collect(self.output,fetch=source,now=NOW)
        self.assertEqual(14,len(data['results']));self.assertEqual(7,len(data['schedules']))
        self.assertNotIn('schemaVersion',data)
        self.assertEqual(14,len(data['reports']))
        self.assertEqual(2,sum(not r['tiers'] for r in data['reports']))

    def test_every_request_failure_preserves_bytes_dates(self):
        collect(self.output,fetch=source,now=NOW);before=self.output.read_bytes()
        for fail in range(13):
            calls=0
            def broken(url):
                nonlocal calls
                calls+=1
                if calls==fail+1:raise OSError('controlled source outage')
                return source(url)
            with self.subTest(fail=fail),self.assertRaises(OSError):
                collect(self.output,fetch=broken,now=NOW+timedelta(minutes=1))
            self.assertEqual(before,self.output.read_bytes())

    def test_bad_schedule_retains_whole_collection(self):
        collect(self.output,fetch=source,now=NOW);before=self.output.read_bytes()
        def changed(url):return source(url).replace(b'$500,000',b'$500,001')
        with self.assertRaises(ValueError):collect(self.output,fetch=changed,now=NOW)
        self.assertEqual(before,self.output.read_bytes())

    def test_clock_regression_retains_bytes(self):
        collect(self.output,fetch=source,now=NOW);before=self.output.read_bytes()
        with self.assertRaises(ValueError):collect(self.output,fetch=source,now=NOW-timedelta(minutes=1))
        self.assertEqual(before,self.output.read_bytes())

    def test_corrected_numbers_require_review(self):
        collect(self.output,fetch=source,now=NOW);before=self.output.read_bytes()
        def changed(url):
            raw=source(url)
            if url==API+'Dakota%20Cash':
                d=json.loads(raw);d['draws'][1]['results'][0]['primary'][0]='4';return json.dumps(d).encode()
            return raw
        with self.assertRaises(ValueError):collect(self.output,fetch=changed,now=NOW)
        self.assertEqual(before,self.output.read_bytes())

    def test_failed_replace_cleans_temporary_preserves_bytes(self):
        collect(self.output,fetch=source,now=NOW);before=self.output.read_bytes()
        with patch('tooling.collect_south_dakota_draws.os.replace',side_effect=OSError('disk failure')):
            with self.assertRaises(OSError):collect(self.output,fetch=source,now=NOW)
        self.assertEqual(before,self.output.read_bytes())
        self.assertEqual([self.output],list(Path(self.tmp.name).iterdir()))

    def test_changed_report_count_retains_bytes(self):
        collect(self.output,fetch=source,now=NOW);before=self.output.read_bytes()
        def changed(url):
            raw=source(url)
            if url==API+'Dakota%20Cash':
                d=json.loads(raw);d['draws'][1]['prizeTiers'][1]['shareCount']+=1
                return json.dumps(d).encode()
            return raw
        with self.assertRaisesRegex(ValueError,'report correction'):
            collect(self.output,fetch=changed,now=NOW)
        self.assertEqual(before,self.output.read_bytes())

    def test_missing_retained_reports_fail_closed(self):
        collect(self.output,fetch=source,now=NOW)
        d=json.loads(self.output.read_text());d.pop('reports')
        self.output.write_text(json.dumps(d));before=self.output.read_bytes()
        with self.assertRaisesRegex(ValueError,'schema migration'):
            collect(self.output,fetch=source,now=NOW)
        self.assertEqual(before,self.output.read_bytes())

    def test_no_baseline_failure_does_not_create_output(self):
        with self.assertRaises(OSError):collect(self.output,fetch=lambda u: (_ for _ in ()).throw(OSError('outage')),now=NOW)
        self.assertFalse(self.output.exists())

if __name__=='__main__':unittest.main()
