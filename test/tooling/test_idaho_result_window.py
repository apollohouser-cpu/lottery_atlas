import copy
from datetime import date
import json
from pathlib import Path
import unittest

from tooling.idaho_draw_results import GAMES
from tooling.idaho_result_window import build_window, source_dates

FIX = Path(__file__).parent / 'fixtures'
SAMPLES = json.loads((FIX / 'idaho_result_samples.json').read_text())


def pages():
    result = {}
    for slug, name in GAMES.items():
        headers = ['Date', 'Winning Numbers'] + (['Multiplier'] if slug in ('powerball', 'lotto-america') else []) + ['Jackpot']
        dates = ['10/21/26'] if slug.startswith('pick-') else ['10/21/26', '10/20/26', '10/19/26']
        result[slug] = '<html><head><title>' + name + ' | Idaho Lottery</title></head><body><div id="tab4"><table><thead><tr>' + ''.join('<th>'+h+'</th>' for h in headers) + '</tr></thead><tbody>' + ''.join('<tr><td data-title="Date">'+d+'</td></tr>' for d in dates) + '</tbody></table></div></body></html>'
    result['millionaire-for-life'] = (FIX / 'idaho_mfl_history.html').read_text()
    return result


def response(url):
    slug, date_text = url.split('/')[-2:]
    result = copy.deepcopy(SAMPLES[slug])
    result['data']['draw_date'] = date_text
    result['data']['title'] = date_text + '-' + GAMES[slug]
    return result


class IdahoWindowTests(unittest.TestCase):
    def test_complete_window_and_pick_previous_date(self):
        calls = []
        def fetch(url):
            calls.append(url)
            return response(url)
        r = build_window(pages(), fetch, as_of=date(2026, 10, 22))
        self.assertEqual(len(r['results']), 22)
        self.assertEqual(len(calls), 14)
        self.assertIn('2026-10-20', [x['drawDate'] for x in r['results'] if x['group'] == 'pick-4-night'])

    def test_every_request_failure_aborts(self):
        for failure in range(14):
            count = 0
            def fetch(url):
                nonlocal count
                count += 1
                if count == failure + 1: raise OSError('controlled request failure')
                return response(url)
            with self.subTest(failure=failure), self.assertRaises(OSError):
                build_window(pages(), fetch, as_of=date(2026, 10, 22))

    def test_wrong_dated_response_rejected(self):
        with self.assertRaises(ValueError):
            build_window(pages(), lambda url: SAMPLES[url.split('/')[-2]], as_of=date(2026, 10, 22))

    def test_incomplete_pages_and_bad_old_date(self):
        p = pages(); del p['pick-3']
        with self.assertRaises(ValueError): build_window(p, response, as_of=date(2026, 10, 22))
        for bad in ['10/21/26', '02/30/26', '10/23/26']:
            raw = pages()['powerball'].replace('10/19/26', bad)
            with self.subTest(bad=bad), self.assertRaises(ValueError): source_dates(raw, 'powerball', as_of=date(2026, 10, 22))


if __name__ == '__main__': unittest.main()
