"""Import Maine's price-category catalog with independently joined dated top tiers."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
from decimal import Decimal
import json
from pathlib import Path
import re
import subprocess
from urllib.parse import urlparse, parse_qs
from zoneinfo import ZoneInfo
from lxml import html

ROOT = 'https://www.mainelottery.com'
SOURCE = ROOT + '/players_info/unclaimed_prizes.html'
PRICES = [1, 2, 3, 5, 10, 20, 25, 30]


def tree(raw):
    return html.fromstring(raw)


def text(node):
    return ' '.join(' '.join(node.itertext()).split())


def integer(value):
    if not re.fullmatch(r'(?:\d+|\d{1,3}(?:,\d{3})+)', value):
        raise ValueError('Invalid nonnegative integer')
    return int(value.replace(',', ''))


def money(value):
    if not re.fullmatch(r'\$\d[\d,]*(?:\.\d{2})?', value):
        raise ValueError('Invalid dollar amount')
    return Decimal(value[1:].replace(',', ''))


def single_table(raw, headers):
    root = tree(raw)
    tables = root.xpath('//table')
    if len(tables) != 1:
        raise ValueError('Missing or ambiguous table')
    rows = tables[0].xpath('.//tr')
    if not rows or [text(x) for x in rows[0].xpath('./th|./td')] != headers:
        raise ValueError('Changed table headers')
    return root, rows[1:]


def report(raw, today):
    root, rows = single_table(raw, ['Price Point', 'Game No.', 'Game Name', 'Percent Unsold', 'Total Unclaimed', 'Top Prize Level(s)', 'Top Prize(s) Unclaimed'])
    stamps = re.findall(r'as of ([A-Z][a-z]+ \d{1,2}, \d{4} \d{1,2}:\d{2} [AP]M)', text(root))
    if len(stamps) != 1:
        raise ValueError('Missing report timestamp')
    stamp = datetime.strptime(stamps[0], '%B %d, %Y %I:%M %p')
    if stamp.date() > today:
        raise ValueError('Future report date')
    games = {}
    current = None
    for row in rows:
        cells = [text(x) for x in row.xpath('./td')]
        if len(cells) != 7:
            raise ValueError('Incomplete report row')
        price, gid, name, unsold, dollars, prize, remaining = cells
        if gid:
            integer(gid)
            cost = money(price)
            if gid in games or not name or cost <= 0 or cost != int(cost) or not re.fullmatch(r'\d+(?:\.\d+)?', unsold) or not 0 <= Decimal(unsold) <= 100:
                raise ValueError('Invalid report identity, price or percentage')
            money(dollars)  # Dollar totals must never be used as ticket counts.
            current = dict(price=int(cost), tiers=[])
            games[gid] = current
        elif current is None or any(cells[:5]):
            raise ValueError('Orphan or malformed continuation row')
        amount = money(prize)
        count = integer(remaining)
        if amount <= 0 or amount != int(amount) or any(t['prizeAmount'] == int(amount) for t in current['tiers']):
            raise ValueError('Invalid or duplicate tier')
        current['tiers'].append(dict(prizeAmount=int(amount), remaining=count))
    if not games:
        raise ValueError('Empty report')
    return games, stamp


def end_dates(raw):
    _, rows = single_table(raw, ['Game Number', 'Game Name', 'Game End**', 'Last Cash Date'])
    result = {}
    for row in rows:
        cells = [text(x) for x in row.xpath('./td')]
        if not cells:
            continue
        if len(cells) != 4:
            raise ValueError('Incomplete deadline row')
        gid, _, end, claim = cells
        integer(gid)
        pair = tuple(datetime.strptime(x, '%B %d, %Y').date() for x in [end, claim])
        result.setdefault(gid, []).append(pair)
    return result


def listing(raw, price):
    root = tree(raw)
    links = {}
    for a in root.xpath('//a[@href]'):
        url = a.get('href')
        if 'topic=Lottery_Scratch' not in url:
            continue
        parsed = urlparse(url)
        query = parse_qs(parsed.query)
        if parsed.scheme != 'https' or parsed.netloc != 'www.maine.gov' or parsed.path != '/tools/whatsnew/index.php' or not re.fullmatch(r'\d+', query.get('id', [''])[0]):
            raise ValueError('Unexpected detail URL')
        links[url] = dict(url=url, price=price, name=text(a))
    return list(links.values())


def detail(raw, item, inventory, stamp, deadlines, today):
    root = tree(raw)
    for node in root.xpath('//script|//style'):
        node.drop_tree()
    content = text(root)
    ids = re.findall(r'Game #\s*(\d+)', content)
    awards = re.findall(r'Maximum Award:\s*\$([\d,]+)', content)
    if len(ids) != 1:
        raise ValueError('Missing printed identity')
    gid = ids[0]
    if gid == '725':
        return None  # Audited blank maximum; never infer it from remaining tiers.
    if len(awards) != 1 or integer(awards[0]) <= 0 or not item['name']:
        raise ValueError('Missing maximum award or game name')
    top = integer(awards[0])
    launches = re.findall(r'On Sale\s*[-:]\s*([A-Z][a-z]+ \d{1,2}, \d{4})', content)
    if len(launches) != 1:
        raise ValueError('Missing launch date')
    launch = datetime.strptime(launches[0], '%B %d, %Y').date()
    if launch > today:
        return None
    dates = set(deadlines.get(gid, []))
    if len(dates) > 1 or any(end > claim for end, claim in dates):
        raise ValueError('Conflicting relevant claim dates')
    end, claim = next(iter(dates)) if dates else (None, None)
    if claim and claim < today:
        return None
    entry = inventory.get(gid)
    if entry and entry['price'] != item['price']:
        raise ValueError('Report/category price mismatch')
    tiers = entry['tiers'] if entry else []
    if any(t['prizeAmount'] > top for t in tiers):
        raise ValueError('Remaining tier exceeds verified maximum')
    matched = [t for t in tiers if t['prizeAmount'] == top]
    count = matched[0]['remaining'] if matched else None
    note = f'Published current price-category subset; game 725 excluded because its maximum award is unverified. Top-tier report as of {stamp.strftime("%Y-%m-%d %H:%M")}, timezone not stated; updated daily. Remaining prizes are not dated winning-ticket counts or store stock.'
    if count is None:
        note += ' Maximum-prize remaining count is not published in this report; unknown, not zero.'
    if end:
        note += f' Warehouse shipments end {end.isoformat()}; retailer sales may continue. Last cash date: {claim.isoformat()}.'
    result = dict(stateName='Maine', id=gid, name=item['name'], cost=item['price'], topPrize=top,
                  topPrizesRemaining=count, sourceUrl=item['url'], sourceDate=stamp.date().isoformat(),
                  startDate=launch.isoformat(), prizeTiers=tiers, inventoryNote=note)
    if claim:
        result['lastDayToRedeem'] = claim.isoformat()
        result['shipmentEndDate'] = end.isoformat()
    return result


def fetch(url):
    return subprocess.run(['curl', '-fsSL', '--max-time', '30', '--retry', '3', url], capture_output=True, check=True).stdout


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    now = datetime.now(ZoneInfo('America/New_York'))
    inventory, stamp = report(fetch(SOURCE), now.date())
    deadlines = end_dates(fetch(ROOT + '/instant/scratchdates.html'))
    with ThreadPoolExecutor(max_workers=2) as pool:
        groups = list(pool.map(lambda p: listing(fetch(f'{ROOT}/instant/scratch{p}dollar.html'), p), PRICES))
        items = [g for group in groups for g in group]
        if len({g['url'] for g in items}) != len(items):
            raise ValueError('Duplicate catalog identity')
        parsed = list(pool.map(lambda g: detail(fetch(g['url']), g, inventory, stamp, deadlines, now.date()), items))
    games = sorted([g for g in parsed if g], key=lambda g: int(g['id']))
    if len(games) < 15 or len({g['id'] for g in games}) != len(games):
        raise ValueError('Incomplete or duplicate catalog')
    catalog = dict(state='Maine', source=SOURCE, sourceDate=stamp.date().isoformat(), sourceTimestamp=stamp.isoformat(), sourceTimezone=None,
                   coverage='Current price-category catalog only. Game 725 excluded due to unverified maximum prize. Two sources joined by printed game number; report-only games excluded. Missing top-tier counts remain unknown.',
                   updateCadence='Lottery reports daily updates; checked every six hours.', games=games)
    result = dict(source='Maine official catalog and dated top-tier report', updatedAt=now.isoformat(), catalogs=[catalog])
    if args.output.exists():
        old = json.loads(args.output.read_text())
        if old.get('catalogs') == result['catalogs']:
            result['updatedAt'] = old['updatedAt']
    temp = args.output.with_suffix('.tmp')
    temp.write_text(json.dumps(result, indent=2) + '\n')
    temp.replace(args.output)
    print(f'Validated {len(games)} eligible Maine games')


if __name__ == '__main__':
    main()
