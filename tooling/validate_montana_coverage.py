"""Validate Montana publication without replacing source retrieval dates."""
import argparse
from datetime import date
import json
import re
from pathlib import Path
from zoneinfo import ZoneInfo
from tooling import montana_coverage as coverage
from tooling import montana_catalog_contract as catalog

ROOT = Path(__file__).parent

def spec(name):
    return json.loads((ROOT / name).read_text())

def without_stamp(value):
    return {k: v for k, v in value.items() if k not in ('retrievedAt', 'sourceRetrievedAt')}

def validate(data):
    if type(data['schemaVersion']) is not int or data['schemaVersion'] != 1 or data['state'] != 'Montana':
        raise ValueError('Invalid Montana identity')
    if set(data) != {'schemaVersion','state','updatedAt','results','rules','sources','status','catalogs','raffle','endings','coverageNote','unavailable'}:
        raise ValueError('Unknown coverage fields')
    if data['coverageNote'] != 'Latest two published dates per reviewed draw group; all exact-date reports unavailable. Catalog schedules are not remaining inventory. Not complete history.' or data['unavailable'] != ['Exact-date Montana winner counts and payout reports', 'Remaining inventory and verified catalog sales status', 'Retired results, complete history, retailer joins and coordinates', 'Current raffle results, Can-Am separate catalog and sports results']:
        raise ValueError('Changed limitation disclosures')
    sources = data['sources']
    if [s['url'] for s in sources] != coverage.source_urls():
        raise ValueError('Wrong source inventory')
    previous = None
    for source in sources:
        if set(source) != {'url','retrievedAt','bytes','sha256'}:
            raise ValueError('Wrong source fields')
        stamp = coverage.instant(source['retrievedAt'])
        if previous is not None and stamp < previous:
            raise ValueError('Capture clock regressed')
        previous = stamp
        if type(source['bytes']) is not int or source['bytes'] <= 0 or not re.fullmatch('[0-9a-f]{64}', source['sha256']):
            raise ValueError('Invalid source provenance')
    if data['updatedAt'] != sources[-1]['retrievedAt']:
        raise ValueError('Wrong collection timestamp')
    by_url = {s['url']:s for s in sources}
    def joined(value, url, field='retrievedAt'):
        if value[field] != by_url[url]['retrievedAt']:
            raise ValueError('Unjoined source timestamp')
    if without_stamp(data['status']) != spec('montana_status_spec.json')['coverage']:
        raise ValueError('Changed coverage boundary')
    joined(data['status'], coverage.ROOT+'games/')
    rule_specs = spec('montana_rule_specs.json')
    if len(data['rules']) != len(coverage.FAMILIES):
        raise ValueError('Incomplete rules')
    for game, rule in zip(coverage.FAMILIES, data['rules']):
        expected = {'game':game, 'coverage':'Literal source rules and schedules, not dated payouts; source discrepancies retained.', **rule_specs[game]}
        if without_stamp(rule) != expected:
            raise ValueError('Changed rule contract')
        joined(rule, coverage.draws.source_url(game))
    for key, filename, url, field in [
        ('raffle','montana_raffle_spec.json',coverage.ROOT+'montana-millionaire/','retrievedAt'),
        ('endings','montana_ending_spec.json',coverage.ENDING_URL,'sourceRetrievedAt')]:
        if without_stamp(data[key]) != spec(filename):
            raise ValueError('Changed offer/ending contract')
        joined(data[key],url,field)
    if data['endings']['sha256'] != by_url[coverage.ENDING_URL]['sha256']:
        raise ValueError('Wrong reviewed PDF hash')
    if set(data['catalogs']) != set(coverage.CATALOGS):
        raise ValueError('Incomplete catalog kinds')
    catalog_specs = spec('montana_catalog_specs.json')
    for kind, (_, _, count) in coverage.CATALOGS.items():
        value = data['catalogs'][kind]
        if catalog.stable(without_stamp(value)) != catalog_specs[kind]:
            raise ValueError('Changed catalog contract')
        for entry in value['entries']:
            jackpot = entry['advertisedJackpot']
            amount = jackpot['amountText']
            if jackpot['status'] == 'published':
                if not isinstance(amount,str) or not re.fullmatch(r'\$(?:0|[1-9]\d{0,2}(?:,\d{3})*)',amount):
                    raise ValueError('Malformed advertised estimate')
            elif amount is not None:
                raise ValueError('Unavailable estimate has amount')
        joined(value, coverage.catalog_url(kind,count))
    if len(data['results']) != 14:
        raise ValueError('Incomplete results')
    groups = {g:[] for g in coverage.GAMES}
    for row in data['results']:
        if set(row) != {'game','drawDate','datePrecision','numbers','bonusNumbers','multiplier','sourceUrl','sourceRetrievedAt','reportStatus'} or row['game'] not in groups:
            raise ValueError('Wrong result schema')
        game = row['game']
        _, _, count, maximum, bmax, days = coverage.draws.SPECS[game]
        if row['sourceUrl'] != coverage.draws.source_url(game) or row['datePrecision'] != 'day' or row['reportStatus'] != 'unavailable':
            raise ValueError('Invalid result identity/status')
        joined(row, row['sourceUrl'], 'sourceRetrievedAt')
        day = date.fromisoformat(row['drawDate'])
        if row['drawDate'] != day.isoformat() or not coverage.draws.SUPPORTED_FROM <= day <= coverage.instant(row['sourceRetrievedAt']).astimezone(ZoneInfo('America/Denver')).date() or day.weekday() not in days:
            raise ValueError('Invalid date/cadence')
        for values, n, limit in [(row['numbers'],count,maximum),(row['bonusNumbers'],1 if bmax else 0,bmax)]:
            if len(values) != n or any(type(v) is not int or not 1 <= v <= limit for v in values) or len(set(values)) != n:
                raise ValueError('Invalid numbers')
        allowed = [2,3,4,5,10] if game == 'powerball' else [2,3,4,5] if game == 'lotto-america' else [None]
        if row['multiplier'] not in allowed or (row['multiplier'] is not None and type(row['multiplier']) is not int):
            raise ValueError('Invalid multiplier')
        groups[game].append(row)
    for rows in groups.values():
        if len(rows) != 2 or rows[0]['drawDate'] <= rows[1]['drawDate']:
            raise ValueError('Missing/duplicate/unordered draw dates')
    return data

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('path')
    args = parser.parse_args()
    validate(json.loads(Path(args.path).read_text()))
    print('Montana coupled snapshot valid')
