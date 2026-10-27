"""Coupled Wyoming collection; caller supplies official HTTP transport.

No credential, customer identifier, jackpot estimate or unverified winner count
is included in the output. Public publication remains a separate release gate.
"""
from datetime import datetime, timedelta, timezone
import hashlib
import json
from urllib.parse import quote, urlencode
from tooling import import_wyoming_draws as draws
from tooling.wyoming_draw_rules import SPEC_PATH, parse_rules

API = 'https://prod.game-data.gambytservices.com'
SITE = 'https://wyolotto.com'
GAMES = tuple(draws.SPECS) + ('keno',)


def validate_catalog(catalog, draw_config, rapid_config):
    games = catalog.get('data', {}).get('games') if isinstance(catalog, dict) else None
    expected = {(g, 'rapid' if g == 'keno' else 'draw', False) for g in GAMES}
    if (catalog.get('status') != 'success' or not isinstance(games, list)
            or len(games) != len(expected)
            or {(r.get('identifier'), r.get('type'), r.get('isRetired')) for r in games} != expected):
        raise ValueError('Current Wyoming catalog changed')
    if (not isinstance(draw_config, list) or len(draw_config) != 5
            or {r.get('id') for r in draw_config} != {s[0] for s in draws.SPECS.values()}
            or any(r.get('activeTo') is not None for r in draw_config)):
        raise ValueError('Active draw identities changed')
    if not isinstance(rapid_config, list) or len(rapid_config) != 1:
        raise ValueError('Rapid game catalog changed')
    r = rapid_config[0]
    contract = dict(id=draws.KENO_ID, activeTo=None, minDrawValue=1, maxDrawValue=80,
                    drawFrequencyInSeconds=240, drawFrequencyInMinutes=4,
                    hasProgressiveJackpots=False)
    if any(k not in r or type(r[k]) is not type(v) or r[k] != v for k,v in contract.items()):
        raise ValueError('Keno configuration changed')


def collect(fetch, clock=lambda: datetime.now(timezone.utc)):
    sources = []
    end = clock()
    if end.tzinfo is None or end.utcoffset() != timedelta(0):
        raise ValueError('Collection clock must be UTC')
    # Service echoes millisecond precision; issue whole-second query boundaries.
    # Actual retrieval timestamps below retain the clock's full precision.
    end = end.replace(microsecond=0)
    start = max(end - timedelta(days=14), draws.SUPPORTED_FROM)
    if start >= end:
        raise ValueError('Unsupported collection window')
    def get(url):
        raw = fetch(url)
        stamp = clock()
        if (not isinstance(raw, bytes) or not raw or stamp.tzinfo is None
                or stamp.utcoffset() != timedelta(0) or stamp < end
                or (sources and stamp < draws.instant(sources[-1]['retrievedAt']))):
            raise ValueError('Invalid capture or capture clock regression')
        sources.append(dict(url=url, retrievedAt=stamp.isoformat(), bytes=len(raw),
                            sha256=hashlib.sha256(raw).hexdigest()))
        return raw, stamp.isoformat()
    catalog, _ = get(f'{SITE}/api/v1/game/all?platform=web&cmsPreview=false')
    draw_config, _ = get(f'{API}/v1/draw-games')
    rapid_config, _ = get(f'{API}/v1/rapid-games')
    validate_catalog(json.loads(catalog), json.loads(draw_config), json.loads(rapid_config))
    results = []
    query = urlencode(dict(startDate=start.isoformat(), endDate=end.isoformat()))
    for game, spec in draws.SPECS.items():
        url = f'{API}/v1/draw-games/{spec[0]}/list-drawings?{query}'
        raw, stamp = get(url)
        rows = draws.parse_draws(json.loads(raw), game, start=start.isoformat(),
                                 end=end.isoformat(), retrieved_at=stamp)
        if len(rows) < 2:
            raise ValueError('Missing two completed draw dates')
        results.extend(rows[:2])
    # Bounded recent Keno lookup; never assert that the returned IDs are gap-free.
    kstart = max(end - timedelta(days=1), draws.SUPPORTED_FROM)
    url = (f'{API}/v1/rapid-games/{draws.KENO_ID}/draw-numbers-by-date/'
           f'{quote(kstart.isoformat(), safe="")}/{quote(end.isoformat(), safe="")}')
    raw, _ = get(url)
    bounds = json.loads(raw)
    if (not isinstance(bounds, dict) or set(bounds) != {'start', 'end', 'min', 'max'}
            or draws.instant(bounds['start']) != kstart or draws.instant(bounds['end']) != end
            or type(bounds['min']) is not int or type(bounds['max']) is not int
            or bounds['min'] <= 0 or bounds['max'] - bounds['min'] < 4):
        raise ValueError('Invalid Keno range identity or bounds')
    first, last = bounds['max'] - 4, bounds['max']
    raw, stamp = get(f'{API}/v1/rapid-games/{draws.KENO_ID}/drawings/{first}/{last}')
    keno = draws.parse_keno(json.loads(raw), first_id=first, last_id=last,
                           start=kstart.isoformat(), end=end.isoformat(), retrieved_at=stamp)
    if len(keno) != 5:
        raise ValueError('Incomplete requested Keno window')
    results.extend(keno)
    specs = json.loads(SPEC_PATH.read_text())
    rules = []
    for game in GAMES:
        raw, stamp = get(f'{SITE}/api/v1/game/rules?identifier={game}&platform=web&cmsPreview=false')
        image, image_stamp = None, None
        if 'image' in specs[game]:
            image, image_stamp = get(specs[game]['image']['url'])
        rule = parse_rules(raw, game, image_bytes=image)
        rule.update(retrievedAt=stamp, imageRetrievedAt=image_stamp)
        rules.append(rule)
    return dict(schemaVersion=1, state='Wyoming', updatedAt=sources[-1]['retrievedAt'],
                queryWindow=dict(start=start.isoformat(), end=end.isoformat()),
                kenoWindow=dict(start=kstart.isoformat(), end=end.isoformat(), firstId=first, lastId=last),
                results=results, rules=rules, sources=sources,
                coverageNote='Latest two completed dates per draw family and five bounded Keno IDs. All winner reports unavailable; no inferred zero counts or complete history.',
                unavailable=['Exact Wyoming winner counts and dated payout reports',
                             'Earlier formats, retired games and complete history',
                             'Retailer joins, coordinates and complete claims',
                             'Wyoming Double Play and Scratch products'])


