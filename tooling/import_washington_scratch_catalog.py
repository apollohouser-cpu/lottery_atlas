"""Import Washington's published Scratch inventories, including closing games."""
import argparse
from datetime import datetime, timezone
import json
from pathlib import Path
import re
import time
from urllib.error import HTTPError, URLError
from urllib.parse import urljoin
from urllib.request import Request, urlopen
from lxml import html

SOURCE = 'https://www.walottery.com/Scratch/TopPrizesRemaining.aspx'
PRICES = (1, 2, 3, 5, 10, 20, 30)

def plain(node):
    return ' '.join(' '.join(node.itertext()).split())

def integer(text):
    if not re.fullmatch(r'(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)', text):
        raise ValueError(f'Invalid prize count: {text}')
    return int(text.replace(',', ''))

def cash_value(label):
    if re.fullmatch(r'\$[\d,]+', label):
        return integer(label[1:])
    match = re.fullmatch(r'\$([\d,]+)/yr/(\d+) years', label)
    if match:
        return integer(match[1]) * integer(match[2])
    if label in ('LIFE', 'BRONCO'):
        return None
    raise ValueError(f'Unrecognized prize label: {label}')

def parse_page(raw, price):
    tree = html.fromstring(raw)
    timestamps = tree.xpath('//p[starts-with(normalize-space(.),"Updated:")]/text()')
    if len(timestamps) != 1:
        raise ValueError('Missing or ambiguous source timestamp')
    printed = timestamps[0].removeprefix('Updated:').strip()
    date = datetime.strptime(printed, '%m/%d/%Y %I:%M:%S %p').date().isoformat()
    games = []
    for item in tree.xpath('//div[contains(concat(" ",normalize-space(@class)," ")," prizes-remaining-item ")]'):
        headers = item.xpath('.//header')
        if len(headers) != 1:
            raise ValueError('Missing game header')
        header = headers[0]
        match = re.search(r'\$(\d+) \| (\d+)\b', plain(header))
        names = header.xpath('.//img/@alt')
        if not match or int(match[1]) != price or len(names) != 1 or not names[0].strip():
            raise ValueError('Invalid game identity or price category')
        columns = [plain(x) for x in item.xpath('.//table//th')]
        if columns != ['Prize Amount', 'Total Prizes', 'Prizes Paid', 'Prizes Remaining']:
            raise ValueError('Unexpected prize table columns')
        tiers = []
        for row in item.xpath('.//table//tr[td]'):
            cells = [plain(x) for x in row.xpath('./td')]
            if len(cells) != 4:
                raise ValueError('Incomplete prize tier')
            label = cells[0]
            cash_value(label)
            total, paid, remaining = map(integer, cells[1:])
            if total != paid + remaining:
                raise ValueError('Prize inventory does not reconcile')
            tiers.append(dict(prizeLabel=label, totalPrizes=total, prizesPaid=paid, prizesRemaining=remaining))
        if not tiers or len({t['prizeLabel'] for t in tiers}) != len(tiers):
            raise ValueError('Missing or duplicate tiers')
        # The official table lists its advertised top tier first. Never borrow
        # a cash-tier remaining count for a vehicle or lifetime prize.
        values = [cash_value(t['prizeLabel']) for t in tiers]
        if any(v is None for v in values[1:]) or (values[0] is not None and values[0] != max(v for v in values if v is not None)):
            raise ValueError('Unexpected top-tier ordering')
        top = tiers[0]
        game = dict(stateName='Washington', id=match[2], name=names[0].strip(), cost=price,
                    topPrize=max((v for v in values if v is not None), default=0),
                    topPrizesRemaining=top['prizesRemaining'], prizeTiers=tiers)
        if not re.fullmatch(r'\$[\d,]+', top['prizeLabel']):
            game['topPrizeLabel'] = top['prizeLabel']
        redemption = re.search(r'Last Day To Redeem: (\d+/\d+/\d+)', plain(header))
        if redemption:
            game['lastDayToRedeem'] = datetime.strptime(redemption[1], '%m/%d/%y').date().isoformat()
        game['inventoryNote'] = f'Prize inventory as of {date}; store availability unverified.'
        if redemption:
            game['inventoryNote'] += f" Redeem by {game['lastDayToRedeem']}."
        games.append(game)
    if not games or len({g['id'] for g in games}) != len(games):
        raise ValueError('Missing or duplicate games')
    return printed, date, games

def build_catalog(pages):
    if set(pages) != set(PRICES):
        raise ValueError('Missing price categories')
    parsed = [parse_page(pages[p], p) for p in PRICES]
    if len({p[0] for p in parsed}) != 1:
        raise ValueError('Mixed source timestamps; retry after source update completes')
    games = sorted([g for p in parsed for g in p[2]], key=lambda g: g['id'])
    if len({g['id'] for g in games}) != len(games):
        raise ValueError('Duplicate game across price categories')
    return dict(state='Washington', source=SOURCE, sourceDate=parsed[0][1],
                sourceTimestampAsPrinted=parsed[0][0], sourceTimezone='Not stated on report',
                coverage='All seven published price categories, including closing games. Cumulative prize inventories, not dated winning-ticket counts or retailer availability.',
                updateCadence='Checked every six hours; source publication SLA and correction cadence unconfirmed.',
                games=games)

def fetch(url):
    for attempt in range(4):
        try:
            with urlopen(Request(url, headers={'User-Agent': 'LotteryAtlasOfficialDataBot/1.0'}), timeout=30) as response:
                return response.read()
        except HTTPError as error:
            if error.code not in (408, 429, 500, 502, 503, 504) or attempt == 3:
                raise
        except (URLError, TimeoutError):
            if attempt == 3:
                raise
        time.sleep(attempt + 1)

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    index = html.fromstring(fetch(SOURCE))
    links = index.xpath('//nav[contains(@class,"nav-views")]//li/a/@href')
    expected = {f'?price=${p}' for p in PRICES}
    if len(links) != len(expected) or set(links) != expected:
        raise ValueError('Published price categories changed')
    catalog = build_catalog({p: fetch(urljoin(SOURCE, f'?price=${p}')) for p in PRICES})
    result = dict(source="Washington's Lottery published Scratch prize inventories", updatedAt=datetime.now(timezone.utc).isoformat(), catalogs=[catalog])
    if args.output.exists():
        previous = json.loads(args.output.read_text())
        if previous.get('catalogs') == result['catalogs']:
            result['updatedAt'] = previous['updatedAt']
    # Validate the complete replacement before touching the last good output.
    temporary = args.output.with_suffix('.tmp')
    temporary.write_text(json.dumps(result, indent=2) + '\n')
    temporary.replace(args.output)
    print(f"Validated {len(catalog['games'])} Washington games, source date {catalog['sourceDate']}")

if __name__ == '__main__':
    main()
