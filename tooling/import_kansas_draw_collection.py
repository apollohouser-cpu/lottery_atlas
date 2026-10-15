"""Fetch and validate all Kansas inputs before atomic collection replacement.

Run with python -m tooling.import_kansas_draw_collection --output PATH.
"""
import argparse
from collections import Counter
from datetime import datetime, timezone
import json
from pathlib import Path
import subprocess
import tempfile
from urllib.parse import urlencode

from tooling.kansas_draw_collection import assemble_collection
from tooling.kansas_draw_results import GROUPS
from tooling.kansas_draw_schedules import SCHEMAS, cms_from_html

API = 'https://gateway-web.loyalty.playonkansas.com/services/jackpot/api/v1'


def fetch(url):
    return subprocess.run(['curl', '--fail', '--silent', '--show-error', '--location',
                           '--proto', '=https', '--proto-redir', '=https',
                           '--connect-timeout', '15', '--max-time', '60', url],
                          check=True, capture_output=True).stdout


def result_url(group):
    query = {'gameId': GROUPS[group][0], 'jackpotStatus': 'COMPLETE',
             'page': 0, 'size': 2, 'sort': 'externalId,drawDate,desc'}
    if group in {'powerball', 'powerball-double-play'}:
        query['doublePlay'] = 'TRUE' if group == 'powerball-double-play' else 'FALSE'
    return API + '/jackpot-results?' + urlencode(query)


def validate_window(value, previous=None):
    if value.get('schemaVersion') != 1 or value.get('state') != 'KS':
        raise ValueError('Wrong collection identity')
    rows = value['reports']
    if len(rows) != 24 or Counter(r['group'] for r in rows) != Counter({g: 2 for g in GROUPS}):
        raise ValueError('Incomplete result window')
    if len({r['id'] for r in rows}) != 24 or set(value['schedules']) != set(SCHEMAS):
        raise ValueError('Duplicate results or incomplete schedules')
    prizes = value['advertisedPrizes']
    if len(prizes) != 4 or {p['scheduleKey'] for p in prizes} != {'powerball', 'lotto-america', 'super-kansas-cash', 'megamillions'}:
        raise ValueError('Incomplete advertised prizes')
    if previous is None:
        return
    validate_window(previous)
    if datetime.fromisoformat(value['retrievedAt']) < datetime.fromisoformat(previous['retrievedAt']):
        raise ValueError('Retrieval timestamp regression')
    for group in GROUPS:
        old = sorted(r['sourceDrawTimestamp'] for r in previous['reports'] if r['group'] == group)
        new = sorted(r['sourceDrawTimestamp'] for r in rows if r['group'] == group)
        if any(a < b for a, b in zip(new, old)):
            raise ValueError('Result window regression')
    old_ids = {r['id']: r for r in previous['reports']}
    for row in rows:
        if row['id'] in old_ids and row['sourceDrawTimestamp'] != old_ids[row['id']]['sourceDrawTimestamp']:
            raise ValueError('Existing result identity changed timestamp')
    old_prizes = {p['scheduleKey']: p for p in previous['advertisedPrizes']}
    for prize in prizes:
        if prize['sourceDrawTimestamp'] < old_prizes[prize['scheduleKey']]['sourceDrawTimestamp']:
            raise ValueError('Advertised draw timestamp regression')


def refresh(output, fetcher=fetch, now=None):
    now = now or datetime.now(timezone.utc)
    if now.tzinfo is None:
        raise ValueError('Retrieval requires timezone')
    output = Path(output)
    previous = json.loads(output.read_text()) if output.exists() else None
    pages = {group: json.loads(fetcher(result_url(group))) for group in GROUPS}
    schedules = {slug: cms_from_html(fetcher(f'https://playonkansas.com/games/draw-games/{slug}'))
                 for slug in SCHEMAS}
    teams = json.loads(fetcher(API + '/game-number/15'))
    advertised = json.loads(fetcher(API + '/jackpot-results/games'))
    result = assemble_collection(pages, schedules, teams, advertised, now.isoformat())
    validate_window(result, previous)
    if previous and {k: v for k, v in result.items() if k != 'retrievedAt'} == {k: v for k, v in previous.items() if k != 'retrievedAt'}:
        return previous
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', dir=output.parent,
                                         prefix=output.name + '.', suffix='.tmp', delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(json.dumps(result, ensure_ascii=False, indent=2) + '\n')
        temporary.replace(output)
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink()
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    print('Validated Kansas results:', len(refresh(args.output)['reports']))
