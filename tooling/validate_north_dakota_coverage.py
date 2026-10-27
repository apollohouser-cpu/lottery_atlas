"""Validate the coupled ND public snapshot without refreshing its source dates."""
import argparse
from datetime import date
import json
import re
from zoneinfo import ZoneInfo
from tooling.north_dakota_coverage import GAMES, instant, CATALOG_URL
from tooling import import_north_dakota_draws as draws
from tooling.north_dakota_rules import SPEC_PATH


def validate(data):
    if data['schemaVersion'] != 1 or data['state'] != 'North Dakota':
        raise ValueError('Wrong coverage identity')
    specs = json.loads(SPEC_PATH.read_text())
    urls = [CATALOG_URL]
    for g in GAMES: urls.extend([draws.source_url(g), specs[g]['sourceUrl']])
    sources = data['sources']
    if len(sources) != 11 or [s['url'] for s in sources] != urls:
        raise ValueError('Wrong source inventory')
    previous = None
    for s in sources:
        stamp = instant(s['retrievedAt'])
        if previous and stamp < previous: raise ValueError('Capture order regressed')
        previous = stamp
        if type(s['bytes']) is not int or s['bytes'] <= 0 or not re.fullmatch('[0-9a-f]{64}',s['sha256']):
            raise ValueError('Invalid source provenance')
    if data['updatedAt'] != sources[-1]['retrievedAt']:
        raise ValueError('Wrong collection timestamp')
    catalog = data['catalog']
    if (catalog['currentGames'] != list(GAMES) or catalog['sourceUrl'] != CATALOG_URL
            or catalog['retrievedAt'] != sources[0]['retrievedAt']
            or catalog['retired'] != [{'game':'lucky-for-life','finalDrawDate':'2026-02-21'}]):
        raise ValueError('Wrong catalog/status')
    if len(data['rules']) != 5 or len(data['results']) != 10:
        raise ValueError('Incomplete rule/result groups')
    for i, game in enumerate(GAMES):
        rule = data['rules'][i]
        if (rule['game'] != game or rule['document'] != specs[game]['document']
                or rule['sourceUrl'] != specs[game]['sourceUrl']
                or rule['retrievedAt'] != sources[2*i+2]['retrievedAt']):
            raise ValueError('Changed or unjoined rule')
        _, _, _, count, maximum, bcount, bmax, days = draws.SPECS[game]
        rows = data['results'][2*i:2*i+2]
        for r in rows:
            if (r['game'] != game or r['reportStatus'] != 'unavailable' or r['datePrecision'] != 'day'
                    or r['sourceUrl'] != draws.source_url(game)
                    or r['sourceRetrievedAt'] != sources[2*i+1]['retrievedAt']
                    or set(r) != {'game','drawDate','datePrecision','numbers','bonusNumbers','numberLabels','multiplier','sourceUrl','sourceRetrievedAt','reportStatus'}):
                raise ValueError('Invalid result identity/provenance/schema')
            day = date.fromisoformat(r['drawDate'])
            captured = instant(r['sourceRetrievedAt']).astimezone(ZoneInfo('America/Chicago')).date()
            if not draws.SUPPORTED_FROM <= day <= captured or day.weekday() not in days:
                raise ValueError('Invalid drawing date')
            for values,n,limit in [(r['numbers'],count,maximum),(r['bonusNumbers'],bcount,bmax)]:
                if len(values)!=n or any(type(v) is not int or not 1<=v<=limit for v in values) or len(set(values))!=n:
                    raise ValueError('Invalid numbers')
            allowed = [2,3,4,5,10] if game=='powerball' else [2,3,4,5] if game=='lotto-america' else [None]
            if r['multiplier'] not in allowed or (r['multiplier'] is not None and type(r['multiplier']) is not int):
                raise ValueError('Invalid multiplier')
            if r['numberLabels'] != (['Red','White'] if game=='2by2' else ['Main','Bonus']):
                raise ValueError('Invalid number labels')
        if rows[0]['drawDate'] <= rows[1]['drawDate']:
            raise ValueError('Duplicate or unordered dates')
    return data


if __name__ == '__main__':
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('path')
    args = parser.parse_args()
    validate(json.load(open(args.path)))
    print('North Dakota coupled snapshot valid')
