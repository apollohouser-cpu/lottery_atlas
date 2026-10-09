"""Bounded, atomic NC report refresh. Never joins reported wins to retailers."""
import argparse
from collections import Counter
from datetime import datetime, timezone
import json
from pathlib import Path
import re
from urllib.parse import urljoin
from lxml import html
from import_north_carolina_scratch_catalog import fetch
from north_carolina_draw_reports import (
    parse_cash_pop, parse_pick_reports, parse_cash5_reports,
    parse_millionaire_reports, parse_xo_reports, parse_powerball_reports,
    parse_mega_reports, CASH_POP_URL, CASH_POP_SESSIONS,
)

HISTORIES = [
    ('powerball-past-draws', 'powerball', parse_powerball_reports),
    ('mega-millions-past-draws', 'mega-millions', parse_mega_reports),
    ('cash5-past-draws', 'cash5', parse_cash5_reports),
    ('Millionaire-For-Life-past-draws', 'millionaire-for-life', parse_millionaire_reports),
    ('Powerball-Xs-and-Os-past-draws', 'Powerball-Xs-and-Os', parse_xo_reports),
]
GROUPS = {(g,s) for g,s in [('Powerball','Drawing'),('Mega Millions','Drawing'),
    ('Cash 5','Daily'),('Millionaire for Life','Daily'),('Powerball Xs and Os','Weekly')]}
GROUPS |= {(g,s) for g in ['Pick 3','Pick 4'] for s in ['Daytime','Evening']}
GROUPS |= {('Cash Pop',s) for s in CASH_POP_SESSIONS}


def detail_urls(raw, route, pick=False):
    if b'</html>' not in raw.lower(): raise ValueError('Incomplete NC history')
    roots=html.fromstring(raw).xpath('//main')
    if len(roots)!=1: raise ValueError('Missing/duplicate NC history main')
    found=[]
    for link in roots[0].xpath('.//a/@href'):
        # The official dated links contain formatting spaces inside the date.
        normalized=re.sub(r'\s+', '', link)
        if not normalized.startswith('/'+route+'?'): continue
        pattern=r'/'+re.escape(route)+(r'\?dn=[1-9]\d*' if pick else r'\?dd=\d{2}/\d{2}/\d{4}')
        if not re.fullmatch(pattern,normalized): raise ValueError('Changed NC detail URL')
        url=urljoin('https://nclottery.com',normalized)
        if url not in found: found.append(url)
    if len(found)<(4 if pick else 2): raise ValueError('Insufficient NC history links')
    if pick:
        # Fetch a bounded window large enough for two of each session.
        return found[:8]
    dated=sorted(found,key=lambda u:datetime.strptime(u.split('=')[1],'%m/%d/%Y'),reverse=True)
    return dated[:2]


def validate_collection(reports, previous=None):
    if len(reports)!=28 or Counter((r['game'],r['session']) for r in reports)!=Counter({g:2 for g in GROUPS}):
        raise ValueError('NC collection must cover all 14 groups twice')
    if len({r['id'] for r in reports})!=28: raise ValueError('Duplicate NC report identity')
    if previous:
        old=previous['reports']
        for group in GROUPS:
            before=sorted(r['drawDate'] for r in old if (r['game'],r['session'])==group)
            after=sorted(r['drawDate'] for r in reports if (r['game'],r['session'])==group)
            if len(before)!=2 or any(a<b for a,b in zip(after,before)):
                raise ValueError('NC report window regression')


def refresh(output, fetcher=fetch, now=None):
    now=now or datetime.now(timezone.utc)
    output=Path(output)
    previous=json.loads(output.read_text()) if output.exists() else None
    reports=parse_cash_pop(fetcher(CASH_POP_URL),today=now.date())
    for history,route,parser in HISTORIES:
        urls=detail_urls(fetcher('https://nclottery.com/'+history),route)
        reports.extend(parser([(u,fetcher(u)) for u in urls],today=now.date()))
    for size in [3,4]:
        urls=detail_urls(fetcher(f'https://nclottery.com/pick{size}-past'),f'Pick{size}-Draw',pick=True)
        reports.extend(parse_pick_reports([(u,fetcher(u)) for u in urls],f'Pick {size}',today=now.date()))
    validate_collection(reports,previous)
    result=dict(schemaVersion=1,stateCode='NC',
        coverage='Two recent official reports per supported game/session. Source-defined Wins and summaries are not distinct people, complete claims, retailer activity or map positions. Source qualifications and warnings must remain visible.',
        reports=sorted(reports,key=lambda r:(r['game'],r['session'],r['drawDate']),reverse=True))
    if previous and all(previous.get(k)==v for k,v in result.items()): return previous
    result['updatedAt']=now.isoformat()
    output.parent.mkdir(parents=True,exist_ok=True)
    temporary=output.with_suffix(output.suffix+'.tmp')
    try:
        temporary.write_text(json.dumps(result,ensure_ascii=False,indent=2)+'\n')
        temporary.replace(output)
    finally:
        if temporary.exists(): temporary.unlink()
    return result


if __name__=='__main__':
    parser=argparse.ArgumentParser();parser.add_argument('--output',required=True)
    args=parser.parse_args()
    print('Validated NC reports:',len(refresh(args.output)['reports']))
