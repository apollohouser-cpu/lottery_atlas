"""Import dated estimated New Mexico top-prize inventory with claim deadlines."""
import argparse
from datetime import datetime
import json
from pathlib import Path
import re
import subprocess
from zoneinfo import ZoneInfo
from lxml import html
SOURCE='https://www.nmlottery.com/games/scratchers/top-prizes-not-yet-claimed/'
INVENTORY='https://nmlotteryscratchers.sks.com/ScratchersPrize/GetTopPrizesHtml'
ENDING='https://www.nmlottery.com/games/scratchers/games-ending/'

def plain(node):return ' '.join(node.text_content().split())
def count(value):
    if not re.fullmatch(r'(?:\d+|\d{1,3}(?:,\d{3})+)',value):raise ValueError('Invalid count')
    return int(value.replace(',',''))
def cash(value):
    if not value.startswith('$'):raise ValueError('Missing cash denomination')
    number=count(value[1:])
    if number<=0:raise ValueError('Nonpositive cash amount')
    return number

def parse_inventory(raw):
    tree=html.fromstring(raw)
    stamps=tree.xpath('//p[@class="top-prizes-update-time"]/strong')
    if len(stamps)!=1:raise ValueError('Missing source timestamp')
    literal=plain(stamps[0]);stamp=datetime.strptime(literal,'%B %d, %Y %I:%M %p')
    tables=tree.xpath('//table')
    if len(tables)!=1:raise ValueError('Missing inventory table')
    if [plain(c) for c in tables[0].xpath('./thead/tr/th')]!=['Ticket Cost','Game #','Game Name','Top Prize Amount','Top Prizes Remaining']:raise ValueError('Changed inventory schema')
    games=[];seen=set()
    for row in tables[0].xpath('./tbody/tr'):
        values=[plain(c) for c in row.xpath('./td')]
        if len(values)!=5:raise ValueError('Incomplete inventory row')
        price,gid,name,prize,remaining=values
        if not gid.isdigit() or gid in seen or not name:raise ValueError('Invalid game identity')
        seen.add(gid)
        games.append(dict(stateName='New Mexico',id=gid,name=name,cost=cash(price),topPrize=cash(prize),topPrizesRemaining=count(remaining),sourceUrl=SOURCE))
    if not games:raise ValueError('Empty inventory')
    return stamp.date(),literal,games

def parse_endings(raw,required_ids):
    tree=html.fromstring(raw);tables=tree.xpath('//table')
    if len(tables)!=2:raise ValueError('Changed ending tables')
    first=tables[0].xpath('.//tr')[0]
    header=[plain(c) for c in first.xpath('./th|./td')]
    if header!=['Game #','Game','End Date','Last Day to Redeem']:raise ValueError('Changed ending columns')
    records={};anomalies=[]
    for table in tables:
        for row in table.xpath('.//tr'):
            values=[plain(c) for c in row.xpath('./td|./th')]
            if values==header:continue
            if len(values)!=4 or not values[0].isdigit():raise ValueError('Malformed ending row')
            gid,name,end,claim=values
            if gid in records:raise ValueError('Duplicate ending identity')
            try:
                end_date=datetime.strptime(end,'%m/%d/%Y').date()
                claim_date=datetime.strptime(claim,'%m/%d/%Y').date()
                if claim_date<end_date:raise ValueError('Claim deadline before game end')
            except ValueError:
                if gid in required_ids:raise ValueError('Invalid dates for inventory game '+gid)
                anomalies.append(gid);records[gid]=None;continue
            records[gid]=dict(endDate=end_date.isoformat(),lastDayToRedeem=claim_date.isoformat())
    if not records:raise ValueError('Empty ending notices')
    return records,anomalies

def build_catalog(inventory,ending,today):
    source_date,literal,games=parse_inventory(inventory)
    if source_date>today:raise ValueError('Future source date')
    dates,anomalies=parse_endings(ending,{g['id'] for g in games})
    kept=[];expired=[]
    for g in games:
        record=dates.get(g['id'])
        if record:
            if record['lastDayToRedeem']<today.isoformat():expired.append(g['id']);continue
            g.update(record)
        note=f'Estimated top-prize inventory as of {literal} (timezone unpublished). Tickets may already be sold or awaiting redemption.'
        if record:note+=f" Game ends {record['endDate']}; redeem by {record['lastDayToRedeem']}."
        note+=' Not dated winning-ticket totals; store availability unverified.'
        g['inventoryNote']=note;kept.append(g)
    if not kept:raise ValueError('No unexpired inventory entries')
    return dict(state='New Mexico',source=SOURCE,inventorySource=INVENTORY,endingSource=ENDING,
                sourceDate=source_date.isoformat(),sourceTimestamp=literal,sourceTimezone=None,
                coverage='Estimated top-prize report entries excluding passed official claim deadlines. Includes ended games still redeemable; does not establish active store stock, all-tier claims or retailer joins.',
                updateCadence='Checked every six hours; source publication cadence unconfirmed.',
                excludedExpiredGameIds=sorted(expired),unrelatedEndingDateAnomalies=sorted(anomalies),
                games=sorted(kept,key=lambda g:int(g['id'])))

def fetch(url):return subprocess.run(['curl','-fsSL','--max-time','30','--retry','3',url],capture_output=True,check=True).stdout

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('output',type=Path);args=parser.parse_args()
    now=datetime.now(ZoneInfo('America/Denver'));catalog=build_catalog(fetch(INVENTORY),fetch(ENDING),now.date())
    if len(catalog['games'])<20:raise ValueError('Unexpectedly small inventory')
    result=dict(source='New Mexico dated estimated top-prize inventory',updatedAt=now.isoformat(),catalogs=[catalog])
    if args.output.exists():
        old=json.loads(args.output.read_text())
        if old.get('catalogs')==result['catalogs']:result['updatedAt']=old['updatedAt']
    temp=args.output.with_suffix('.tmp');temp.write_text(json.dumps(result,indent=2)+'\n');temp.replace(args.output)
    print(f"Validated {len(catalog['games'])} unexpired entries; excluded {len(catalog['excludedExpiredGameIds'])} expired games")
if __name__=='__main__':main()
