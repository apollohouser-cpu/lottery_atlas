"""Coupled ND result/rule collection with atomic, fail-closed retention.

This module does not establish complete history or winner counts. Publication
and app integration are separate gates.
"""
from datetime import datetime, timedelta, timezone
import hashlib
import json
import os
from pathlib import Path
import tempfile
from tooling import import_north_dakota_draws as draws
from tooling.north_dakota_rules import SPEC_PATH, parse_rules
from tooling.north_dakota_catalog import URL as CATALOG_URL, parse_catalog

GAMES = tuple(draws.SPECS)


def instant(value):
    stamp = datetime.fromisoformat(value.replace('Z', '+00:00'))
    if stamp.tzinfo is None or stamp.utcoffset() != timedelta(0):
        raise ValueError('Capture must be UTC')
    return stamp


def collect(fetch, clock=lambda: datetime.now(timezone.utc)):
    sources, results, rules = [], [], []
    specs = json.loads(SPEC_PATH.read_text())
    def get(url):
        raw = fetch(url)
        stamp = clock().isoformat()
        parsed = instant(stamp)
        if not isinstance(raw, bytes) or not raw:
            raise ValueError('Empty or non-byte capture')
        if sources and parsed < instant(sources[-1]['retrievedAt']):
            raise ValueError('Capture clock regressed')
        text = raw.decode('utf-8')
        sources.append(dict(url=url, retrievedAt=stamp, bytes=len(raw),
                            sha256=hashlib.sha256(raw).hexdigest()))
        return text, stamp
    html, stamp = get(CATALOG_URL)
    catalog = parse_catalog(html)
    catalog['retrievedAt'] = stamp
    for game in GAMES:
        html, stamp = get(draws.source_url(game))
        results.extend(draws.parse_draws(html, game, retrieved_at=stamp)[:2])
        html, stamp = get(specs[game]['sourceUrl'])
        rule = parse_rules(html, game)
        rule['retrievedAt'] = stamp
        rules.append(rule)
    return dict(schemaVersion=1, state='North Dakota', updatedAt=sources[-1]['retrievedAt'],
                results=results, rules=rules, sources=sources, catalog=catalog,
                coverageNote='Latest two published dates per current family. Date-only results; all exact-date winner reports unavailable. Not complete history.',
                unavailable=['Exact-date North Dakota winner counts and payout reports',
                             'Retired games, older formats and complete history',
                             'Retailer joins, coordinates and complete claims',
                             'Scratch products and North Dakota Double Play'])


def continuity(prior, candidate):
    if (prior['schemaVersion'], prior['state']) != (candidate['schemaVersion'], candidate['state']):
        raise ValueError('Coverage identity changed')
    if instant(candidate['updatedAt']) < instant(prior['updatedAt']):
        raise ValueError('Capture regressed')
    def stable(row):
        return {k: v for k, v in row.items() if k not in ('sourceRetrievedAt', 'retrievedAt')}
    if stable(prior['catalog']) != stable(candidate['catalog']):
        raise ValueError('Catalog boundary changed')
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
