"""Coupled Montana source collection; all components succeed before replacement."""
from datetime import datetime, timedelta, timezone
import hashlib
import json
import os
from pathlib import Path
import tempfile
from tooling import import_montana_draws as draws
from tooling.montana_rules import parse_rules
from tooling.montana_catalog import combine_pages
from tooling.montana_catalog_contract import validate_catalog, continuity as catalog_continuity
from tooling.montana_status import parse_status
from tooling.montana_raffle import parse_raffle
from tooling.montana_endings import parse_endings, SPEC_PATH as ENDING_SPEC

GAMES = tuple(draws.SPECS)
FAMILIES = tuple(g for g in GAMES if g != 'powerball-double-play')
ROOT = 'https://montanalottery.com/'
CATALOGS = {'scratch': ('scratch-games', 'e-page-eeedf9c', 12),
            'treasure-play': ('treasure-play', 'e-page-ae879f3', 3)}
ENDING_URL = json.loads(ENDING_SPEC.read_text())['sourceUrl']

def catalog_url(kind, page):
    slug, query, count = CATALOGS[kind]
    if not 1 <= page <= count:
        raise ValueError('Unreviewed catalog page')
    return ROOT + slug + '/' + (('?' + query + '=' + str(page)) if page > 1 else '')

def source_urls():
    return ([ROOT + 'games/'] + [draws.source_url(g) for g in FAMILIES]
            + [catalog_url(k, n) for k, (_, _, count) in CATALOGS.items() for n in range(1, count + 1)]
            + [ROOT + 'montana-millionaire/', ENDING_URL])

def instant(value):
    stamp = datetime.fromisoformat(value.replace('Z', '+00:00'))
    if stamp.tzinfo is None or stamp.utcoffset() != timedelta(0):
        raise ValueError('Capture must be UTC')
    return stamp

def collect(fetch, clock=lambda: datetime.now(timezone.utc)):
    sources, results, rules = [], [], []
    def get(url):
        raw = fetch(url)
        stamp = clock().isoformat()
        parsed = instant(stamp)
        if not isinstance(raw, bytes) or not raw:
            raise ValueError('Empty or non-byte capture')
        if sources and parsed < instant(sources[-1]['retrievedAt']):
            raise ValueError('Capture clock regressed')
        sources.append(dict(url=url, retrievedAt=stamp, bytes=len(raw), sha256=hashlib.sha256(raw).hexdigest()))
        return raw, stamp
    raw, status_stamp = get(ROOT + 'games/')
    navigation = raw.decode('utf-8')
    pages = {}
    for game in FAMILIES:
        raw, stamp = get(draws.source_url(game))
        html = raw.decode('utf-8')
        pages[game] = html
        results.extend(draws.parse_draws(html, game, retrieved_at=stamp)[:2])
        if game == 'powerball':
            results.extend(draws.parse_draws(html, 'powerball-double-play', retrieved_at=stamp)[:2])
        rules.append({**parse_rules(html, game), 'retrievedAt': stamp})
    status = {**parse_status(navigation, pages['millionaire-for-life']), 'retrievedAt': status_stamp}
    catalogs = {}
    for kind, (_, _, count) in CATALOGS.items():
        catalog_pages = {}
        for n in range(1, count + 1):
            raw, stamp = get(catalog_url(kind, n))
            catalog_pages[n] = raw.decode('utf-8')
        catalogs[kind] = {**validate_catalog(combine_pages(catalog_pages, kind)), 'retrievedAt': stamp}
    raw, stamp = get(ROOT + 'montana-millionaire/')
    raffle = {**parse_raffle(raw.decode('utf-8')), 'retrievedAt': stamp}
    raw, stamp = get(ENDING_URL)
    endings = parse_endings(raw, retrieved_at=stamp)
    return dict(schemaVersion=1, state='Montana', updatedAt=stamp, results=results,
                rules=rules, sources=sources, status=status, catalogs=catalogs,
                raffle=raffle, endings=endings,
                coverageNote='Latest two published dates per reviewed draw group; all exact-date reports unavailable. Catalog schedules are not remaining inventory. Not complete history.',
                unavailable=['Exact-date Montana winner counts and payout reports',
                             'Remaining inventory and verified catalog sales status',
                             'Retired results, complete history, retailer joins and coordinates',
                             'Current raffle results, Can-Am separate catalog and sports results'])

def continuity(prior, candidate):
    if (prior['schemaVersion'], prior['state']) != (candidate['schemaVersion'], candidate['state']):
        raise ValueError('Coverage identity changed')
    if instant(candidate['updatedAt']) < instant(prior['updatedAt']):
        raise ValueError('Capture regressed')
    def stable(row):
        return {k: v for k, v in row.items() if k not in ('sourceRetrievedAt', 'retrievedAt')}
    if stable(prior['status']) != stable(candidate['status']):
        raise ValueError('Product boundary changed')
    for kind in ('scratch', 'treasure-play'):
        catalog_continuity(stable(prior['catalogs'][kind]), stable(candidate['catalogs'][kind]))
    for key in ('raffle', 'endings'):
        if stable(prior[key]) != stable(candidate[key]):
            raise ValueError('Offer/ending contract changed')
    if [stable(r) for r in prior['rules']] != [stable(r) for r in candidate['rules']]:
        raise ValueError('Rule contract changed')
    if any(prior[k] != candidate[k] for k in ('coverageNote', 'unavailable')):
        raise ValueError('Coverage boundary changed')
    def groups(data):
        grouped = {g: [] for g in GAMES}
        for row in data['results']:
            if row['game'] not in grouped:
                raise ValueError('Unknown result group')
            grouped[row['game']].append(row)
        for rows in grouped.values():
            if len(rows) != 2 or rows[0]['drawDate'] <= rows[1]['drawDate']:
                raise ValueError('Missing, duplicate or unordered result dates')
        return grouped
    before, after = groups(prior), groups(candidate)
    for game in GAMES:
        old, new = before[game], after[game]
        if any(n['drawDate'] < o['drawDate'] for o, n in zip(old, new)):
            raise ValueError('Result window regressed')
        indexed = {r['drawDate']: r for r in new}
        for row in old:
            day = row['drawDate']
            if day in indexed:
                if stable(row) != stable(indexed[day]):
                    raise ValueError('Existing result corrected')
            elif day >= min(indexed):
                raise ValueError('Result lost inside retained window')
    return candidate


def refresh(path, fetch, clock=lambda: datetime.now(timezone.utc)):
    path = Path(path)
    prior = json.loads(path.read_text()) if path.exists() else None
    candidate = collect(fetch, clock)
    if prior is not None:
        continuity(prior, candidate)
    encoded = (json.dumps(candidate, ensure_ascii=False, indent=2) + '\n').encode()
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, prefix=path.name+'.', delete=False) as handle:
            temporary = handle.name
            handle.write(encoded)
            handle.flush()
            os.fsync(handle.fileno())
        os.replace(temporary, path)
    finally:
        if temporary and os.path.exists(temporary):
            os.unlink(temporary)
    return candidate
