"""Atomic, explicitly city-bounded Missouri public address directory.

No private workbook rows, inferred coordinates, or statewide completeness claim.
"""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
from urllib.parse import urlencode
import subprocess
from missouri_public_locator import parse_results

SOURCE = 'https://www.molottery.com/where-to-play/where-to-play.do'


def fetch_city(city):
    form = urlencode([('city', city), ('zipcode', ''), ('range', '0'),
                      ('games', 'online'), ('games', 'keno'),
                      ('games', 'scratchers'), ('parameter', 'Search')])
    return subprocess.check_output(['curl', '-fsSL', '--max-time', '40',
        '-H', 'Accept-Language: en-US,en;q=0.9', '--data', form, SOURCE])


def refresh(output, city, fetcher=fetch_city):
    city = ' '.join(city.split())
    if not city or len(city) > 128 or any(ord(c) < 32 for c in city):
        raise ValueError('Invalid city query')
    output = Path(output)
    old = json.loads(output.read_text()) if output.exists() else None
    rows = parse_results(fetcher(city))
    if any(' '.join(r['city'].split()).casefold() != city.casefold() for r in rows):
        raise ValueError('Local response city differs from requested city')
    # Bound unexpected server responses, not an assertion about statewide size.
    if len(rows) > 10000:
        raise ValueError('Unexpectedly large local response')
    result = dict(stateCode='MO', sourceUrl=SOURCE, sourceDate=None,
        query=dict(city=city, radiusMiles=0, productGroups=['online','keno','scratchers']),
        coverage='Official local-only city query results, not a statewide directory or completeness claim. Addresses and product labels are source supplied. Coordinates and retailer IDs unavailable; includes agency, mobile or subscription entries. No store stock or retailer-winning claim.',
        retailers=rows)
    if old:
        if old.get('query') != result['query']:
            raise ValueError('Cannot replace a different query baseline')
        if len(rows) < len(old['retailers']) * .9:
            raise ValueError('Local result drop requires review')
        if all(old.get(k) == v for k,v in result.items()):
            return old
    result['updatedAt'] = datetime.now(timezone.utc).isoformat()
    output.parent.mkdir(parents=True, exist_ok=True)
    temp = output.with_suffix(output.suffix + '.tmp')
    temp.write_text(json.dumps(result, indent=2)+'\n')
    temp.replace(output)
    return result


if __name__ == '__main__':
    parser = argparse.ArgumentParser()
    parser.add_argument('--city', required=True)
    parser.add_argument('--output', required=True)
    args = parser.parse_args()
    print('Validated local query rows:', len(refresh(args.output,args.city)['retailers']))
