"""Join current Nebraska game details to a separately reviewed dated report."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime
import json
from pathlib import Path
import re
import subprocess
from zoneinfo import ZoneInfo
from lxml import html
SOURCE='https://nelottery.com/scratch'
REPORT='https://nelottery.com/images/media/Scratch_Prizes_Remaining.pdf'

def plain(node):return ' '.join(node.text_content().split())
def count(text):
    if not re.fullmatch(r'(?:\d+|\d{1,3}(?:,\d{3})+)',text):raise ValueError('Invalid integer count')
    return int(text.replace(',',''))

def parse_listing(raw):
    tree=html.fromstring(raw);games=[];seen=set()
    for a in tree.xpath('//a[contains(@href,"scratch-detail?")]'):
        # Promotional navigation repeats games without catalog prices or structure.
        if a.xpath('ancestor::*[contains(concat(" ",normalize-space(@class)," ")," sbm_contain_all ")]'):
            continue
        link=a.get('href')
        if not re.fullmatch(r'/scratch-detail\?gameid=\d+',link) or link in seen:raise ValueError('Invalid detail link')
        seen.add(link)
        card=a.getparent().getparent();row=card.getparent().getparent()
        prices=row.xpath('.//div[contains(@class,"scratch_ball")]/div/text()')
        names=card.xpath('.//strong')
        if len(prices)!=1 or len(names)!=1 or not re.fullmatch(r'\$\d+',prices[0]):raise ValueError('Ambiguous listing price/name')
        price=count(prices[0][1:])
        if not price or not plain(names[0]):raise ValueError('Empty listing identity')
        games.append(dict(url='https://nelottery.com'+link,name=plain(names[0]),cost=price))
    if not games:raise ValueError('Empty catalog')
    return games

def parse_detail(raw,listing):
    tree=html.fromstring(raw)
    names=[plain(x) for x in tree.xpath('//strong') if re.match(r'^\d{4} ',plain(x))]
    if len(names)!=1:raise ValueError('Missing printed game identity')
    gid,name=names[0].split(' ',1)
    if name.casefold()!=listing['name'].casefold():raise ValueError('Detail/listing name mismatch')
    tables=tree.xpath('//table')
    if len(tables)!=1:raise ValueError('Missing prize structure')
    rows=tables[0].xpath('.//tr')
    if [plain(x) for x in rows[0].xpath('./th|./td')]!=['Prize','Odds','Winners**']:raise ValueError('Changed prize-structure columns')
    tiers=[];cash=[]
    for row in rows[1:]:
        cells=[plain(x) for x in row.xpath('./td')]
        if len(cells)!=3:raise ValueError('Incomplete prize structure')
        label,odds,winners=cells
        if not re.fullmatch(r'[\d,]+\.\d{2}',odds):raise ValueError('Invalid published odds')
        tier=dict(prizeLabel=label,publishedOdds=odds,publishedStructureWinners=count(winners))
        if re.fullmatch(r'\$[\d,]+',label):
            amount=count(label[1:])
            if not amount:raise ValueError('Nonpositive prize')
            tier['prizeAmount']=amount;cash.append(amount)
        elif not re.fullmatch(r'(?:Free \$\d+ Ticket|\$\d+ Free Ticket)(?: \+ \$\d+)?',label):raise ValueError('Unsupported prize label')
        tiers.append(tier)
    if not cash:raise ValueError('No cash prize structure')
    return dict(stateName='Nebraska',id=gid,name=name,cost=listing['cost'],topPrize=max(cash),sourceUrl=listing['url'],prizeStructure=tiers)

def reviewed_counts(root,today):
    if root.get('source')!=REPORT or not re.fullmatch(r'[0-9a-f]{64}',root.get('sourceSha256','')):raise ValueError('Invalid reviewed report provenance')
    stamp=date.fromisoformat(root['sourceDate'])
    if stamp>today:raise ValueError('Future report date')
    games=root.get('games');counts={}
    if not isinstance(games,list) or not games:raise ValueError('Missing report rows')
    for g in games:
        gid=g.get('id')
        if not isinstance(gid,str) or not gid.isdigit() or gid in counts:raise ValueError('Duplicate or invalid report identity')
        if type(g.get('topPrize')) is not int or g['topPrize']<=0 or type(g.get('topPrizesRemaining')) is not int or g['topPrizesRemaining']<0:raise ValueError('Invalid reviewed report counts')
        counts[gid]=g
    return counts

def join_report(games,report,today):
    counts=reviewed_counts(report,today);seen=set()
    for game in games:
        if game['id'] in seen:raise ValueError('Duplicate printed game identity')
        seen.add(game['id']);item=counts.get(game['id'])
        if item:
            if item['topPrize']!=game['topPrize']:raise ValueError('Report/detail top-prize mismatch')
            game['topPrizesRemaining']=item['topPrizesRemaining']
            game['inventoryNote']=f"Top-prize inventory as of {report['sourceDate']}; weekly report, manually reviewed."
        else:
            game['inventoryNote']=f"Remaining count unknown: absent from reviewed {report['sourceDate']} report."
        game['inventoryNote']+=' Prize-structure winners are not dated claims. Store availability unverified.'
    return dict(state='Nebraska',source=SOURCE,sourceDate=report['sourceDate'],inventorySource=REPORT,
                coverage='Current catalog joined by printed game number to a manually reviewed dated top-prize report. Unknown unmatched counts remain missing. Prize-structure rows are not claims or remaining inventory. Excludes report-only games absent from current catalog; no retailer joins.',
                updateCadence='Official remaining-prize report is weekly; this reviewed snapshot is not automatically refreshed. Catalog details checked every six hours.',
                games=sorted(games,key=lambda g:int(g['id'])))

def fetch(url):return subprocess.run(['curl','-fsSL','--max-time','30','--retry','3',url],capture_output=True,check=True).stdout

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('output',type=Path);args=parser.parse_args()
    today=datetime.now(ZoneInfo('America/Chicago'))
    listing=parse_listing(fetch(SOURCE))
    with ThreadPoolExecutor(max_workers=3) as pool:games=list(pool.map(lambda g:parse_detail(fetch(g['url']),g),listing))
    if len(games)<15:raise ValueError('Unexpectedly small catalog')
    report=json.loads((Path(__file__).resolve().parents[1]/'data/nebraska_top_prizes.reviewed.json').read_text())
    catalog=join_report(games,report,today.date());result=dict(source='Nebraska official catalog and reviewed dated top-prize inventory',updatedAt=today.isoformat(),catalogs=[catalog])
    if args.output.exists():
        old=json.loads(args.output.read_text())
        if old.get('catalogs')==result['catalogs']:result['updatedAt']=old['updatedAt']
    temp=args.output.with_suffix('.tmp');temp.write_text(json.dumps(result,indent=2)+'\n');temp.replace(args.output)
    print(f"Validated {len(games)} Nebraska games; {sum('topPrizesRemaining' in g for g in games)} dated counts")
if __name__=='__main__':main()