def continuity(prior, candidate):
    """Fail closed on corrections, losses and regressions before disk mutation."""
    if (prior['schemaVersion'], prior['state']) != (candidate['schemaVersion'], candidate['state']):
        raise ValueError('Coverage identity changed')
    if draws.instant(candidate['updatedAt']) < draws.instant(prior['updatedAt']):
        raise ValueError('Capture regressed')
    for window in ('queryWindow', 'kenoWindow'):
        for key in ('start', 'end'):
            if draws.instant(candidate[window][key]) < draws.instant(prior[window][key]):
                raise ValueError('Query window regressed')
    def stable(row):
        return {k:v for k,v in row.items() if k not in ('sourceRetrievedAt','retrievedAt','imageRetrievedAt')}
    if [stable(r) for r in candidate['rules']] != [stable(r) for r in prior['rules']]:
        raise ValueError('Rule contract changed')
    def groups(data):
        grouped = {g: [] for g in GAMES}
        for r in data['results']:
            grouped[r['game']].append(r)
        for g, rows in grouped.items():
            if len(rows) != (5 if g == 'keno' else 2) or len({r['drawId'] for r in rows}) != len(rows):
                raise ValueError('Incomplete or duplicate result group')
        return grouped
    before, after = groups(prior), groups(candidate)
    for game in GAMES:
        old, new = before[game], after[game]
        for key in ('drawId','drawTimeUtc'):
            if min(r[key] for r in new) < min(r[key] for r in old) or max(r[key] for r in new) < max(r[key] for r in old):
                raise ValueError('Result window regressed')
        indexed = {r['drawId']:r for r in new}
        for r in old:
            if r['drawId'] in indexed:
                if stable(r) != stable(indexed[r['drawId']]):
                    raise ValueError('Existing result corrected')
            elif r['drawId'] >= min(indexed):
                raise ValueError('Result lost inside retained window')
    return candidate


def refresh(path, fetch, clock=lambda: datetime.now(timezone.utc)):
    import os
    from pathlib import Path
    import tempfile
    path = Path(path)
    prior = json.loads(path.read_text()) if path.exists() else None
    candidate = collect(fetch, clock)
    if prior is not None:
        continuity(prior, candidate)
    encoded = (json.dumps(candidate, ensure_ascii=False, indent=2)+'\n').encode()
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, prefix=path.name+'.', delete=False) as handle:
            temporary = handle.name
            handle.write(encoded); handle.flush(); os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        if temporary and os.path.exists(temporary):
            os.unlink(temporary)
    return candidate
