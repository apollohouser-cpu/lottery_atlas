"""Collect Oklahoma all-game coverage atomically; failed refresh retains bytes."""
from datetime import datetime, timezone
import json
import os
from pathlib import Path
import tempfile
from zoneinfo import ZoneInfo
import import_oklahoma_draws as draws
import import_oklahoma_fast_play as fast
import import_oklahoma_scratch_catalog as scratch
from oklahoma_draw_rules import parse_rules


def collect(fetch, clock=lambda: datetime.now(timezone.utc)):
    requests = []
    def get(url):
        raw = fetch(url)
        stamp = clock()
        if stamp.tzinfo is None:
            raise ValueError('Missing capture timezone')
        requests.append(dict(url=url, retrievedAt=stamp.isoformat()))
        return raw, stamp
    results, rules, excluded = [], [], 0
    for slug in draws.CONTRACTS:
        raw, stamp = get(draws.SOURCE+slug)
        parsed = draws.parse_results(raw, slug, stamp)
        results.extend(parsed['results']); excluded += parsed['excludedScheduled']
        rules.append(parse_rules(raw, slug))
    products = {}
    for kind, module, minimum in [('scratch', scratch, 50), ('fastPlay', fast, 19)]:
        raw, stamp = get(module.SOURCE)
        games, total = module.parse_listing(raw, stamp.astimezone(ZoneInfo('America/Chicago')).date())
        if len(games) < minimum:
            raise ValueError('Catalog shrank below reviewed baseline')
        verified = []
        for game in games:
            raw, captured = get(module.SOURCE+'/'+game['slug'])
            detail = module.parse_detail(raw, game)
            detail['retrievedAt'] = captured.isoformat()
            verified.append(detail)
        if len({g['id'] for g in verified}) != len(verified):
            raise ValueError('Duplicate printed product identity')
        if kind == 'scratch':
            scratch.validate_inventory_coverage(verified)
        products[kind] = dict(listedGameCount=total, games=verified,
                              listingRetrievedAt=stamp.isoformat(), sourceUrl=module.SOURCE)
    return dict(schemaVersion=1, state='Oklahoma', updatedAt=requests[-1]['retrievedAt'],
                results=results, rules=rules, excludedScheduled=excluded,
                products=products, sources=requests,
                coverageNote='Bounded completed results; all winner reports unavailable. Pick3 sessions '
                'unavailable. Current eligible inventory subsets only; no complete history, claims, '
                'retailer joins, store stock or progressive inference.')


def without(value, *keys):
    return {k: v for k, v in value.items() if k not in keys}


def continuity(old, new):
    if old['schemaVersion'] != new['schemaVersion'] or old['state'] != new['state']:
        raise ValueError('Changed feed identity')
    if datetime.fromisoformat(new['updatedAt']) < datetime.fromisoformat(old['updatedAt']):
        raise ValueError('Collection time regression')
    if old['rules'] != new['rules']:
        raise ValueError('Rule change requires review')
    def group(rows):
        out = {}
        for r in rows:
            out.setdefault((r['game'], r['variant']), {})[r['date']] = r
        return out
    before, after = group(old['results']), group(new['results'])
    if before.keys() != after.keys():
        raise ValueError('Result group loss')
    for key, prior in before.items():
        current = after[key]
        if max(current) < max(prior):
            raise ValueError('Result window regression')
        # A retained newest date must still appear unless the new window has
        # advanced completely past it. A hole inside the window is not rollover.
        for day, row in prior.items():
            if day >= min(current) and day not in current:
                raise ValueError('Result disappeared inside window')
            if day in current and without(row, 'retrievedAt') != without(current[day], 'retrievedAt'):
                raise ValueError('Result correction requires review')
    for kind, catalog in old['products'].items():
        current = {g['id']: g for g in new['products'][kind]['games']}
        for prior in catalog['games']:
            if prior['id'] not in current:
                raise ValueError('Product identity disappeared')
            item = current[prior['id']]
            dynamic = ('retrievedAt','prizeTiers','topPrizesRemaining','inventoryNote','inventoryStatus','progressiveEstimate')
            if without(prior, *dynamic) != without(item, *dynamic):
                raise ValueError('Product metadata changed')
            # Explicit unknown remains unknown, never zero or stale copied data.
            if not prior['prizeTiers'] or not item['prizeTiers']:
                continue
            def tier_key(t):
                return t.get('prizeLabel', t['prizeAmount'])
            old_tiers = {tier_key(t): t for t in prior['prizeTiers']}
            new_tiers = {tier_key(t): t for t in item['prizeTiers']}
            if old_tiers.keys() != new_tiers.keys():
                raise ValueError('Prize structure changed')
            for key, tier in old_tiers.items():
                now = new_tiers[key]
                if without(tier, 'remainingPrizes') != without(now, 'remainingPrizes') or now['remainingPrizes'] > tier['remainingPrizes']:
                    raise ValueError('Inventory correction requires review')


def refresh(path, fetch, clock=lambda: datetime.now(timezone.utc)):
    path = Path(path)
    prior = json.loads(path.read_text()) if path.exists() else None
    result = collect(fetch, clock)
    if prior is not None:
        continuity(prior, result)
    encoded = (json.dumps(result, indent=2, ensure_ascii=False)+'\n').encode()
    temporary = None
    try:
        with tempfile.NamedTemporaryFile(dir=path.parent, prefix=path.name+'.', suffix='.tmp', delete=False) as stream:
            temporary = Path(stream.name)
            stream.write(encoded); stream.flush(); os.fsync(stream.fileno())
        os.replace(temporary, path)
    finally:
        if temporary is not None and temporary.exists():
            temporary.unlink()
    return result
