"""Atomic NC catalog import; separate from mapped winner activity."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
from urllib.request import Request, urlopen
from north_carolina_scratch_catalog import SOURCE, parse_catalog


def fetch(url):
    with urlopen(Request(url,headers={'User-Agent':'LotteryAtlasOfficialDataBot/1.0'}),timeout=40) as response:
        return response.read()


def refresh(output, fetcher=fetch):
    output = Path(output)
    old = json.loads(output.read_text()) if output.exists() else None
    result = parse_catalog(fetcher(SOURCE))
    if len(result['games']) < 50: raise ValueError('Unexpectedly small NC catalog')
    if result['sourceDate'] > datetime.now(timezone.utc).date().isoformat():
        raise ValueError('Future source date')
    if old:
        if result['sourceDate'] < old['sourceDate']: raise ValueError('Source date regression')
        if len(result['games']) < len(old['games'])*0.9: raise ValueError('Catalog drop requires review')
        prior = {g['id']:g for g in old['games']}
        for game in result['games']:
            before = prior.get(game['id'])
            if before and any(before[k]!=game[k] for k in ['name','ticketPrice','sourceUrl']):
                raise ValueError('Game identity changed')
            if before and {t['prizeLabel'] for t in before['tiers']} != {t['prizeLabel'] for t in game['tiers']}:
                raise ValueError('Existing prize tier identities changed')
        if all(old.get(k)==v for k,v in result.items()): return old
    result['updatedAt'] = datetime.now(timezone.utc).isoformat()
    output.parent.mkdir(parents=True,exist_ok=True)
    temp = output.with_suffix(output.suffix+'.tmp')
    temp.write_text(json.dumps(result,indent=2)+'\n'); temp.replace(output)
    return result


if __name__ == '__main__':
    parser=argparse.ArgumentParser(); parser.add_argument('--output',required=True)
    args=parser.parse_args()
    print('Validated NC listed games:',len(refresh(args.output)['games']))
