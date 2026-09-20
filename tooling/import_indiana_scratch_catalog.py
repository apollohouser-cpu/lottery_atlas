"""Import the official Hoosier Lottery top-prize inventory table."""
import argparse
import json
import re
import subprocess
from datetime import datetime
from pathlib import Path
from zoneinfo import ZoneInfo
from lxml import html

SOURCE = 'https://hoosierlottery.com/games/scratch-off/scratch-off-stats/'
FIELDS = ['Name', 'InstantGameId', 'TopPrize', 'Unclaimed', 'PrizeTotal', 'PricePoint', 'ConsumerSalesStartDate', 'Odds']

def integer(value):
    if not re.fullmatch(r'(?:\d+|\d{1,3}(?:,\d{3})+)', value):
        raise ValueError('Invalid integer')
    return int(value.replace(',', ''))

def cash(value):
    if not value.startswith('$'):
        raise ValueError('Missing cash denomination')
    result = integer(value[1:])
    if result <= 0:
        raise ValueError('Nonpositive cash amount')
    return result

def parse_catalog(raw, today):
    tree = html.fromstring(raw)
    tables = tree.xpath('//table[contains(concat(" ",normalize-space(@class)," ")," grid-table ")]')
    if len(tables) != 1:
        raise ValueError('Missing or ambiguous inventory table')
    if tree.xpath('//*[contains(@class,"grid-pager")]//a[@href]'):
        raise ValueError('Unexpected pagination; refusing partial import')
    games, seen = [], set()
    for row in tables[0].xpath('./tbody/tr'):
        cells = row.xpath('./td')
        if [c.get('data-name') for c in cells] != FIELDS:
            raise ValueError('Changed or incomplete inventory columns')
        name, game_id, prize, left, total, price, start, odds = [' '.join(c.text_content().split()) for c in cells]
        if not name or not re.fullmatch(r'\d+', game_id) or game_id in seen:
            raise ValueError('Invalid or duplicate game identity')
        seen.add(game_id)
        remaining, printed = integer(left), integer(total)
        if remaining > printed:
            raise ValueError('Remaining top prizes exceed original total')
        start_date = datetime.strptime(start, '%m/%d/%Y').date()
        if start_date > today:
            raise ValueError('Unexpected future on-sale date')
        if not re.fullmatch(r'1 in \d+(?:\.\d+)?', odds):
            raise ValueError('Invalid published odds')
        games.append(dict(stateName='Indiana', id=game_id, name=name, cost=cash(price), topPrize=cash(prize),
                          topPrizesRemaining=remaining, topPrizesTotal=printed, startDate=start_date.isoformat(),
                          estimatedOdds=odds, sourceUrl=SOURCE,
                          inventoryNote='Unclaimed top prizes only; source verification date unpublished. Not dated winning-ticket totals. Store availability unverified.'))
    if not games:
        raise ValueError('Empty inventory table')
    return dict(state='Indiana', source=SOURCE, sourceDate=None,
                coverage='Games listed in official Scratch-off Stats. Top-prize inventory only; no lower tiers, dated claims or retailer joins. Ending and redemption dates are not provided by this table.',
                updateCadence='Checked every six hours; source publication cadence unconfirmed.',
                games=sorted(games, key=lambda g: int(g['id'])))

def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('output', type=Path)
    args = parser.parse_args()
    raw = subprocess.run(['curl', '-fsSL', '--max-time', '30', '--retry', '3', '--retry-delay', '2', SOURCE], capture_output=True, check=True).stdout
    now = datetime.now(ZoneInfo('America/Indiana/Indianapolis'))
    catalog = parse_catalog(raw, now.date())
    if len(catalog['games']) < 30:
        raise ValueError('Unexpectedly small Indiana catalog')
    result = dict(source='Hoosier Lottery official top-prize inventory', updatedAt=now.isoformat(), catalogs=[catalog])
    if args.output.exists():
        previous = json.loads(args.output.read_text())
        if previous.get('catalogs') == result['catalogs']:
            result['updatedAt'] = previous['updatedAt']
    temporary = args.output.with_suffix('.tmp')
    temporary.write_text(json.dumps(result, indent=2) + '\n')
    temporary.replace(args.output)
    print(f"Validated {len(catalog['games'])} Indiana games")

if __name__ == '__main__':
    main()
