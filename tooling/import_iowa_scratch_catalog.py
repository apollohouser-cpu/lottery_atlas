"""Import Iowa's dated $50-plus Scratch prize inventory, not winner activity."""
import argparse
from concurrent.futures import ThreadPoolExecutor
from datetime import datetime
import json
from pathlib import Path
import re
import subprocess
from zoneinfo import ZoneInfo
from lxml import html

SOURCE = 'https://ialottery.com/Pages/Games/RemainingPrizes.aspx'
DETAIL = 'https://www.ialottery.com/Pages/Games-Scratch/ScratchGamesDetail.aspx?g='
DATE_FIELDS = {'Game Start:': 'startDate', 'End Distribution:': 'endDistributionDate',
               'Official Game End:': 'gameEndDate', 'Last Day To Redeem Prizes:': 'lastDayToRedeem'}

def plain(node):
    return ' '.join(' '.join(node.itertext()).split())

def count(value):
    if not re.fullmatch(r'0|[1-9]\d*', value):
        raise ValueError('Invalid nonnegative integer count')
    return int(value)

def parse_report(raw):
    tree = html.fromstring(raw)
    dates = tree.xpath('//*[@id="ContentPlaceHolder1_DataAsOf"]/text()')
    if len(dates) != 1:
        raise ValueError('Missing source date')
    source_date = datetime.strptime(dates[0].strip(), '%m/%d/%Y').date().isoformat()
    tables = tree.xpath('//*[@id="RemainPrizes_JS_DATATABLE"]')
    if len(tables) != 1:
        raise ValueError('Missing prize report')
    columns = [plain(c) for c in tables[0].xpath('./thead/tr/th')]
    if columns != ['Game Name (Game Number)', 'Game Type', 'Cost', 'Prize', 'Claimed', 'Unclaimed']:
        raise ValueError('Unexpected prize report columns')
    rows = tables[0].xpath('./tbody/tr')
    if not rows:
        raise ValueError('Empty prize report')
    games = {}
    for row in rows:
        cells = [plain(c) for c in row.xpath('./td')]
        if len(cells) != 6:
            raise ValueError('Incomplete prize row')
        name, kind, price, prize, claimed, unclaimed = cells
        if kind not in ('Scratch', 'PullTab', 'InstaPlay'):
            raise ValueError('Unknown game type')
        if kind != 'Scratch':
            continue
        match = re.fullmatch(r'(.+?)\s+\((\d+)\)', name)
        if not match or not re.fullmatch(r'\$\d+', prize):
            raise ValueError('Invalid game identity or prize')
        cost, amount = count(price), count(prize[1:])
        if cost <= 0 or amount < 50:
            raise ValueError('Invalid price or changed report threshold')
        game = games.setdefault(match[2], dict(stateName='Iowa', id=match[2], name=match[1], cost=cost, prizeTiers=[]))
        if (game['name'], game['cost']) != (match[1], cost):
            raise ValueError('Conflicting game identity')
        if any(t['prizeAmount'] == amount for t in game['prizeTiers']):
            raise ValueError('Duplicate prize tier')
        game['prizeTiers'].append(dict(prizeAmount=amount, claimed=count(claimed), unclaimed=count(unclaimed)))
    if not games:
        raise ValueError('No Scratch games in report')
    for game in games.values():
        top = max(game['prizeTiers'], key=lambda t: t['prizeAmount'])
        game.update(topPrize=top['prizeAmount'], topPrizesRemaining=top['unclaimed'])
    return source_date, list(games.values())

def verify_detail(raw, game, source_date):
    tree = html.fromstring(raw)
    fields = {}
    for row in tree.xpath('//table[@id="Dates"]/tr'):
        cells = [plain(c) for c in row.xpath('./td')]
        if cells and cells[0] in DATE_FIELDS:
            key = DATE_FIELDS[cells[0]]
            if key in fields or len(cells) < 2:
                raise ValueError('Invalid game date fields')
            fields[key] = datetime.strptime(cells[1], '%m/%d/%Y').date().isoformat() if cells[1] else None
    if set(fields) != set(DATE_FIELDS.values()) or not fields['startDate']:
        raise ValueError('Missing game dates')
    if any(value and value < fields['startDate'] for key, value in fields.items() if key != 'startDate'):
        raise ValueError('Game end date precedes start')
    labels = tree.xpath('//*[@id="ContentPlaceHolder1_gameDetail_Title"]')
    label = plain(labels[0]) if len(labels) == 1 else ''
    match = re.fullmatch(r'(?:Win Up To|Load With) \$([\d,]+)(?: Top Prizes)?!?', label, re.I)
    if not match or int(match[1].replace(',', '')) != game['topPrize']:
        raise ValueError('Advertised top prize disagrees with report')
    note = f'Inventory through {source_date}; published tiers $50 or more only. Cumulative counts, not 2026 winning tickets. Store availability unverified.'
    for key, prefix in [('endDistributionDate', 'Distribution ended'), ('gameEndDate', 'Game ends'), ('lastDayToRedeem', 'Redeem by')]:
        if fields[key]:
            note += f' {prefix} {fields[key]}.'
    return {**game, **{k: v for k, v in fields.items() if v}, 'sourceUrl': DETAIL + game['id'], 'inventoryNote': note}

def fetch(url):
    # curl is also used in source audits; no cookies or authenticated session.
    return subprocess.run(['curl', '-fsSL', '--max-time', '30', '--retry', '3', '--retry-delay', '2', url], capture_output=True, check=True).stdout

def build_catalog(fetcher):
    source_date, games = parse_report(fetcher(SOURCE))
    with ThreadPoolExecutor(max_workers=2) as pool:
        verified = list(pool.map(lambda g: verify_detail(fetcher(DETAIL + g['id']), g, source_date), games))
    return dict(state='Iowa', source=SOURCE, sourceDate=source_date,
                coverage='Scratch games in the dated $50-plus remaining-prizes report. Cumulative claimed/unclaimed inventory only; excludes lower tiers, other game types, retailer locations and dated winning-ticket totals.',
                updateCadence='Checked every six hours; source publication cadence unconfirmed.',
                games=sorted(verified, key=lambda g: int(g['id'])))

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    catalog = build_catalog(fetch)
    today = datetime.now(ZoneInfo('America/Chicago'))
    if catalog['sourceDate'] > today.date().isoformat() or len(catalog['games']) < 30:
        raise ValueError('Future source date or unexpectedly small Iowa catalog')
    result = dict(source='Iowa Lottery dated Scratch prize inventory', updatedAt=today.isoformat(), catalogs=[catalog])
    if args.output.exists():
        previous = json.loads(args.output.read_text())
        if previous.get('catalogs') == result['catalogs']:
            result['updatedAt'] = previous['updatedAt']
    temporary = args.output.with_suffix('.tmp')
    temporary.write_text(json.dumps(result, indent=2) + '\n')
    temporary.replace(args.output)
    print(f"Validated {len(catalog['games'])} Iowa Scratch games, source date {catalog['sourceDate']}")

if __name__ == '__main__':
    main()
