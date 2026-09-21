"""Import Louisiana report candidates with verified detail inventory and eligibility."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime, timedelta, timezone
import json
from pathlib import Path
import re
import subprocess
from zoneinfo import ZoneInfo
from lxml import html
SOURCE='https://louisianalottery.com/top-prizes-remaining/'

def plain(node):return ' '.join(node.text_content().split())
def number(value):
    if not isinstance(value,str) or not re.fullmatch(r'(?:\d+|\d{1,3}(?:,\d{3})+)',value):raise ValueError('Invalid numeric source value')
    return int(value.replace(',',''))
def timestamp(tree):
    matches=re.findall(r'Last Updated:\s*(\d{2}/\d{2}/\d{4} \d{2}:\d{2}:\d{2} [AP]M) (CDT|CST)',plain(tree))
    if len(matches)!=1:raise ValueError('Missing or ambiguous source timestamp')
    value,zone=matches[0]
    return datetime.strptime(value,'%m/%d/%Y %I:%M:%S %p').replace(tzinfo=timezone(timedelta(hours=-5 if zone=='CDT' else -6)))

def parse_report(raw):
    tree=html.fromstring(raw);scripts=tree.xpath('//prize-table/script[@type="application/json"]/text()')
    if len(scripts)!=1:raise ValueError('Missing report data')
    data=json.loads(scripts[0]);rows=data['data']
    if [x['key'] for x in data['columns']]!=['image','number','price','game','remaining','top_prize','percent_claimed','start_date']:raise ValueError('Changed report columns')
    if not isinstance(rows,list) or not rows:raise ValueError('Empty report')
    seen=set()
    for g in rows:
        gid=g['number'];number(gid)
        if gid in seen:raise ValueError('Duplicate game identity')
        seen.add(gid)
        if number(g['price'])<=0 or number(g['top_prize'])<=0:raise ValueError('Nonpositive price/prize')
        if not g['game']['name'] or not re.fullmatch(r'https://louisianalottery.com/game/[a-z0-9-]+/',g['game']['link']):raise ValueError('Invalid source link')
        counts=re.fullmatch(r'(\d+) of (\d+)',g['remaining'])
        if not counts or int(counts[1])>int(counts[2]):raise ValueError('Invalid remaining/original counts')
        datetime.strptime(g['start_date'],'%m/%d/%Y')
    return rows,timestamp(tree)

def parse_detail(raw,game,today):
    tree=html.fromstring(raw);titles=tree.xpath('//title/text()')
    if not titles or not titles[0].startswith(game['number']+' - '):raise ValueError('Printed game identity mismatch')
    if 'This game expired on' in plain(tree):return None
    meta=[plain(x) for x in tree.xpath('//ul[contains(@class,"hero__game-meta")]/li')]
    deadlines=[x.removeprefix('Final Redemption Date: ') for x in meta if x.startswith('Final Redemption Date: ')]
    if len(deadlines)>1:raise ValueError('Ambiguous claim deadline')
    deadline=datetime.strptime(deadlines[0],'%b %d, %Y').date() if deadlines else None
    if deadline and deadline<today:return None
    prices=[e for e in tree.xpath('//li[.//em]') if 'Ticket Price' in plain(e)]
    if len(prices)!=1:raise ValueError('Missing detail price')
    price=plain(prices[0].xpath('.//em')[0])
    if not price.startswith('$') or number(price[1:])!=number(game['price']):raise ValueError('Price mismatch')
    starts=tree.xpath('//ul[contains(@class,"hero__game-meta")]//time/@datetime')
    if len(starts)!=1 or starts[0]!=datetime.strptime(game['start_date'],'%m/%d/%Y').date().isoformat():raise ValueError('Launch date mismatch')
    if starts[0]>today.isoformat():raise ValueError('Future launch')
    tables=tree.xpath('//table[caption[contains(text(),"Scratch-offs Prize")]]')
    if len(tables)!=1:raise ValueError('Missing prize table')
    if [plain(c) for c in tables[0].xpath('./thead/tr/th')]!=['Tier Prize','Odds of Winning','Total','Claimed','Remaining']:raise ValueError('Changed tier schema')
    tiers=[];seen=set()
    for row in tables[0].xpath('./tbody/tr'):
        cells=[plain(c) for c in row.xpath('./td')]
        if len(cells)!=5:raise ValueError('Incomplete tier row')
        label,odds,total,claimed,remaining=cells
        if label in seen:raise ValueError('Duplicate tier')
        seen.add(label);total,claimed,remaining=map(number,[total,claimed,remaining])
        if total!=claimed+remaining:raise ValueError('Inventory does not reconcile')
        t=dict(prizeLabel=label,total=total,claimed=claimed,remaining=remaining,publishedOdds=odds)
        if label.startswith('$'):t['prizeAmount']=number(label[1:])
        elif label!='TICKET':raise ValueError('Unsupported noncash prize')
        tiers.append(t)
    cash=[t for t in tiers if 'prizeAmount' in t]
    if not cash:raise ValueError('Missing cash prizes')
    top=max(cash,key=lambda t:t['prizeAmount'])
    if top['prizeAmount']!=number(game['top_prize']):raise ValueError('Top prize mismatch')
    stamp=timestamp(tree)
    if stamp.astimezone(ZoneInfo('America/Chicago')).date()>today:raise ValueError('Future source timestamp')
    note=f"Inventory as of {stamp.isoformat()}. Cumulative game totals/claims, not dated winning-ticket totals. Store availability unverified."
    if deadline:note+=f' Redeem by {deadline.isoformat()}.'
    result=dict(stateName='Louisiana',id=game['number'],name=game['game']['name'],cost=number(game['price']),topPrize=top['prizeAmount'],topPrizesRemaining=top['remaining'],startDate=starts[0],sourceUrl=game['game']['link'],sourceTimestamp=stamp.isoformat(),prizeTiers=tiers,inventoryNote=note)
    if deadline:result['lastDayToRedeem']=deadline.isoformat()
    return result

def fetch(url):return subprocess.run(['curl','-fsSL','--max-time','30','--retry','3',url],capture_output=True,check=True).stdout

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('output',type=Path);args=parser.parse_args()
    now=datetime.now(ZoneInfo('America/Chicago'));rows,stamp=parse_report(fetch(SOURCE))
    if stamp.astimezone(ZoneInfo('America/Chicago')).date()>now.date():raise ValueError('Future report date')
    with ThreadPoolExecutor(max_workers=2) as pool:parsed=list(pool.map(lambda g:parse_detail(fetch(g['game']['link']),g,now.date()),rows))
    games=[g for g in parsed if g is not None]
    if len(games)<20:raise ValueError('Unexpectedly small eligible catalog')
    catalog=dict(state='Louisiana',source=SOURCE,sourceDate=stamp.date().isoformat(),reportTimestamp=stamp.isoformat(),coverage='Top-prize report candidates with unexpired detail pages. Per-game detail timestamps govern tier inventory; report timestamp governs candidate discovery. Cumulative game inventory only, not dated claims or retailer joins.',updateCadence='Checked every six hours; inventory publication cadence unconfirmed.',games=sorted(games,key=lambda g:int(g['id'])))
    result=dict(source='Louisiana official verified game-detail inventory',updatedAt=now.isoformat(),catalogs=[catalog])
    if args.output.exists():
        old=json.loads(args.output.read_text())
        if old.get('catalogs')==result['catalogs']:result['updatedAt']=old['updatedAt']
    temp=args.output.with_suffix('.tmp');temp.write_text(json.dumps(result,indent=2)+'\n');temp.replace(args.output)
    print(f'Validated {len(games)} eligible Louisiana games')
if __name__=='__main__':main()
