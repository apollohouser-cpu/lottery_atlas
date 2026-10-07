"""Atomic Missouri literal inventory snapshot; not a generic cash-prize feed."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import json
from pathlib import Path
from urllib.parse import urljoin, urlparse, parse_qs
from lxml import html
from missouri_scratch_catalog import parse_listing, validate_detail
from import_missouri_draw_reports import fetch

SOURCE = 'https://www.molottery.com/scratchers-list.do'


def build_catalog(fetcher=fetch):
    raw = fetcher(SOURCE)
    if b'</html>' not in raw.lower():
        raise ValueError('Incomplete catalog page')
    listing = parse_listing(raw)
    # A drop below this observed-scale guard demands review, not a completeness claim.
    if len(listing) < 50:
        raise ValueError('Unexpectedly small Missouri catalog')
    routes = {}
    for href in html.fromstring(raw).xpath('//a/@href'):
        u = urlparse(urljoin(SOURCE,href))
        if u.path != '/scratchers.do':continue
        q = parse_qs(u.query)
        if q.get('method') != ['d']:continue
        if u.scheme != 'https' or u.netloc != 'www.molottery.com' or set(q) != {'method','game'} or len(q['game']) != 1:
            raise ValueError('Changed catalog detail route')
        routes[q['game'][0]] = u.geturl()
    def load(game):
        if game['id'] not in routes:raise ValueError('Missing listed detail link')
        detail = fetcher(routes[game['id']])
        if b'</html>' not in detail.lower():raise ValueError('Incomplete detail document')
        return dict(validate_detail(detail,game),sourceUrl=routes[game['id']])
    with ThreadPoolExecutor(max_workers=2) as pool:
        games = list(pool.map(load,listing))
    return dict(stateCode='MO',sourceUrl=SOURCE,sourceDate=None,
                updateCadence='Official pages state daily updates; no distinct source verification date supplied.',
                coverage='Listed Missouri Scratchers estimated unclaimed inventory; includes listed ended games. Advertised prizes remain literal, not verified cash options. No claims, retailer stock or statewide completeness assertion.',
                games=sorted(games,key=lambda g:int(g['id'])))


def refresh(output,fetcher=fetch):
    output=Path(output)
    old=json.loads(output.read_text()) if output.exists() else None
    result=build_catalog(fetcher)
    if old:
        if len(result['games']) < len(old['games'])*0.9:
            raise ValueError('Catalog count drop requires review')
        prior={g['id']:g for g in old['games']}
        for game in result['games']:
            previous=prior.get(game['id'])
            if previous and any(game[k]!=previous[k] for k in ['name','ticketPrice','startDate']):
                raise ValueError('Existing game identity changed')
        if all(old.get(k)==v for k,v in result.items()):return old
    result['updatedAt']=datetime.now(timezone.utc).isoformat()
    output.parent.mkdir(parents=True,exist_ok=True)
    temp=output.with_suffix(output.suffix+'.tmp')
    temp.write_text(json.dumps(result,indent=2)+'\n');temp.replace(output)
    return result


if __name__=='__main__':
    p=argparse.ArgumentParser();p.add_argument('--output',required=True);a=p.parse_args()
    print('Validated Missouri catalog:',len(refresh(a.output)['games']))
