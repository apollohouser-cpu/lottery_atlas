"""Import the explicitly active subset of South Dakota's published catalog."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import subprocess
from lxml import html
SOURCE='https://lottery.sd.gov/scratch-games/'
API='https://lottery.sd.gov/api/igt/games/v1/instant-games/games/'

def integer(v, positive=False):
    if type(v) is not int or v < (1 if positive else 0):raise ValueError('Invalid integer inventory/amount')
    return v

def parse_listing(raw):
    nodes=html.fromstring(raw).xpath('//script[@id="__NEXT_DATA__"]/text()')
    if len(nodes)!=1:raise ValueError('Missing page data')
    blocks=json.loads(nodes[0])['props']['pageProps']['post']['blocks']
    sources=[b['attributes']['games'] for b in blocks if 'games' in b.get('attributes',{})]
    if len(sources)!=1 or not isinstance(sources[0],list) or not sources[0]:raise ValueError('Missing or ambiguous published listing')
    seen=set();selected=[]
    for edge in sources[0]:
        g=edge['node'];gid=g['acf']['igtIdentifier']
        if not isinstance(gid,str) or not gid.isdigit() or gid in seen:raise ValueError('Invalid or duplicate game identity')
        seen.add(gid)
        kinds={x['slug'] for x in g['gameTypes']['nodes']}
        if kinds!={'scratch-tickets'}:raise ValueError('Unexpected game type')
        options={x['node']['slug'] for x in g['gameOptions']['edges']}
        if 'active' not in options:continue
        if options.intersection({'closed','upcoming'}):raise ValueError('Conflicting active status')
        prices=g['gamePrices']['nodes']
        if len(prices)!=1 or not re.fullmatch(r'\d+',prices[0]['slug']):raise ValueError('Ambiguous ticket price')
        cost=integer(int(prices[0]['slug']),True)
        if not g.get('title') or not re.fullmatch(r'[a-z0-9-]+',g['slug']):raise ValueError('Missing game title or slug')
        selected.append(dict(id=gid,name=g['title'],cost=cost,slug=g['slug']))
    if not selected:raise ValueError('Empty active subset')
    return selected,len(sources[0])

def parse_inventory(raw,game):
    d=json.loads(raw)
    if d.get('gameId')!=game['id'] or d.get('validationStatus')!='ACTIVE':raise ValueError('Inventory identity/status mismatch')
    if integer(d.get('ticketPrice'),True)!=game['cost']*100:raise ValueError('Listing/API ticket price mismatch')
    rows=d.get('prizeTiers')
    if not isinstance(rows,list) or not rows:raise ValueError('Missing prize tiers')
    tiers=[];seen=set()
    for t in rows:
        number=integer(t.get('tierNumber'),True)
        if number in seen:raise ValueError('Duplicate prize tier')
        seen.add(number)
        cents=integer(t.get('prizeAmount'),True);original=integer(t.get('winningTickets'));paid=integer(t.get('paidTickets'))
        if paid>original:raise ValueError('Paid count exceeds original inventory')
        tiers.append(dict(tierNumber=number,prizeAmount=cents/100,winningTickets=original,paidTickets=paid,remaining=original-paid))
    top=max(t['prizeAmount'] for t in tiers)
    top_rows=[t for t in tiers if t['prizeAmount']==top]
    if len(top_rows)!=1:raise ValueError('Ambiguous top tier')
    return dict(stateName='South Dakota',id=game['id'],name=game['name'],cost=game['cost'],topPrize=top,
                topPrizesRemaining=top_rows[0]['remaining'],prizeTiers=tiers,sourceUrl='https://lottery.sd.gov/game/'+game['slug']+'/',inventorySource=API+game['id'],
                inventoryNote='Published active-list subset; complete state coverage unconfirmed. Remaining = original winning inventory minus paid tickets. Cumulative counts, not 2026 claims. Source verification timestamp and store availability unknown.')

def fetch(url):return subprocess.run(['curl','-fsSL','--max-time','30','--retry','3',url],capture_output=True,check=True).stdout

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('output',type=Path);args=parser.parse_args()
    games,total=parse_listing(fetch(SOURCE))
    with ThreadPoolExecutor(max_workers=2) as pool:verified=list(pool.map(lambda g:parse_inventory(fetch(API+g['id']),g),games))
    if len(verified)<15:raise ValueError('Unexpectedly small active subset')
    catalog=dict(state='South Dakota',source=SOURCE,sourceDate=None,publishedListingCount=total,
                 coverage='Explicitly active Scratch entries in the published listing only. Listing completeness/pagination unconfirmed (100 entries at initial audit). Cumulative prize inventory/paid counts, not dated claims or retailer activity. Operational distribution/disable dates are not interpreted as consumer claim deadlines.',
                 updateCadence='Checked every six hours; official inventory publication cadence unconfirmed.',games=sorted(verified,key=lambda g:int(g['id'])))
    result=dict(source='South Dakota official published active Scratch subset',updatedAt=datetime.now(timezone.utc).isoformat(),catalogs=[catalog])
    if args.output.exists():
        old=json.loads(args.output.read_text())
        if old.get('catalogs')==result['catalogs']:result['updatedAt']=old['updatedAt']
    temp=args.output.with_suffix('.tmp');temp.write_text(json.dumps(result,indent=2)+'\n');temp.replace(args.output)
    print(f'Validated {len(verified)} active games from {total} published entries')
if __name__=='__main__':main()
