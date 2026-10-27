import copy
from datetime import datetime, timezone
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch
from urllib.parse import parse_qs, unquote, urlparse
from tooling import wyoming_coverage as coverage
from tooling.tests import test_wyoming_draws as draw_tests
from tooling.tests import test_wyoming_keno as keno_tests

NOW = datetime(2026,10,27,3,tzinfo=timezone.utc)


class WyomingCollectionTests(unittest.TestCase):
    def fetch(self, url):
        self.calls += 1
        if self.calls == self.fail:
            raise OSError('controlled request failure')
        if '/api/v1/game/all?' in url:
            return json.dumps({'status':'success','data':{'games':[
                dict(identifier=g,type='rapid' if g=='keno' else 'draw',isRetired=False) for g in coverage.GAMES]}}).encode()
        if url.endswith('/v1/draw-games'):
            return json.dumps([dict(id=s[0],activeTo=None) for s in coverage.draws.SPECS.values()]).encode()
        if url.endswith('/v1/rapid-games'):
            return json.dumps([dict(id=coverage.draws.KENO_ID,activeTo=None,minDrawValue=1,maxDrawValue=80,
                drawFrequencyInSeconds=240,drawFrequencyInMinutes=4,hasProgressiveJackpots=False)]).encode()
        if '/list-drawings?' in url:
            game=next(g for g,s in coverage.draws.SPECS.items() if s[0] in url)
            a=draw_tests.WyomingDrawTests().row(game);b=copy.deepcopy(a)
            older={'cowboy-draw':'2026-10-19T20:00:00Z','powerball':'2026-10-22T02:59:00Z',
                   'mega-millions':'2026-10-21T03:00:00Z','millionaire-for-life':'2026-10-24T03:15:00Z',
                   '2by2':'2026-10-24T02:30:00Z'}[game]
            a['results']['drawResult']['drawingNumber']=2
            b['when']['drawTime']=older;b['results']['drawResult']['asOf']=older
            return json.dumps([a,b]).encode()
        if '/draw-numbers-by-date/' in url:
            start,end=url.rsplit('/',2)[1:]
            return json.dumps(dict(start=unquote(start),end=unquote(end),min=96,max=100)).encode()
        if '/drawings/' in url:
            rows=[]
            for i in range(5):
                r=keno_tests.WyomingKenoTests().row();r['result']['drawingNumber']=100-i
                r['result']['drawingDate']=f'2026-10-27T00:{56-i*4:02}:00Z'
                rows.append(r)
            return json.dumps(rows).encode()
        if '/api/v1/game/rules?' in url:
            game=parse_qs(urlparse(url).query)['identifier'][0]
            return json.dumps({'game':game}).encode()
        return b'synthetic image bytes'

    def setUp(self):
        self.calls=0;self.fail=None
        # Transaction tests isolate transport/rules; literal rule/image validation
        # is covered separately by test_wyoming_rules and retained source audit.
        self.mock=patch.object(coverage,'parse_rules',side_effect=lambda raw,g,**kw: {'game':g,'rules':['fixed']})
        self.mock.start();self.addCleanup(self.mock.stop)

    def candidate(self):
        self.calls=0
        return coverage.collect(self.fetch,lambda:NOW)

    def test_complete_coupling_and_no_private_fields(self):
        data=self.candidate()
        self.assertEqual(self.calls,21)
        self.assertEqual(len(data['results']),15)
        self.assertEqual(len(data['rules']),6)
        self.assertTrue(all(r['reportStatus']=='unavailable' for r in data['results']))
        self.assertNotIn('customerId',json.dumps(data))

    def test_every_request_failure_preserves_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'snapshot.json'
            coverage.refresh(path,self.fetch,lambda:NOW);original=path.read_bytes()
            for position in range(1,22):
                self.calls=0;self.fail=position
                with self.subTest(position=position),self.assertRaises(OSError):
                    coverage.refresh(path,self.fetch,lambda:NOW)
                self.assertEqual(path.read_bytes(),original)
                self.assertEqual(list(Path(directory).iterdir()),[path])

    def test_disk_replace_failure_preserves_bytes(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'snapshot.json'
            coverage.refresh(path,self.fetch,lambda:NOW);original=path.read_bytes()
            with patch('os.replace',side_effect=OSError('controlled disk failure')),self.assertRaises(OSError):
                coverage.refresh(path,self.fetch,lambda:NOW)
            self.assertEqual(path.read_bytes(),original)
            self.assertEqual(list(Path(directory).iterdir()),[path])

    def test_correction_loss_and_regression(self):
        prior=self.candidate()
        mutations=[lambda d:d['results'][0]['numbers'].reverse(),
                   lambda d:d['results'].pop(),
                   lambda d:d.update(updatedAt='2026-10-26T00:00:00Z'),
                   lambda d:d['queryWindow'].update(end='2026-10-26T00:00:00Z'),
                   lambda d:d['rules'][0].update(rules=['changed']),
                   lambda d:d['results'][0].update(drawId=0)]
        for mutate in mutations:
            candidate=copy.deepcopy(prior);mutate(candidate)
            with self.assertRaises(ValueError):coverage.continuity(prior,candidate)
        candidate=copy.deepcopy(prior)
        for row in candidate['results']:row['sourceRetrievedAt']='2026-10-27T04:00:00Z'
        coverage.continuity(prior,candidate)

    def test_clock_regression_and_keno_range_mismatch(self):
        with self.assertRaises(ValueError):
            coverage.collect(self.fetch,lambda:datetime(2026,10,27))
        fetch=self.fetch
        def corrupt(url):
            raw=fetch(url)
            if '/draw-numbers-by-date/' in url:
                data=json.loads(raw);data['end']='2026-10-27T02:00:00Z';return json.dumps(data).encode()
            return raw
        with self.assertRaises(ValueError):coverage.collect(corrupt,lambda:NOW)

    def test_new_window_advances_and_interior_loss_rejected(self):
        prior=self.candidate();candidate=copy.deepcopy(prior)
        rows=[r for r in candidate['results'] if r['game']=='keno']
        for r in rows:
            r['drawId']+=5
            r['drawTimeUtc']=coverage.draws.instant(r['drawTimeUtc']).replace(hour=1).isoformat()
        coverage.continuity(prior,candidate)
        candidate=copy.deepcopy(prior)
        rows=[r for r in candidate['results'] if r['game']=='keno']
        rows[-2]['drawId']=101;rows[-2]['drawTimeUtc']='2026-10-27T01:00:00+00:00'
        with self.assertRaises(ValueError):coverage.continuity(prior,candidate)

    def test_correction_is_rejected_before_disk_replace(self):
        with tempfile.TemporaryDirectory() as directory:
            path=Path(directory)/'snapshot.json'
            coverage.refresh(path,self.fetch,lambda:NOW);original=path.read_bytes()
            candidate=json.loads(original);candidate['results'][0]['numbers'].reverse()
            with patch.object(coverage,'collect',return_value=candidate),self.assertRaises(ValueError):
                coverage.refresh(path,self.fetch,lambda:NOW)
            self.assertEqual(path.read_bytes(),original)

    def test_catalog_and_config_changes_rejected(self):
        for endpoint, mutate in [
            ('/api/v1/game/all?',lambda d:d['data']['games'].pop()),
            ('/v1/draw-games',lambda d:d[0].update(activeTo='2026-10-27T00:00:00Z')),
            ('/v1/rapid-games',lambda d:d[0].update(hasProgressiveJackpots=True)),
            ('/v1/rapid-games',lambda d:d[0].update(drawFrequencyInSeconds=60)),
        ]:
            def corrupt(url):
                raw=self.fetch(url)
                if (endpoint in url if '?' in endpoint else url.endswith(endpoint)):
                    d=json.loads(raw);mutate(d);return json.dumps(d).encode()
                return raw
            with self.subTest(endpoint=endpoint),self.assertRaises(ValueError):
                coverage.collect(corrupt,lambda:NOW)

    def test_query_seconds_and_actual_capture_precision(self):
        stamp=NOW.replace(microsecond=123456)
        data=coverage.collect(self.fetch,lambda:stamp)
        self.assertEqual(data['queryWindow']['end'],NOW.isoformat())
        self.assertEqual(data['sources'][0]['retrievedAt'],stamp.isoformat())
