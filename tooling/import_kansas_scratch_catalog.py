"""Import verified Kansas Scratch inventory from the official PlayOn site."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
import json
from pathlib import Path
import re
import subprocess
from zoneinfo import ZoneInfo
from lxml import html

SOURCE = 'https://playonkansas.com/games/scratch-and-pull-tabs'

def positive(value):
    if type(value) is not int or value <= 0:
        raise ValueError('Invalid positive cash amount')
    return value

def integer(value):
    if not re.fullmatch(r'(?:\d+|\d{1,3}(?:,\d{3})+)', value):
        raise ValueError('Invalid remaining count')
    return int(value.replace(',', ''))

def parse_listing(raw, today):
    tree = html.fromstring(raw)
    chunks = []
    for script in tree.xpath('//script[not(@src)]/text()'):
        match = re.fullmatch(r'self\.__next_f\.push\((\[.*\])\)', script, re.S)
        if match:
            item = json.loads(match[1])
            if len(item) == 2 and item[0] == 1 and isinstance(item[1], str):
                chunks.append(item[1])
    payload = ''.join(chunks)
    marker = '"scratchOffs":'
    if payload.count(marker) != 1:
        raise ValueError('Missing or ambiguous full catalog payload')
    games = json.JSONDecoder().raw_decode(payload.split(marker, 1)[1].lstrip())[0]
    if not isinstance(games, list) or not games:
        raise ValueError('Empty catalog')
    seen, slugs, selected = set(), set(), []
    for game in games:
        gid, slug = game.get('gameNumber'), game.get('slug')
        if not isinstance(gid, str) or not gid.isdigit() or gid in seen or game.get('gameId') != int(gid):
            raise ValueError('Invalid or duplicate game identity')
        if not isinstance(slug, str) or not re.fullmatch(r'[a-z0-9-]+', slug) or slug in slugs:
            raise ValueError('Invalid or duplicate detail slug')
        seen.add(gid); slugs.add(slug)
        if type(game.get('pullTab')) is not bool or not game.get('title'):
            raise ValueError('Missing game type or title')
        positive(game.get('ticketPrice')); positive(game.get('topPrize'))
        dates = {}
        for field in ('startDate', 'endDate', 'claimEndDate'):
            if field not in game:
                raise ValueError('Missing date status')
            value = game[field]
            if value is not None:
                stamp = datetime.fromisoformat(value)
                if stamp.tzinfo is None:
                    raise ValueError('Missing source timezone')
                dates[field] = stamp.date()
        if 'startDate' not in dates:
            raise ValueError('Missing source launch date')
        # Conservative scope: no announced end or claim deadline, and launched
        # before today. Do not resolve the source's one-day display discrepancy.
        if not game['pullTab'] and game['endDate'] is None and game['claimEndDate'] is None and dates['startDate'] < today:
            selected.append(game)
    if not selected:
        raise ValueError('No eligible Scratch games')
    return selected

def field(tree, label):
    nodes = tree.xpath('//main//*[text()=$label]', label=label)
    if len(nodes) != 1:
        raise ValueError('Missing or ambiguous detail field: ' + label)
    siblings = nodes[0].getparent().getchildren()
    if len(siblings) != 2:
        raise ValueError('Changed detail field structure')
    return ' '.join(siblings[1].text_content().split())

def parse_detail(raw, game):
    tree = html.fromstring(raw)
    for label, expected in [('Game Number',game['gameNumber']), ('Price',str(game['ticketPrice'])), ('Top Prize',str(game['topPrize']))]:
        value = field(tree,label)
        if label != 'Game Number':
            if not value.startswith('$'):
                raise ValueError('Missing detail cash denomination')
            value = str(integer(value[1:]))
        if value != expected:
            raise ValueError('Detail and listing disagree: ' + label)
    if field(tree,'Expiration Date') != 'TBD':
        raise ValueError('Detail has an expiration date for undated listing')
    displayed_launch = datetime.strptime(field(tree,'Launch Date'), '%b %d, %Y').date().isoformat()
    tables = tree.xpath('//main//table')
    if len(tables) != 1 or [x.text_content() for x in tables[0].xpath('./thead/tr/th')] != ['Prize','Remaining']:
        raise ValueError('Changed prize table')
    tiers, seen = [], set()
    for row in tables[0].xpath('./tbody/tr'):
        cells = row.xpath('./td')
        if len(cells) != 2:
            raise ValueError('Incomplete prize row')
        values = []
        for cell in cells:
            spans = cell.xpath('./span')
            visible = cell.xpath('./span[@aria-hidden="true"]')
            # Official markup repeats each value for accessibility. Validate
            # both representations instead of concatenating or double counting.
            if len(spans) != 2 or len(visible) != 1 or spans[0].text_content() != spans[1].text_content():
                raise ValueError('Ambiguous duplicate prize rendering')
            values.append(visible[0].text_content().strip())
        label, remaining = values
        if label in seen:
            raise ValueError('Duplicate prize tier')
        seen.add(label)
        tier = dict(prizeLabel=label, remaining=integer(remaining))
        if label.startswith('$'):
            tier['prizeAmount'] = positive(integer(label[1:]))
        elif label != 'FREE TICKET':
            raise ValueError('Unsupported noncash tier')
        tiers.append(tier)
    cash_tiers = [t for t in tiers if 'prizeAmount' in t]
    if not cash_tiers or max(t['prizeAmount'] for t in cash_tiers) != game['topPrize']:
        raise ValueError('Advertised top prize disagrees with tiers')
    top = next(t for t in cash_tiers if t['prizeAmount'] == game['topPrize'])
    if 'The remaining prize quantity updates once every hour.' not in tree.text_content():
        raise ValueError('Source cadence statement changed')
    launch_note = ('Source launch dates conflict; normalized launch date omitted.'
                   if displayed_launch != game['startDate'][:10]
                   else 'Normalized launch date omitted pending source date verification.')
    return dict(stateName='Kansas', id=game['gameNumber'], name=game['title'], cost=game['ticketPrice'],
                topPrize=game['topPrize'], topPrizesRemaining=top['remaining'], prizeTiers=tiers,
                sourceUrl=SOURCE+'/'+game['slug'],
                sourceLaunchMetadata=game['startDate'], sourceLaunchDisplayed=displayed_launch,
                inventoryNote='Remaining prizes; source verification timestamp unpublished. ' + launch_note + ' Store availability unverified. Not dated winning-ticket totals.')

def fetch(url):
    return subprocess.run(['curl','-fsSL','--max-time','30','--retry','3','--retry-delay','2',url],capture_output=True,check=True).stdout

def build_catalog(fetcher, today):
    games = parse_listing(fetcher(SOURCE), today)
    with ThreadPoolExecutor(max_workers=3) as pool:
        verified = list(pool.map(lambda g: parse_detail(fetcher(SOURCE+'/'+g['slug']),g),games))
    return dict(state='Kansas',source=SOURCE,sourceDate=None,
                coverage='Scratch games with no announced end or claim deadline in listing metadata; excludes Pull Tabs and historical/closing listings. Remaining prize inventory only, including categorical free-ticket tiers; no dated claims or retailer joins.',
                updateCadence='Source states hourly remaining-prize updates; checked every six hours.',
                games=sorted(verified,key=lambda g:int(g['id'])))

def main():
    parser=argparse.ArgumentParser(description=__doc__);parser.add_argument('output',type=Path);args=parser.parse_args()
    now=datetime.now(ZoneInfo('America/Chicago'))
    catalog=build_catalog(fetch,now.date())
    if len(catalog['games']) < 20:
        raise ValueError('Unexpectedly small Kansas catalog')
    result=dict(source='Kansas Lottery official Scratch prize inventory',updatedAt=now.isoformat(),catalogs=[catalog])
    if args.output.exists():
        previous=json.loads(args.output.read_text())
        if previous.get('catalogs')==result['catalogs']:result['updatedAt']=previous['updatedAt']
    temp=args.output.with_suffix('.tmp');temp.write_text(json.dumps(result,indent=2)+'\n');temp.replace(args.output)
    print(f"Validated {len(catalog['games'])} Kansas Scratch games")

if __name__=='__main__':main()
