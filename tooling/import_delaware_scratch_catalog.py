"""Join Delaware's current Instant Games to its dated weekly top-prize report."""
import argparse
from datetime import datetime
import json
from pathlib import Path
import re
import subprocess
from zoneinfo import ZoneInfo
from lxml import html

ROOT='https://www.delottery.com'
SOURCE=ROOT+'/Instant-Games'
REPORT=SOURCE+'/Top-Prizes-Remaining'
CLOSEOUT=SOURCE+'/Close-Out-Schedule'

def text(node):return ' '.join(node.text_content().split())
def integer(value):
    if not re.fullmatch(r'\$?(?:\d+|\d{1,3}(?:,\d{3})+)',value):raise ValueError('Invalid nonnegative integer')
    return int(value.replace('$','').replace(',',''))
def table(raw,headers):
    tree=html.fromstring(raw);tables=tree.xpath('//table')
    if len(tables)!=1 or [text(n) for n in tables[0].xpath('./thead/tr/th')]!=headers:raise ValueError('Changed table headers')
    return tree,tables[0].xpath('./tbody/tr')

def parse_report(raw):
    tree,rows=table(raw,['Game Number','Game Name','Dollar Amount','Top Prize','Total Top Prizes','Prizes Remaining'])
    full=text(tree)
    dates=re.findall(r'as of (\d{1,2}/\d{1,2}/\d{4} \d{1,2}:\d{2}:\d{2} [AP]M)',full)
    if len(dates)!=1 or 'routine weekly updates' not in full:raise ValueError('Missing report timestamp or cadence statement')
    stamp=datetime.strptime(dates[0],'%m/%d/%Y %I:%M:%S %p')
    result={}
    for row in rows:
        c=[text(n) for n in row.xpath('./td')]
        if len(c)!=6 or not re.fullmatch(r'\d+\*?',c[0]):raise ValueError('Invalid report row')
        gid=c[0].rstrip('*')
        if gid in result or not c[1]:raise ValueError('Duplicate or missing report identity')
        cost,top,original,remaining=map(integer,c[2:])
        if min(cost,top,original)<=0 or remaining>original:raise ValueError('Invalid prize/count range')
        result[gid]=dict(name=c[1],cost=cost,topPrize=top,original=original,remaining=remaining)
    if not result:raise ValueError('Empty report')
    return stamp,result

def parse_catalog(raw):
    tree=html.fromstring(raw);games={}
    # Exclude featured navigation duplicates; only the current-game grid owns eligibility.
    cards=tree.xpath('//div[contains(concat(" ",normalize-space(@class)," ")," item ")]/div[@data-toggle="modal"][@data-gamenumber]')
    for card in cards:
        gid=card.get('data-gamenumber');name=card.get('data-gamename','').strip()
        if not gid or not gid.isdigit() or not name or card.getparent().get('data-gamenumber')!=gid:raise ValueError('Invalid catalog identity')
        cost=integer(card.get('data-amount',''));top=integer(card.get('data-topprize',''))
        if min(cost,top)<=0:raise ValueError('Invalid catalog prize/price')
        detail=card.get('data-imagedetailinfo','')
        if not detail.startswith('https://delotterywebcontent.blob.core.windows.net/delottery-site-assets/images/instant-lottery/instant-details/'):raise ValueError('Unrecognized detail source')
        if gid in games:
            old=games[gid]
            if old['cost']!=cost or old['topPrize']!=top or old['detailImage']!=detail or name in old['names']:raise ValueError('Conflicting or duplicate catalog card')
            old['names'].append(name)
        else:games[gid]=dict(cost=cost,topPrize=top,names=[name],detailImage=detail)
    if not games:raise ValueError('Empty current catalog')
    return games

