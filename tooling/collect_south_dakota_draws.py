"""Private SD staging collector. Reporting and public integration remain gated."""
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import tempfile
from urllib.parse import quote
from urllib.request import Request, urlopen

from tooling.south_dakota_draw_results import SPECS, parse_results
from tooling.south_dakota_schedules import SLUGS, parse_schedules

API = 'https://lottery.sd.gov/api/igt/games/v2/draw-games/draws?game-names='


def fetch_page(url):
    with urlopen(Request(url, headers={'User-Agent':'LotteryAtlas source validation'}), timeout=45) as response:
        raw = response.read(5_000_001)
        if response.status != 200 or len(raw) > 5_000_000:
            raise ValueError('Invalid source response')
        return raw


def check_continuity(previous, current):
    if previous is None:
        return
    if previous.get('stage') != current['stage'] or previous.get('state') != 'South Dakota':
        raise ValueError('Unrecognized retained collection')
    old_time = datetime.fromisoformat(previous['retrievedAt'])
    new_time = datetime.fromisoformat(current['retrievedAt'])
    if old_time.tzinfo is None or old_time > new_time:
        raise ValueError('Retrieval timestamp regression')
    groups = {(r['game'],r['variant']) for r in current['results']}
    if groups != {(r['game'],r['variant']) for r in previous['results']}:
        raise ValueError('Result group loss')
    for group in groups:
        old = [r for r in previous['results'] if (r['game'],r['variant']) == group]
        new = [r for r in current['results'] if (r['game'],r['variant']) == group]
        if len(old) != 2 or len(new) != 2 or max(r['drawDate'] for r in new) < max(r['drawDate'] for r in old):
            raise ValueError('Result date regression')
        indexed = {r['drawId']:r for r in old}
        for r in new:
            if r['drawId'] in indexed and indexed[r['drawId']] != r:
                raise ValueError('Published draw correction requires review')


def collect(output, *, fetch=fetch_page, now=None):
    now = now or datetime.now(timezone.utc)
    if now.tzinfo is None or now.utcoffset() is None:
        raise ValueError('Aware retrieval timestamp required')
    output = Path(output)
    previous = json.loads(output.read_text()) if output.exists() else None
    results, schedules = [], []
    for slug, spec in SPECS.items():
        payload = json.loads(fetch(API + quote(spec[0])))
        results.extend(parse_results(payload, slug, now=now))
    for slug in SLUGS:
        url = f'https://lottery.sd.gov/game/{slug}/'
        sections = parse_schedules(fetch(url), slug)
        schedules.append(dict(slug=slug, sourceUrl=url, sections=sections))
    if len(results) != 14 or len(schedules) != 7:
        raise ValueError('Incomplete staging collection')
    result = dict(stage='private-number-and-schedule-validation-only', state='South Dakota',
                  retrievedAt=now.isoformat(), results=results, schedules=schedules,
                  limitations=['Dated winner/prize reports not integrated; no zero-winner inference.',
                               'API timestamps establish source calendar dates, not exact physical drawing times.',
                               'Literal MFL source retains stale Lucky for Life wording.',
                               'Mega Millions static base schedule is not a final multiplier ticket payout.'])
    check_continuity(previous, result)
    output.parent.mkdir(parents=True, exist_ok=True)
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(mode='w', encoding='utf-8', dir=output.parent,
                                         prefix='.'+output.name+'.', delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(json.dumps(result, indent=2, ensure_ascii=False)+'\n')
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, output)
    finally:
        if temporary is not None:
            temporary.unlink(missing_ok=True)
    return result


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    result = collect(args.output)
    print(f"Privately staged {len(result['results'])} results / {len(result['schedules'])} rule pages")
