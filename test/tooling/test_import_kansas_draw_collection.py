import copy
from datetime import datetime, timedelta
import json
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

from tooling.import_kansas_draw_collection import API, refresh, result_url, validate_window
from tooling.kansas_draw_results import GROUPS
from tooling.kansas_draw_schedules import SCHEMAS

NOW = datetime.fromisoformat('2026-10-15T01:00:00+00:00')
FIXTURES = Path(__file__).parents[1] / 'fixtures/kansas'

def fixture(name):
    return json.loads((FIXTURES / f'{name}.json').read_text())


class KansasImportTests(unittest.TestCase):
    def fetcher(self):
        names = {'pick3-midday': 'pick-3-midday', 'pick3-evening': 'pick-3',
                 'powerball-double-play': 'powerball-double-play'}
        pages = {g: fixture(names.get(g, data[3])) for g, data in GROUPS.items()}
        schedules = {slug: fixture(f'{slug}-schedule') for slug in SCHEMAS}
        teams, prizes = fixture('team-mapping'), fixture('advertised-games')
        urls = {result_url(g): json.dumps(p) for g, p in pages.items()}
        for slug, cms in schedules.items():
            flight = 'prefix"cms":' + json.dumps(cms)
            urls[f'https://playonkansas.com/games/draw-games/{slug}'] = '<script>self.__next_f.push(' + json.dumps([1, flight]) + ')</script>'
        urls[API + '/game-number/15'] = json.dumps(teams)
        urls[API + '/jackpot-results/games'] = json.dumps(prizes)
        return urls.__getitem__

    def test_refresh_unchanged_retains_exact_bytes_and_timestamp(self):
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'collection.json'
            first=refresh(path,self.fetcher(),NOW)
            before=path.read_bytes()
            second=refresh(path,self.fetcher(),NOW+timedelta(minutes=1))
            self.assertEqual(first,second)
            self.assertEqual(before,path.read_bytes())
            self.assertEqual(24,len(first['reports']))

    def test_fetch_parse_and_replace_failure_preserve_bytes(self):
        with tempfile.TemporaryDirectory() as folder:
            path=Path(folder)/'collection.json'
            refresh(path,self.fetcher(),NOW)
            before=path.read_bytes()
            real=self.fetcher()
            for mode in ['network','parse','replace']:
                def fetch(url):
                    if url.endswith('/games') and mode=='network':raise OSError('request failed')
                    if url.endswith('/games') and mode=='parse':return '{}'
                    return real(url)
                with self.subTest(mode=mode):
                    if mode=='replace':
                        changed=json.loads(before);changed['coverage']['window']='previous wording'
                        path.write_text(json.dumps(changed));before=path.read_bytes()
                        with patch.object(Path,'replace',side_effect=OSError('storage failure')):
                            with self.assertRaises(OSError):refresh(path,fetch,NOW)
                    else:
                        with self.assertRaises((OSError,ValueError)):refresh(path,fetch,NOW)
                    self.assertEqual(before,path.read_bytes())
                    self.assertEqual([],list(Path(folder).glob('*.tmp')))

    def test_window_and_identity_regressions_reject(self):
        with tempfile.TemporaryDirectory() as folder:
            first=refresh(Path(folder)/'data',self.fetcher(),NOW)
        changes=[lambda x:x['reports'].pop(),
                 lambda x:x.update(retrievedAt='2020-01-01T00:00:00+00:00'),
                 lambda x:x['reports'][0].update(sourceDrawTimestamp='2020-01-01T00:00:00Z'),
                 lambda x:x['reports'][0].update(sourceDrawTimestamp='2030-01-01T00:00:00Z'),
                 lambda x:x['advertisedPrizes'][0].update(sourceDrawTimestamp='2020-01-01T00:00:00Z')]
        for change in changes:
            changed=copy.deepcopy(first);change(changed)
            with self.assertRaises(ValueError):validate_window(changed,first)

    def test_powerball_requests_have_explicit_variant_filter(self):
        self.assertIn('doublePlay=FALSE',result_url('powerball'))
        self.assertIn('doublePlay=TRUE',result_url('powerball-double-play'))

if __name__=='__main__':unittest.main()
