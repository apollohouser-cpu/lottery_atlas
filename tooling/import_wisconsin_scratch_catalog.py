"""Refresh the Wisconsin Scratch catalog without inventing missing prize counts."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import date, datetime, timedelta, timezone
import json
from pathlib import Path
import re
import time
from urllib.error import HTTPError, URLError
from urllib.parse import parse_qs, urljoin, urlparse
from urllib.request import Request, urlopen
from zoneinfo import ZoneInfo
from lxml import html

SOURCE = 'https://www.wilottery.com/games/instant-games/scratch-games'

def plain(node):
    return ' '.join(' '.join(node.itertext()).split())

def count(value):
    if not re.fullmatch(r'(?:0|[1-9]\d*|[1-9]\d{0,2}(?:,\d{3})+)', value):
        raise ValueError(f'Invalid count: {value}')
    return int(value.replace(',', ''))

def parse_listing(raw):
    tree = html.fromstring(raw)
    cards = tree.xpath('//div[contains(concat(" ",normalize-space(@class)," ")," instant-listing-item ")]')
    if not cards:
        raise ValueError('Missing listing cards')
    games = []
    for card in cards:
        if card.get('data-type') not in ('scratch', 'pulltab', 'pulltab-vc'):
            raise ValueError('Unknown game type')
        if card.get('data-type') != 'scratch':
            continue
        links = card.xpath('./a/@href')
        if not links or not links[0].startswith('/games/instant-games/'):
            raise ValueError('Missing official game URL')
        start, end = card.get('data-startd'), card.get('data-endd')
        if start:
            date.fromisoformat(start)
        if end:
            date.fromisoformat(end)
        price = card.get('data-price', '')
        if not re.fullmatch(r'[1-9]\d*\.00', price):
            raise ValueError('Invalid Scratch price')
        names = card.xpath('.//h3')
        if len(names) > 1:
            raise ValueError('Ambiguous game name')
        if names and not plain(names[0]):
            names = names[0].xpath('following-sibling::*[1][self::p]')
        labels = card.xpath('.//*[contains(@class,"top-prize-amount")]')
        games.append(dict(url=urljoin(SOURCE, links[0]), name=plain(names[0]) if names else '',
                          start=start or None, end=end or None, cost=int(price[:-3]),
                          prizeLabel=plain(labels[0]) if len(labels) == 1 else None))
    pages = set()
    for link in tree.xpath('//nav[contains(@class,"pager")]//a/@href'):
        target = urlparse(urljoin(SOURCE, link))
        if target.netloc != urlparse(SOURCE).netloc or target.path != urlparse(SOURCE).path:
            raise ValueError('Unexpected pagination URL')
        values = parse_qs(target.query).get('page', [])
        if len(values) != 1 or not values[0].isdigit() or int(values[0]) >= 100:
            raise ValueError('Invalid pagination')
        pages.add(int(values[0]))
    return games, pages

def parse_detail(raw, listing, today):
    tree = html.fromstring(raw)
    fields = {}
    for row in tree.xpath('//div[contains(concat(" ",normalize-space(@class)," ")," instant-row ")]'):
        cells = row.xpath('./div[contains(concat(" ",normalize-space(@class)," ")," cell ")]')
        if len(cells) != 2:
            raise ValueError('Malformed detail field')
        key, value = map(plain, cells)
        if key in fields:
            raise ValueError('Duplicate detail field')
        fields[key] = value
    game_id = fields.get('Game Number', '')
    if not game_id.isdigit() or not listing['url'].endswith('-' + game_id):
        raise ValueError('Detail game identity does not match URL')
    if fields.get('Price') != f"${listing['cost']}.00":
        raise ValueError('Detail price does not match listing')
    started = datetime.strptime(fields['Start Date'], '%m/%d/%Y').date()
    if listing['start'] and started.isoformat() != listing['start']:
        raise ValueError('Start dates disagree')
    redeem = datetime.strptime(fields['Redeem By'], '%m/%d/%Y').date() if fields.get('Redeem By') else None
    # A blank listing end date must never resurrect a historically expired game.
    if (redeem and redeem < today) or started > today:
        return None
    headings = tree.xpath('//h1')
    if len(headings) == 1 and not plain(headings[0]):
        headings = headings[0].xpath('following-sibling::*[1][self::p]')
    name = plain(headings[0]) if len(headings) == 1 else listing['name']
    if not name:
        raise ValueError('Missing current game name')
    match = re.fullmatch(r'Top (Instant )?Prize \$?([\d,]+)!?', listing['prizeLabel'] or '')
    if not match:
        raise ValueError('Missing or unrecognized advertised top prize')
    if 'Top prize counts verified weekly' not in plain(tree):
        raise ValueError('Missing source cadence notice')
    game = dict(stateName='Wisconsin', id=game_id, name=name, cost=listing['cost'],
                topPrize=count(match[2]), sourceUrl=listing['url'], startDate=started.isoformat())
    if match[1]:
        game['topPrizeLabel'] = f"${match[2]} instant prize"
    total, remaining = fields.get('Total Top Prizes'), fields.get('Remaining Top Prizes')
    if (total is None) != (remaining is None):
        raise ValueError('Incomplete top-prize counts')
    if total is not None:
        total_count, remaining_count = count(total), count(remaining)
        if remaining_count > total_count:
            raise ValueError('Remaining prizes exceed total')
        game.update(totalTopPrizes=total_count, topPrizesRemaining=remaining_count)
    note = f'Retrieved {today.isoformat()}; top-prize counts verified weekly, verification date unpublished. Store availability unverified.'
    if remaining is None:
        note += ' Remaining count unavailable.'
    if redeem:
        game['lastDayToRedeem'] = redeem.isoformat()
        note += f' Redeem by {redeem.isoformat()}.'
    game['inventoryNote'] = note
    return game

def build_catalog(fetch, today):
    pending, seen, listings = {0}, set(), {}
    while pending:
        page = min(pending)
        pending.remove(page)
        rows, links = parse_listing(fetch(SOURCE + f'?page={page}'))
        seen.add(page)
        pending.update(links - seen)
        for row in rows:
            old = listings.get(row['url'])
            if old is not None and old != row:
                raise ValueError('Conflicting duplicate listing')
            listings[row['url']] = row
    if seen != set(range(max(seen) + 1)):
        raise ValueError('Incomplete pagination')
    cutoff = (today - timedelta(days=180)).isoformat()
    candidates = [g for g in listings.values() if not g['end'] or g['end'] >= cutoff]
    with ThreadPoolExecutor(max_workers=2) as pool:
        results = list(pool.map(lambda g: parse_detail(fetch(g['url']), g, today), candidates))
    games = sorted([g for g in results if g is not None], key=lambda g: g['id'])
    if not games or len({g['id'] for g in games}) != len(games):
        raise ValueError('Missing or duplicate confirmed game IDs')
    return dict(state='Wisconsin', source=SOURCE, retrievedDate=today.isoformat(),
                sourceDate=None, updateCadence='Top-prize counts verified weekly by source; checked every six hours.',
                coverage='Published Scratch listing, including games in its 180-day closing window, excluding expired redemption deadlines. Top-prize inventory only; not dated claims, all-tier winning tickets or retailer stock. Missing counts remain unknown.',
                listingPageCount=len(seen), games=games)

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
    today = datetime.now(ZoneInfo('America/Chicago')).date()
    catalog = build_catalog(fetch, today)
    result = dict(source='Wisconsin Lottery published Scratch catalog', updatedAt=datetime.now(timezone.utc).isoformat(), catalogs=[catalog])
    if args.output.exists():
        previous = json.loads(args.output.read_text())
        if previous.get('catalogs') == result['catalogs']:
            result['updatedAt'] = previous['updatedAt']
    temporary = args.output.with_suffix('.tmp')
    temporary.write_text(json.dumps(result, indent=2) + '\n')
    temporary.replace(args.output)
    print(f"Validated {len(catalog['games'])} Wisconsin games across {catalog['listingPageCount']} pages")

if __name__ == '__main__':
    main()
