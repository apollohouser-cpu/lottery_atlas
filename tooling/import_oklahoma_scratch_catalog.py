"""Import Oklahoma's official no-end-date Scratcher catalog and inventory."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
import json
from pathlib import Path
import re
import subprocess
from zoneinfo import ZoneInfo
from lxml import html
SOURCE='https://oklottery.com/games/scratchers'

def embedded(raw,key):
    chunks=[]
    for script in html.fromstring(raw).xpath('//script[not(@src)]/text()'):
        match=re.fullmatch(r'self\.__next_f\.push\((\[.*\])\)',script,re.S)
        if match:
            value=json.loads(match[1])
            if len(value)==2 and value[0]==1 and isinstance(value[1],str):chunks.append(value[1])
    text=''.join(chunks);marker='"'+key+'":'
    if text.count(marker)!=1:raise ValueError('Missing or ambiguous '+key)
    return json.JSONDecoder().raw_decode(text.split(marker,1)[1].lstrip())[0]

def integer(v,positive=False):
    if type(v) is not int or v<(1 if positive else 0):raise ValueError('Invalid integer value')
    return v

def parse_listing(raw,today):
    games=embedded(raw,'scratchOffs');selected=[];seen=set();internal=set();slugs=set()
    if not isinstance(games,list) or not games:raise ValueError('Empty published catalog')
    for g in games:
        gid=g.get('gameNumber');key=integer(g.get('gameId'),True);slug=g.get('slug')
        if not isinstance(gid,str) or not gid.isdigit() or gid in seen or key in internal:raise ValueError('Duplicate or invalid identity')
        if not isinstance(slug,str) or not re.fullmatch(r'[a-z0-9-]+',slug) or slug in slugs:raise ValueError('Invalid slug')
        seen.add(gid);internal.add(key);slugs.add(slug)
        if type(g.get('pullTab')) is not bool or not g.get('title'):raise ValueError('Missing type/name')
        integer(g.get('ticketPrice'),True);integer(g.get('topPrize'),True)
        if 'endDate' not in g:raise ValueError('Missing ending status')
        start=datetime.fromisoformat(g['startDate'])
        if start.tzinfo is None:raise ValueError('Missing launch timezone')
        if g['endDate'] is not None:
            end=datetime.fromisoformat(g['endDate'])
            if end.tzinfo is None or end<start:raise ValueError('Invalid end date')
        if not g['pullTab'] and g['endDate'] is None and start.date()<=today:selected.append(g)
    if not selected:raise ValueError('No eligible games')
    return selected,len(games)

def parse_detail(raw,game):
    d=embedded(raw,'cms')
    for k in ['gameId','gameNumber','slug','ticketPrice','topPrize','startDate']:
        if d.get(k)!=game[k]:raise ValueError('Detail/listing mismatch: '+k)
    if d.get('pullTab') is not False or 'endDate' not in d or 'claimEndDate' not in d or d['endDate'] is not None or d['claimEndDate'] is not None:raise ValueError('Changed detail eligibility')
    groups=d.get('prizeDetails')
    if not isinstance(groups,list) or len(groups)!=1:raise ValueError('Ambiguous prize structure')
    rows=groups[0].get('matches')
    if not isinstance(rows,list) or not rows:raise ValueError('Missing prize tiers')
    tiers=[];seen=set()
    for row in rows:
        label=row.get('prize')
        if not isinstance(label,str) or not re.fullmatch(r'\$\$(?:\d+|\d{1,3}(?:,\d{3})+)',label):raise ValueError('Unsupported prize format')
        amount=int(label[2:].replace(',',''))
        if amount<=0 or amount in seen:raise ValueError('Invalid or duplicate tier')
        seen.add(amount);remaining=integer(row.get('remainingPrizes'));total=integer(row.get('totalPrizes'))
        if remaining>total:raise ValueError('Impossible inventory')
        tiers.append(dict(prizeAmount=amount,remainingPrizes=remaining,totalPrizes=total))
    if max(t['prizeAmount'] for t in tiers)!=game['topPrize']:raise ValueError('Top tier mismatch')
    top=next(t for t in tiers if t['prizeAmount']==game['topPrize'])
    return dict(stateName='Oklahoma',id=game['gameNumber'],name=game['title'],cost=game['ticketPrice'],topPrize=game['topPrize'],topPrizesRemaining=top['remainingPrizes'],internalGameId=game['gameId'],startDate=datetime.fromisoformat(game['startDate']).date().isoformat(),totalTickets=integer(d.get('totalTickets'),True),prizeTiers=tiers,sourceUrl=SOURCE+'/'+game['slug'],inventoryNote='Published no-end-date Scratcher subset. Remaining prize inventory, not dated claims. Source verification timestamp/cadence and store availability unconfirmed.')

def fetch(url):return subprocess.run(['curl','-fsSL','--max-time','30','--retry','3',url],capture_output=True,check=True).stdout

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('output',type=Path);args=parser.parse_args()
    now=datetime.now(ZoneInfo('America/Chicago'));games,total=parse_listing(fetch(SOURCE),now.date())
    with ThreadPoolExecutor(max_workers=2) as pool:verified=list(pool.map(lambda g:parse_detail(fetch(SOURCE+'/'+g['slug']),g),games))
    if len(verified)<20:raise ValueError('Unexpectedly small catalog')
    catalog=dict(state='Oklahoma',source=SOURCE,sourceDate=None,publishedListingCount=total,coverage='Published Scratcher entries with no end or claim deadline and launched by retrieval date. Original prize totals, remaining prizes and total tickets are distinct; no dated claims or retailer joins.',updateCadence='Checked every six hours; official Scratcher inventory update cadence unconfirmed.',games=sorted(verified,key=lambda g:int(g['id'])))
    result=dict(source='Oklahoma official no-end-date Scratcher inventory',updatedAt=now.isoformat(),catalogs=[catalog])
    if args.output.exists():
        old=json.loads(args.output.read_text())
        if old.get('catalogs')==result['catalogs']:result['updatedAt']=old['updatedAt']
    temp=args.output.with_suffix('.tmp');temp.write_text(json.dumps(result,indent=2)+'\n');temp.replace(args.output)
    print(f'Validated {len(verified)} games from {total} published entries')
if __name__=='__main__':main()