def parse_closeouts(raw):
    _,rows=table(raw,['Name','Game Number','Date Launched','Announced End of Sales']);result={}
    for row in rows:
        c=[text(n) for n in row.xpath('./td')]
        if len(c)!=4 or not c[1].isdigit() or c[1] in result:raise ValueError('Invalid closeout record')
        start,end=[datetime.strptime(v,'%m/%d/%Y').date() for v in c[2:]]
        if end<start:raise ValueError('Invalid closeout dates')
        result[c[1]]=dict(start=start,end=end)
    return result

def join(catalog,stamp,report,closeouts,today):
    if stamp.date()>today:raise ValueError('Future source date')
    games=[]
    for gid,c in catalog.items():
        if gid not in report:raise ValueError('Current game missing top-prize report')
        r=report[gid]
        if c['cost']!=r['cost'] or c['topPrize']!=r['topPrize']:raise ValueError('Catalog/report price or top-prize conflict')
        if len(c['names'])==1 and c['names'][0].casefold()!=r['name'].casefold():raise ValueError('Catalog/report name conflict')
        dates=closeouts.get(gid)
        if dates and (dates['end']<today or dates['start']>today):continue
        note=f"Top-prize inventory as of {stamp.strftime('%Y-%m-%d %I:%M:%S %p')}; source timezone unspecified. Routine weekly updates, with possible same-day final-top-prize changes. Unclaimed top prizes are not dated winning-ticket totals or verified store stock. Games absent from the current catalog are excluded."
        if len(c['names'])>1:note+=' Shared game number across ticket designs: '+', '.join(c['names'])+'. The reported prize counts apply once to the game, not once per design.'
        if dates:note+=f' Announced end of sales: {dates["end"]}. Claims are due within one year of the announced end of sales.'
        game=dict(stateName='Delaware',id=gid,name=r['name'],cost=r['cost'],topPrize=r['topPrize'],topPrizesRemaining=r['remaining'],originalTopPrizes=r['original'],ticketDesigns=c['names'],detailImage=c['detailImage'],sourceUrl=REPORT,sourceDate=stamp.date().isoformat(),inventoryNote=note)
        if dates:game.update(startDate=dates['start'].isoformat(),saleEndDate=dates['end'].isoformat())
        games.append(game)
    if not games:raise ValueError('No current matched games')
    return dict(state='Delaware',source=REPORT,sourceDate=stamp.date().isoformat(),sourceTimestampLocal=stamp.isoformat(),sourceTimezone=None,updateCadence='Routine weekly inventory updates; final-top-prize updates may occur the same business day. Checked every six hours.',coverage='Current catalog joined by printed game number to published top-prize inventory. Shared ticket designs counted once; report-only games excluded. No dated claims or retailer stock/joins.',excludedReportOnlyIds=sorted(set(report)-set(catalog),key=int),games=sorted(games,key=lambda g:int(g['id'])))

def fetch(url):return subprocess.run(['curl','-fsSL','--max-time','30','--retry','3',url],check=True,capture_output=True).stdout

def main():
    p=argparse.ArgumentParser(description=__doc__);p.add_argument('output',type=Path);args=p.parse_args()
    now=datetime.now(ZoneInfo('America/New_York'));stamp,report=parse_report(fetch(REPORT))
    catalog=join(parse_catalog(fetch(SOURCE)),stamp,report,parse_closeouts(fetch(CLOSEOUT)),now.date())
    if len(catalog['games'])<20:raise ValueError('Unexpectedly small current catalog')
    result=dict(source='Delaware official current Instant Games and top-prize report',updatedAt=now.isoformat(),catalogs=[catalog])
    if args.output.exists():
        old=json.loads(args.output.read_text())
        if old.get('catalogs')==result['catalogs']:result['updatedAt']=old['updatedAt']
    temp=args.output.with_suffix('.tmp');temp.write_text(json.dumps(result,indent=2)+'\n');temp.replace(args.output)
    print(f"Validated {len(catalog['games'])} Delaware games")
if __name__=='__main__':main()
