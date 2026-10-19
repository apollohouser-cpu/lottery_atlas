"""Couple Iowa draws and typed instant inventories in one atomic snapshot."""
from datetime import datetime, timezone
import hashlib
import json
import os
from pathlib import Path
import tempfile
from zoneinfo import ZoneInfo

from tooling.collect_iowa_draws import collect as collect_draws, fetch_page
from tooling.iowa_instant_inventories import parse_inventories, TYPES
from tooling.import_iowa_scratch_catalog import build_catalog, SOURCE


def check_inventory_continuity(previous, current):
    if previous is None:
        return
    if current['sourceDate'] < previous['sourceDate']:
        raise ValueError('Inventory source date regression')
    if current['sourceDate'] == previous['sourceDate'] and current != previous:
        raise ValueError('Same-date inventory correction requires review')
    for kind in TYPES:
        old = next(s for s in previous['inventories'] if s['productType'] == kind)
        new = next(s for s in current['inventories'] if s['productType'] == kind)
        indexed = {g['id']: g for g in new['games']}
        for game in old['games']:
            retained = indexed.get(game['id'])
            if retained is None or (retained['name'], retained['cost']) != (game['name'], game['cost']):
                raise ValueError('Inventory identity loss/change requires review')
            tiers = {t['prizeAmount']: t for t in retained['prizeTiers']}
            for tier in game['prizeTiers']:
                following = tiers.get(tier['prizeAmount'])
                if following is None or following['claimed'] < tier['claimed'] or following['unclaimed'] > tier['unclaimed']:
                    raise ValueError('Cumulative inventory correction requires review')


def collect(output, *, fetch=fetch_page, now=None):
    now = now or datetime.now(timezone.utc)
    if now.utcoffset() is None:
        raise ValueError('Aware retrieval timestamp required')
    output = Path(output)
    previous = json.loads(output.read_text()) if output.exists() else None
    if previous is not None and (previous.get('schemaVersion') != 1 or previous.get('state') != 'Iowa'):
        raise ValueError('Unrecognized retained coverage')
    cache = {}

    def source(url):
        if url not in cache:
            cache[url] = fetch(url)
        return cache[url]

    output.parent.mkdir(parents=True, exist_ok=True)
    with tempfile.TemporaryDirectory(dir=output.parent, prefix='.iowa-stage-') as directory:
        staged = Path(directory) / 'draws.json'
        if previous:
            staged.write_text(json.dumps(previous['draws']))
        draws = collect_draws(staged, fetch=source, now=now)
        inventory = parse_inventories(source(SOURCE), as_of=now.astimezone(ZoneInfo('America/Chicago')).date())
        scratch = build_catalog(source)
        if scratch['sourceDate'] != inventory['sourceDate']:
            raise ValueError('Scratch/report source dates differ')
        typed_scratch = next(s for s in inventory['inventories'] if s['productType'] == 'Scratch')
        projected = [{key: game[key] for key in ('id', 'name', 'cost', 'prizeTiers')} for game in typed_scratch['games']]
        verified = [{key: game[key] for key in ('id', 'name', 'cost', 'prizeTiers')} for game in scratch['games']]
        if projected != verified:
            raise ValueError('Scratch detail inventory differs from typed source')
        check_inventory_continuity(previous['instantInventories'] if previous else None, inventory)
        if previous and previous['scratchCatalog']['sourceDate'] == scratch['sourceDate'] and previous['scratchCatalog'] != scratch:
            raise ValueError('Same-date Scratch detail correction requires review')
        result = dict(schemaVersion=1, state='Iowa', retrievedAt=now.isoformat(), draws=draws,
                      instantInventories=inventory, scratchCatalog=scratch,
                      sources=[dict(url=url, sha256=hashlib.sha256(raw).hexdigest()) for url, raw in cache.items()])
        temporary = Path(directory) / 'coverage.json'
        with temporary.open('w', encoding='utf-8') as stream:
            stream.write(json.dumps(result, indent=2, ensure_ascii=False) + '\n')
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(temporary, output)
    return result


if __name__ == '__main__':
    import argparse
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    result = collect(args.output)
    print(f"Validated coupled Iowa coverage: {len(result['draws']['results'])} results, "
          f"{sum(len(s['games']) for s in result['instantInventories']['inventories'])} typed games")
